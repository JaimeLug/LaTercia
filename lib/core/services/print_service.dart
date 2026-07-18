import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:win32/win32.dart';

import '../database/database.dart';
import '../utils/app_logger.dart';
import '../utils/formatters.dart';
import '../utils/pricing.dart';

/// FASE 3.1/3.2 — Servicio de impresión térmica ESC/POS + gaveta de dinero.
///
/// Todo el hardware vive detrás de flags (`impresion_activa`, `gaveta_activa`)
/// y es genérico/multimarca (ESC/POS estándar, sin nada atado a un modelo).
/// La generación de documentos se prueba a nivel de bytes; el envío real por
/// socket (red) o spooler (USB) no se puede verificar sin hardware.

// ─── El pulso estándar de apertura de gaveta ────────────────────────────────

/// Pulso ESC/POS estándar `ESC p 0 25 250` → pin 0, on-time 25, off-time 250.
///
/// Estos son los bytes exactos que casi todas las gavetas conectadas a la
/// impresora esperan. NO usamos `Generator.drawer()` de esc_pos_utils_plus:
/// ese emite `ESC p '0' '3' '0'` (dígitos ASCII 0x30/0x33/0x30), que no es el
/// pulso canónico que pide el plan.
const List<int> kDrawerKickBytes = [0x1B, 0x70, 0x00, 0x19, 0xFA];

/// Comando alterno `DLE DC4 0 1 0` que algunas gavetas usan en su lugar.
const List<int> kDrawerKickAltBytes = [0x10, 0x14, 0x00, 0x01, 0x00];

// ─── Abstracción de transporte ───────────────────────────────────────────────

/// Un canal por el que se envían bytes crudos ESC/POS a la impresora.
///
/// Lanza si el envío falla; la [PrintQueue] captura la excepción, reintenta y,
/// tras agotar los reintentos, la reporta sin romper la venta.
abstract class PrinterTransport {
  Future<void> send(List<int> bytes);
}

/// Impresora de red (Ethernet/WiFi) escuchando en el puerto RAW 9100.
///
/// Abre el socket, escribe los bytes, hace flush y cierra. Un [timeout]
/// razonable evita colgar la cola si la impresora está apagada o inalcanzable.
class NetworkPrinterTransport implements PrinterTransport {
  NetworkPrinterTransport(
    this.host, {
    this.port = 9100,
    this.timeout = const Duration(seconds: 5),
  });

  final String host;
  final int port;
  final Duration timeout;

  @override
  Future<void> send(List<int> bytes) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    try {
      socket.add(bytes);
      await socket.flush();
    } finally {
      socket.destroy();
    }
  }
}

/// Impresora del sistema Windows (típicamente USB) vía el spooler.
///
/// Envía bytes RAW con la secuencia estándar del API de impresión de Windows:
/// `OpenPrinter` → `StartDocPrinter` (DOC_INFO_1 con `pDatatype = 'RAW'`, que
/// hace que el spooler entregue los bytes sin procesarlos) → `StartPagePrinter`
/// → `WritePrinter` → `EndPagePrinter` → `EndDocPrinter` → `ClosePrinter`.
///
/// Es la forma genérica de hablar con cualquier impresora instalada en Windows.
/// No se puede probar sin una impresora real instalada; todos los handles y la
/// memoria nativa se liberan en `finally`.
class WindowsRawPrinterTransport implements PrinterTransport {
  WindowsRawPrinterTransport(this.printerName);

  final String printerName;

  @override
  Future<void> send(List<int> bytes) async {
    if (!Platform.isWindows) {
      throw UnsupportedError(
          'La impresión RAW por spooler solo está disponible en Windows.');
    }

    final printerNamePtr = printerName.toNativeUtf16();
    final hPrinterPtr = calloc<IntPtr>();
    final docNamePtr = 'La Tercia POS'.toNativeUtf16();
    final dataTypePtr = 'RAW'.toNativeUtf16();
    final docInfo = calloc<DOC_INFO_1>();
    final dataPtr = calloc<Uint8>(bytes.length);
    final bytesWritten = calloc<Uint32>();

    try {
      // Abrir la impresora por nombre.
      if (OpenPrinter(printerNamePtr, hPrinterPtr, nullptr) == 0) {
        throw OSError(
            'OpenPrinter falló para "$printerName"', GetLastError());
      }
      final hPrinter = hPrinterPtr.value;

      try {
        // Documento RAW: el spooler entrega los bytes tal cual a la impresora.
        docInfo.ref
          ..pDocName = docNamePtr
          ..pOutputFile = nullptr
          ..pDatatype = dataTypePtr;

        if (StartDocPrinter(hPrinter, 1, docInfo) == 0) {
          throw OSError('StartDocPrinter falló', GetLastError());
        }
        try {
          if (StartPagePrinter(hPrinter) == 0) {
            throw OSError('StartPagePrinter falló', GetLastError());
          }
          try {
            // Copiar los bytes al buffer nativo.
            final buffer = dataPtr.asTypedList(bytes.length);
            buffer.setAll(0, bytes);

            if (WritePrinter(
                    hPrinter, dataPtr, bytes.length, bytesWritten) ==
                0) {
              throw OSError('WritePrinter falló', GetLastError());
            }
          } finally {
            EndPagePrinter(hPrinter);
          }
        } finally {
          EndDocPrinter(hPrinter);
        }
      } finally {
        ClosePrinter(hPrinter);
      }
    } finally {
      calloc.free(printerNamePtr);
      calloc.free(hPrinterPtr);
      calloc.free(docNamePtr);
      calloc.free(dataTypePtr);
      calloc.free(docInfo);
      calloc.free(dataPtr);
      calloc.free(bytesWritten);
    }
  }
}

/// FASE 6.1 — Impresora USB/local en Linux. Dos modos según [target]:
/// - Empieza con `/dev/` (p.ej. `/dev/usb/lp0`): escribe los bytes RAW directo
///   al archivo de dispositivo (requiere permisos, típicamente el grupo `lp`).
/// - Cualquier otra cosa: se trata como una cola de CUPS y se manda con
///   `lp -d <cola> -o raw` por stdin (la forma estándar y portable en Linux).
///
/// No verificable sin una impresora/Linux reales; se prueba a nivel de bytes en
/// los builders. La impresora de RED (socket 9100) ya es cross-platform y no
/// necesita esto.
class LinuxPrinterTransport implements PrinterTransport {
  LinuxPrinterTransport(this.target);

  final String target;

  @override
  Future<void> send(List<int> bytes) async {
    if (!Platform.isLinux) {
      throw UnsupportedError(
          'La impresión USB/local por CUPS solo está disponible en Linux.');
    }

    if (target.startsWith('/dev/')) {
      // Escritura RAW directa al dispositivo.
      final raf = await File(target).open(mode: FileMode.writeOnlyAppend);
      try {
        await raf.writeFrom(bytes);
        await raf.flush();
      } finally {
        await raf.close();
      }
      return;
    }

    // Cola CUPS vía `lp -o raw`, alimentando los bytes por stdin.
    final process = await Process.start('lp', ['-d', target, '-o', 'raw']);
    process.stdin.add(bytes);
    await process.stdin.flush();
    await process.stdin.close();
    final code = await process.exitCode;
    if (code != 0) {
      final err =
          await process.stderr.transform(systemEncoding.decoder).join();
      throw Exception('lp devolvió $code: $err');
    }
  }
}

/// Enumera las impresoras instaladas en Windows (locales + conexiones de red
/// del sistema) para poblar el desplegable de Configuración, en vez de que el
/// usuario teclee el nombre exacto a mano.
///
/// Usa `EnumPrinters` (nivel 4, que solo trae nombres y es rápido) con el
/// patrón estándar de dos llamadas: la primera pide el tamaño de buffer, la
/// segunda lo llena. Devuelve lista vacía fuera de Windows o si algo falla.
List<String> listWindowsPrinters() {
  if (!Platform.isWindows) return const [];

  // PRINTER_ENUM_LOCAL (0x2) | PRINTER_ENUM_CONNECTIONS (0x4).
  const flags = 0x00000002 | 0x00000004;
  final pcbNeeded = calloc<Uint32>();
  final pcReturned = calloc<Uint32>();

  try {
    // 1ª llamada: averiguar cuántos bytes hacen falta.
    EnumPrinters(flags, nullptr, 4, nullptr, 0, pcbNeeded, pcReturned);
    final cb = pcbNeeded.value;
    if (cb == 0) return const [];

    final buffer = calloc<Uint8>(cb);
    try {
      // 2ª llamada: llenar el buffer con los PRINTER_INFO_4.
      if (EnumPrinters(flags, nullptr, 4, buffer, cb, pcbNeeded, pcReturned) ==
          0) {
        return const [];
      }
      final count = pcReturned.value;
      final info = buffer.cast<PRINTER_INFO_4>();
      final names = <String>[];
      for (var i = 0; i < count; i++) {
        final namePtr = (info + i).ref.pPrinterName;
        if (namePtr != nullptr) {
          final name = namePtr.toDartString();
          if (name.isNotEmpty) names.add(name);
        }
      }
      return names;
    } finally {
      calloc.free(buffer);
    }
  } catch (_) {
    return const [];
  } finally {
    calloc.free(pcbNeeded);
    calloc.free(pcReturned);
  }
}

/// Nombres de impresoras virtuales de Windows que NO son térmicas: no
/// entienden bytes ESC/POS crudos (esperan gráficos GDI), así que enviarles un
/// ticket produce basura o un archivo inválido. Se usa para avisar en la UI.
bool isVirtualPrinter(String name) {
  final n = name.toLowerCase();
  return n.contains('pdf') ||
      n.contains('xps') ||
      n.contains('onenote') ||
      n.contains('fax') ||
      n.contains('microsoft print to');
}

/// Número de columnas de caracteres del papel: 32 para 58 mm, 48 para 80 mm.
/// Es el ancho real de una línea en la impresora térmica.
int paperColumns(Map<String, String> settings) =>
    settings['printer_width'] == '58' ? 32 : 48;

/// Sanea texto para impresión: las fuentes estándar (latin1 en ESC/POS,
/// Helvetica en el PDF) no soportan toda la puntuación Unicode (la raya larga
/// "—", comillas tipográficas, etc.). Sustituye esos glyphs por equivalentes
/// ASCII y descarta cualquier code unit fuera de 0..255 para no romper nunca la
/// generación de bytes ni el layout del PDF.
String sanitizeTicketText(String s) {
  final replaced = s
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('‘', "'")
      .replaceAll('’', "'")
      .replaceAll('…', '...');
  final buffer = StringBuffer();
  for (final unit in replaced.codeUnits) {
    buffer.writeCharCode(unit <= 0xFF ? unit : 0x3F /* '?' */);
  }
  return buffer.toString();
}

String _centerLine(String s, int width) {
  if (s.length >= width) return s;
  final pad = (width - s.length) ~/ 2;
  return '${' ' * pad}$s';
}

/// Líneas de texto plano del ticket de prueba, formateadas al ancho real del
/// papel (32/48 columnas). Sirven para una **vista previa en pantalla** — que
/// el usuario valide tamaño y contenido sin necesidad de una impresora física
/// (y sin caer en la trampa de "imprimir" a un PDF, que no entiende ESC/POS).
List<String> testTicketPreviewLines(Map<String, String> settings) {
  final w = paperColumns(settings);
  final businessName = settings['business_name'] ?? 'La Tercia';
  final width = settings['printer_width'] ?? '80';
  final transport =
      (settings['printer_transport'] ?? 'red') == 'usb' ? 'USB' : 'Red';

  return [
    _centerLine(businessName, w),
    _centerLine('TICKET DE PRUEBA', w),
    '-' * w,
    'Ancho de papel: $width mm',
    'Conexion: $transport',
    formatDateTime(DateTime.now()),
    '-' * w,
    _centerLine('Si lees esto,', w),
    _centerLine('la impresora funciona.', w),
  ];
}

/// Elige el transporte a partir de los settings de configuración.
///
/// `printer_transport` = 'red' → [NetworkPrinterTransport] (host, o `host:puerto`).
/// `printer_transport` = 'usb' → impresora local: en Windows el spooler
/// ([WindowsRawPrinterTransport], nombre de impresora); en Linux CUPS o
/// `/dev/usb/lp0` ([LinuxPrinterTransport]). Devuelve `null` si no hay dirección
/// configurada, para que la cola avise "impresora no configurada" sin fallar.
PrinterTransport? printerTransportFromSettings(Map<String, String> settings) {
  final transport = settings['printer_transport'] ?? 'red';
  final address = (settings['printer_address'] ?? '').trim();
  if (address.isEmpty) return null;

  if (transport == 'usb') {
    if (Platform.isLinux) return LinuxPrinterTransport(address);
    return WindowsRawPrinterTransport(address);
  }

  // Red: acepta "192.168.1.50" o "192.168.1.50:9100".
  final parts = address.split(':');
  final host = parts.first.trim();
  final port = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 9100 : 9100;
  return NetworkPrinterTransport(host, port: port);
}

// ─── Modelo de modificador para la comanda ───────────────────────────────────

class _ParsedModifier {
  const _ParsedModifier(this.name, this.priceDelta, {this.included = false});
  final String name;
  final double priceDelta;
  final bool included;
}

List<_ParsedModifier> _parseModifiers(String? modifiersJson) {
  if (modifiersJson == null || modifiersJson.isEmpty) return const [];
  try {
    final decoded = jsonDecode(modifiersJson);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((m) => _ParsedModifier(
              (m['name'] ?? '').toString(),
              (m['priceDelta'] is num)
                  ? (m['priceDelta'] as num).toDouble()
                  : 0.0,
              included: m['included'] == true,
            ))
        .toList();
  } catch (_) {
    // JSON corrupto no debe romper la impresión de la comanda.
    return const [];
  }
}

// ─── Función pura testeable: líneas de la comanda de cocina ──────────────────

const Map<String, String> _orderTypeLabels = {
  'mesa': 'MESA',
  'para_llevar': 'PARA LLEVAR',
  'delivery': 'DELIVERY',
};

/// Construye las líneas de texto de la comanda de cocina como una lista pura de
/// `String`, sin ESC/POS. Aislada del builder de bytes para poder verificar en
/// tests que aparecen nombres de producto y modificadores parseados sin tener
/// que rastrear dentro del documento binario.
///
/// Sin precios: la comanda es para cocina.
List<String> kitchenTicketLines(Order order, List<OrderItem> items) {
  final lines = <String>[];

  final typeLabel = _orderTypeLabels[order.type] ?? order.type.toUpperCase();
  lines.add(typeLabel);
  if (order.type == 'mesa' && order.tableId != null) {
    lines.add('Mesa: ${order.tableId}');
  }
  lines.add('Folio: ${order.orderNumber}');
  lines.add('Hora: ${formatTime(order.createdAt)}');

  for (final item in items) {
    lines.add('${item.quantity}x ${item.productName}');
    for (final mod in _parseModifiers(item.modifiersJson)) {
      lines.add(mod.included ? '  + ${mod.name} (incluido)' : '  + ${mod.name}');
    }
    if (item.itemNote != null && item.itemNote!.trim().isNotEmpty) {
      lines.add('  * ${item.itemNote!.trim()}');
    }
  }

  if (order.note != null && order.note!.trim().isNotEmpty) {
    lines.add('NOTA: ${order.note!.trim()}');
  }

  return lines;
}

// ─── Cola de impresión con reintento ─────────────────────────────────────────

/// Encola trabajos de impresión y los envía por el transporte con reintento y
/// backoff. Si tras los reintentos sigue fallando, registra un WARN y marca
/// [lastJobFailed] para que la UI pueda avisar ("la impresora no responde").
///
/// NUNCA lanza hacia el caller: la impresión es best-effort y jamás debe
/// romper ni bloquear la venta (se dispara después del commit de la BD).
class PrintQueue {
  PrintQueue({
    this.maxRetries = 3,
    this.baseBackoff = const Duration(milliseconds: 400),
  });

  final int maxRetries;
  final Duration baseBackoff;

  // Cadena de futures: serializa los trabajos para que salgan en orden y no se
  // pisen en el transporte.
  Future<void> _tail = Future.value();

  /// `true` si el último trabajo procesado falló tras agotar los reintentos.
  bool lastJobFailed = false;

  /// Descripción del último trabajo que falló, para el mensaje de la UI.
  String? lastError;

  /// Encola un trabajo. El future se completa con `true` si se imprimió,
  /// `false` si falló (nunca lanza).
  Future<bool> enqueue(
    PrinterTransport? transport,
    List<int> bytes,
    String description,
  ) {
    final completer = Completer<bool>();
    _tail = _tail.then((_) async {
      final ok = await _send(transport, bytes, description);
      completer.complete(ok);
    });
    return completer.future;
  }

  Future<bool> _send(
    PrinterTransport? transport,
    List<int> bytes,
    String description,
  ) async {
    if (transport == null) {
      appLogger.warn(
          'Impresión omitida ($description): impresora no configurada.');
      lastJobFailed = true;
      lastError = description;
      return false;
    }

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await transport.send(bytes);
        lastJobFailed = false;
        lastError = null;
        return true;
      } catch (e, st) {
        if (attempt >= maxRetries) {
          appLogger.warn(
            'La impresora no responde ($description) tras $maxRetries intentos.',
            e,
            st,
          );
          lastJobFailed = true;
          lastError = description;
          return false;
        }
        // Backoff exponencial: base, 2×base, 4×base, ...
        await Future<void>.delayed(baseBackoff * (1 << (attempt - 1)));
      }
    }
    return false;
  }
}

// ─── Servicio de alto nivel ──────────────────────────────────────────────────

class PrintService {
  PrintService();

  final PrintQueue queue = PrintQueue();

  // El perfil de capacidades ESC/POS se carga una sola vez y se cachea.
  Future<CapabilityProfile>? _profileFuture;
  Future<CapabilityProfile> _profile() =>
      _profileFuture ??= CapabilityProfile.load();

  bool printingEnabled(Map<String, String> settings) =>
      settings['impresion_activa'] == 'true';

  bool drawerEnabled(Map<String, String> settings) =>
      settings['gaveta_activa'] == 'true';

  PaperSize _paperSize(Map<String, String> settings) =>
      settings['printer_width'] == '58' ? PaperSize.mm58 : PaperSize.mm80;

  /// Modo de impresión: 'termica' (ESC/POS, default) o 'grafica' (PDF).
  String printerMode(Map<String, String> settings) =>
      settings['printer_mode'] == 'grafica' ? 'grafica' : 'termica';

  /// Formato de página del rollo del PDF según el ancho de papel:
  /// 58 mm → [PdfPageFormat.roll57], 80 mm → [PdfPageFormat.roll80].
  PdfPageFormat _rollFormat(Map<String, String> settings) =>
      settings['printer_width'] == '58'
          ? PdfPageFormat.roll57
          : PdfPageFormat.roll80;

  PrinterTransport? transportFor(Map<String, String> settings) =>
      printerTransportFromSettings(settings);

  /// latin1 (el codec por defecto del Generator) no puede codificar caracteres
  /// como la raya larga "—" (U+2014) y lanzaría. Sustituimos la puntuación
  /// unicode común por equivalentes latin1 y descartamos cualquier code unit
  /// fuera de 0..255 para no romper nunca la generación de bytes.
  static String _san(String s) => sanitizeTicketText(s);

  // ─── Pulso de gaveta ───────────────────────────────────────────────────────

  /// Los bytes exactos del pulso de apertura (ver [kDrawerKickBytes]).
  List<int> buildDrawerKick() => List<int>.from(kDrawerKickBytes);

  // ─── Ticket de venta ─────────────────────────────────────────────────────

  /// Documento ESC/POS del ticket de venta. Devuelve los bytes listos para el
  /// transporte. Si [reprint] es `true` imprime la marca "— REIMPRESIÓN —"
  /// cerca del encabezado.
  Future<List<int>> buildSalesTicket({
    required Order order,
    required List<OrderItem> items,
    required Payment payment,
    required Map<String, String> settings,
    required Employee employee,
    bool reprint = false,
  }) async {
    final profile = await _profile();
    final g = Generator(_paperSize(settings), profile);
    final symbol = settings['currency_symbol'] ?? r'$';
    final decimals = int.tryParse(settings['currency_decimals'] ?? '2') ?? 2;
    final businessName = settings['business_name'] ?? 'La Tercia';
    final slogan = settings['slogan'] ?? '';
    final footer = settings['receipt_footer'] ?? '';
    final showEmployee = settings['receipt_show_employee'] != 'false';
    final showDiscount = settings['receipt_show_discount'] != 'false';

    String money(double v) => formatCurrency(v, symbol, decimals: decimals);

    final bytes = <int>[];
    bytes.addAll(g.reset());

    // Encabezado.
    bytes.addAll(g.text(_san(businessName),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        )));
    if (slogan.isNotEmpty) {
      bytes.addAll(g.text(_san(slogan),
          styles: const PosStyles(align: PosAlign.center)));
    }

    if (reprint) {
      bytes.addAll(g.text(_san('— REIMPRESIÓN —'),
          styles: const PosStyles(align: PosAlign.center, bold: true)));
    }

    bytes.addAll(g.text(_san(formatDateTime(order.createdAt)),
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.text(_san('Folio: ${order.orderNumber}'),
        styles: const PosStyles(align: PosAlign.center)));
    if (showEmployee) {
      bytes.addAll(g.text(_san('Atendió: ${employee.name}'),
          styles: const PosStyles(align: PosAlign.center)));
    }

    bytes.addAll(g.hr());

    // Desglose de items: "cant× nombre ............ precio".
    for (final item in items) {
      bytes.addAll(g.row([
        PosColumn(
          text: _san('${item.quantity}x ${item.productName}'),
          width: 8,
        ),
        PosColumn(
          text: _san(money(item.unitPrice * item.quantity)),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(g.hr());

    // Subtotal / descuento / IVA.
    bytes.addAll(_kv(g, 'Subtotal', money(order.subtotal)));
    if (showDiscount && order.discountAmount > 0) {
      bytes.addAll(_kv(g, 'Descuento', '-${money(order.discountAmount)}'));
    }
    if (order.taxAmount > 0) {
      final ivaLabel = taxIsIncludedInTotal(
        subtotal: order.subtotal,
        discount: order.discountAmount,
        tax: order.taxAmount,
        total: order.total,
      )
          ? 'IVA incluido'
          : 'IVA';
      bytes.addAll(_kv(g, ivaLabel, money(order.taxAmount)));
    }
    if (order.deliveryFee > 0) {
      final label = order.deliveryZone != null
          ? 'Envío (${order.deliveryZone})'
          : 'Envío';
      bytes.addAll(_kv(g, label, money(order.deliveryFee)));
    }

    // TOTAL en negrita/grande.
    bytes.addAll(g.row([
      PosColumn(
        text: 'TOTAL',
        width: 6,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: _san(money(order.total)),
        width: 6,
        styles: const PosStyles(
          bold: true,
          align: PosAlign.right,
          height: PosTextSize.size2,
        ),
      ),
    ]));

    bytes.addAll(g.hr());

    // Método de pago y cambio (si efectivo).
    if (payment.method == 'efectivo') {
      bytes.addAll(_kv(g, 'Efectivo', money(payment.amountTendered)));
      if (payment.changeGiven > 0) {
        bytes.addAll(_kv(g, 'Cambio', money(payment.changeGiven)));
      }
    } else {
      bytes.addAll(_kv(g, 'Pago', _san(payment.method)));
    }

    // Pie.
    if (footer.isNotEmpty) {
      bytes.addAll(g.feed(1));
      bytes.addAll(g.text(_san(footer),
          styles: const PosStyles(align: PosAlign.center)));
    }

    bytes.addAll(g.cut());
    return bytes;
  }

  List<int> _kv(Generator g, String label, String value) {
    return g.row([
      PosColumn(text: _san(label), width: 6),
      PosColumn(
        text: value,
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
  }

  // ─── Comanda de cocina ───────────────────────────────────────────────────

  /// Documento ESC/POS de la comanda de cocina: grande y legible, con tipo de
  /// orden, folio, hora, items + modificadores + notas. Sin precios.
  Future<List<int>> buildKitchenTicket({
    required Order order,
    required List<OrderItem> items,
    required Map<String, String> settings,
  }) async {
    final profile = await _profile();
    final g = Generator(_paperSize(settings), profile);

    final typeLabel =
        _orderTypeLabels[order.type] ?? order.type.toUpperCase();

    final bytes = <int>[];
    bytes.addAll(g.reset());

    // Tipo de orden (grande) y mesa.
    bytes.addAll(g.text(_san(typeLabel),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        )));
    if (order.type == 'mesa' && order.tableId != null) {
      bytes.addAll(g.text(_san('Mesa: ${order.tableId}'),
          styles: const PosStyles(
              align: PosAlign.center, height: PosTextSize.size2)));
    }

    bytes.addAll(g.text(_san('Folio: ${order.orderNumber}'),
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.text(_san('Hora: ${formatTime(order.createdAt)}'),
        styles: const PosStyles(align: PosAlign.center)));

    bytes.addAll(g.hr());

    // Items grandes con modificadores y nota por item.
    for (final item in items) {
      bytes.addAll(g.text(_san('${item.quantity}x ${item.productName}'),
          styles: const PosStyles(
              bold: true, height: PosTextSize.size2, width: PosTextSize.size2)));
      for (final mod in _parseModifiers(item.modifiersJson)) {
        bytes.addAll(g.text(
            _san(mod.included ? '  + ${mod.name} (incluido)' : '  + ${mod.name}')));
      }
      if (item.itemNote != null && item.itemNote!.trim().isNotEmpty) {
        bytes.addAll(g.text(_san('  * ${item.itemNote!.trim()}'),
            styles: const PosStyles(bold: true)));
      }
    }

    // Nota de la orden.
    if (order.note != null && order.note!.trim().isNotEmpty) {
      bytes.addAll(g.hr());
      bytes.addAll(g.text(_san('NOTA: ${order.note!.trim()}'),
          styles: const PosStyles(bold: true)));
    }

    bytes.addAll(g.cut());
    return bytes;
  }

  // ─── Builders PDF (modo 'grafica') ───────────────────────────────────────
  //
  // Reflejan el MISMO contenido que sus equivalentes ESC/POS, pero renderizado
  // como documento gráfico para impresoras normales (inyección/láser). Se
  // prueban a nivel de bytes (empiezan con el header "%PDF"); el envío real a
  // la impresora (printPdfToWindows) no es testeable sin hardware.

  // Estilos monoespaciados reutilizables.
  pw.TextStyle get _mono => pw.TextStyle(font: pw.Font.courier(), fontSize: 8);
  pw.TextStyle get _monoBold =>
      pw.TextStyle(font: pw.Font.courierBold(), fontSize: 8);
  pw.TextStyle get _monoBig => pw.TextStyle(
      font: pw.Font.courierBold(), fontSize: 13, letterSpacing: 0.5);
  pw.TextStyle get _monoMed =>
      pw.TextStyle(font: pw.Font.courierBold(), fontSize: 10);

  pw.Widget _center(String text, pw.TextStyle style) => pw.Center(
        child: pw.Text(sanitizeTicketText(text),
            style: style, textAlign: pw.TextAlign.center),
      );

  pw.Widget _hrPdf() => pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Divider(height: 1, thickness: 0.5),
      );

  /// Fila "etiqueta …… valor" (valor alineado a la derecha).
  pw.Widget _kvPdf(String label, String value, {pw.TextStyle? style}) {
    final s = style ?? _mono;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: pw.Text(sanitizeTicketText(label), style: s)),
        pw.Text(sanitizeTicketText(value), style: s),
      ],
    );
  }

  /// Logo para el encabezado del ticket PDF: el personalizado si el negocio
  /// subió uno en Configuración → Negocio, o el de La Tercia por defecto
  /// (`assets/images/logo-color.png`) si no. Best-effort: si ninguno carga,
  /// el ticket sigue imprimiéndose sin logo (nunca rompe la venta).
  Future<pw.ImageProvider?> _resolveLogo(Map<String, String> settings) async {
    final path = (settings['logo_path'] ?? '').trim();
    if (path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) {
          return pw.MemoryImage(await file.readAsBytes());
        }
      } catch (e, st) {
        appLogger.warn(
            'No se pudo cargar el logo personalizado para el ticket.', e, st);
      }
    }
    try {
      return await imageFromAssetBundle('assets/images/logo-color.png');
    } catch (e, st) {
      appLogger.warn('No se pudo cargar el logo por defecto para el ticket.', e, st);
      return null;
    }
  }

  /// PDF del ticket de venta — mismo contenido que [buildSalesTicket].
  Future<Uint8List> buildSalesTicketPdf({
    required Order order,
    required List<OrderItem> items,
    required Payment payment,
    required Map<String, String> settings,
    required Employee employee,
    bool reprint = false,
  }) async {
    final symbol = settings['currency_symbol'] ?? r'$';
    final decimals = int.tryParse(settings['currency_decimals'] ?? '2') ?? 2;
    final businessName = settings['business_name'] ?? 'La Tercia';
    final slogan = settings['slogan'] ?? '';
    final footer = settings['receipt_footer'] ?? '';
    final showEmployee = settings['receipt_show_employee'] != 'false';
    final showDiscount = settings['receipt_show_discount'] != 'false';
    final logo = await _resolveLogo(settings);

    String money(double v) => formatCurrency(v, symbol, decimals: decimals);

    final children = <pw.Widget>[
      if (logo != null) ...[
        pw.Center(
          child: pw.SizedBox(
              height: 46, width: 46, child: pw.Image(logo)),
        ),
        pw.SizedBox(height: 4),
      ],
      _center(businessName, _monoBig),
      if (slogan.isNotEmpty) _center(slogan, _mono),
      if (reprint) _center('— REIMPRESIÓN —', _monoBold),
      _center(formatDateTime(order.createdAt), _mono),
      _center('Folio: ${order.orderNumber}', _mono),
      if (showEmployee) _center('Atendió: ${employee.name}', _mono),
      _hrPdf(),
      for (final item in items)
        _kvPdf('${item.quantity}x ${item.productName}',
            money(item.unitPrice * item.quantity)),
      _hrPdf(),
      _kvPdf('Subtotal', money(order.subtotal)),
      if (showDiscount && order.discountAmount > 0)
        _kvPdf('Descuento', '-${money(order.discountAmount)}'),
      if (order.taxAmount > 0)
        _kvPdf(
            taxIsIncludedInTotal(
              subtotal: order.subtotal,
              discount: order.discountAmount,
              tax: order.taxAmount,
              total: order.total,
            )
                ? 'IVA incluido'
                : 'IVA',
            money(order.taxAmount)),
      if (order.deliveryFee > 0)
        _kvPdf(
            order.deliveryZone != null
                ? 'Envío (${order.deliveryZone})'
                : 'Envío',
            money(order.deliveryFee)),
      _kvPdf('TOTAL', money(order.total), style: _monoMed),
      _hrPdf(),
      if (payment.method == 'efectivo') ...[
        _kvPdf('Efectivo', money(payment.amountTendered)),
        if (payment.changeGiven > 0)
          _kvPdf('Cambio', money(payment.changeGiven)),
      ] else
        _kvPdf('Pago', payment.method),
      if (footer.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        _center(footer, _mono),
      ],
    ];

    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: _rollMargins(settings),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: pw.MainAxisSize.min,
        children: children,
      ),
    ));
    return doc.save();
  }

  /// PDF de la comanda de cocina — mismo contenido que [buildKitchenTicket].
  Future<Uint8List> buildKitchenTicketPdf({
    required Order order,
    required List<OrderItem> items,
    required Map<String, String> settings,
  }) async {
    final typeLabel = _orderTypeLabels[order.type] ?? order.type.toUpperCase();

    final children = <pw.Widget>[
      _center(typeLabel, _monoBig),
      if (order.type == 'mesa' && order.tableId != null)
        _center('Mesa: ${order.tableId}', _monoMed),
      _center('Folio: ${order.orderNumber}', _mono),
      _center('Hora: ${formatTime(order.createdAt)}', _mono),
      _hrPdf(),
    ];

    for (final item in items) {
      children.add(pw.Text(
          sanitizeTicketText('${item.quantity}x ${item.productName}'),
          style: _monoMed));
      for (final mod in _parseModifiers(item.modifiersJson)) {
        children.add(pw.Text(
            sanitizeTicketText(
                mod.included ? '  + ${mod.name} (incluido)' : '  + ${mod.name}'),
            style: _mono));
      }
      if (item.itemNote != null && item.itemNote!.trim().isNotEmpty) {
        children.add(pw.Text(
            sanitizeTicketText('  * ${item.itemNote!.trim()}'),
            style: _monoBold));
      }
    }

    if (order.note != null && order.note!.trim().isNotEmpty) {
      children
        ..add(_hrPdf())
        ..add(pw.Text(sanitizeTicketText('NOTA: ${order.note!.trim()}'),
            style: _monoBold));
    }

    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: _rollMargins(settings),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: pw.MainAxisSize.min,
        children: children,
      ),
    ));
    return doc.save();
  }

  /// PDF del ticket de prueba — refleja [testTicketPreviewLines].
  Future<Uint8List> buildTestTicketPdf(Map<String, String> settings) async {
    final lines = testTicketPreviewLines(settings);
    final children = <pw.Widget>[];
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      // Las dos primeras líneas (negocio + "TICKET DE PRUEBA") van centradas
      // y en grande, igual que la vista previa/el ESC/POS.
      if (i == 0) {
        children.add(_center(raw, _monoBig));
      } else if (i == 1) {
        children.add(_center(raw, _monoBold));
      } else if (raw.replaceAll('-', '').isEmpty && raw.isNotEmpty) {
        children.add(_hrPdf());
      } else {
        children.add(_center(raw, _mono));
      }
    }

    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: _rollMargins(settings),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisSize: pw.MainAxisSize.min,
        children: children,
      ),
    ));
    return doc.save();
  }

  PdfPageFormat _rollMargins(Map<String, String> settings) =>
      _rollFormat(settings).copyWith(
        marginLeft: 6,
        marginRight: 6,
        marginTop: 8,
        marginBottom: 8,
      );

  /// Envía un PDF a una impresora de Windows por su nombre (modo 'grafica').
  ///
  /// Busca la [Printer] cuyo `name` coincida (case-insensitive/trim) en
  /// `Printing.listPrinters()`. Si no la encuentra, registra un WARN y devuelve
  /// `false`. Best-effort: nunca lanza (todo envuelto en try/catch → WARN +
  /// false). No pasa por la [PrintQueue] de bytes ESC/POS: es una ruta paralela.
  Future<bool> printPdfToWindows(
    String printerName,
    Uint8List pdfBytes,
    String jobName,
  ) async {
    final target = printerName.trim();
    if (target.isEmpty) {
      appLogger.warn(
          'Impresión gráfica omitida ($jobName): impresora no configurada.');
      return false;
    }
    try {
      final printers = await Printing.listPrinters();
      Printer? printer;
      for (final p in printers) {
        if (p.name.trim().toLowerCase() == target.toLowerCase()) {
          printer = p;
          break;
        }
      }
      if (printer == null) {
        appLogger.warn(
            'Impresión gráfica ($jobName): no se encontró la impresora '
            '"$printerName" en Windows.');
        return false;
      }
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (_) async => pdfBytes,
        name: jobName,
      );
      return true;
    } catch (e, st) {
      appLogger.warn('Falló la impresión gráfica ($jobName).', e, st);
      return false;
    }
  }

  // ─── Wiring de alto nivel (best-effort, tras el commit de la BD) ─────────

  /// Imprime el ticket de venta y, opcionalmente, la comanda de cocina al
  /// cobrar. No-op si el flag `impresion_activa` está OFF. Nunca lanza.
  ///
  /// [includeKitchen] va en `false` para el cobro diferido (pagar-al-final):
  /// la comanda ya se imprimió al enviar la orden a cocina, no hay que
  /// duplicarla. [reprint] fuerza la marca "— REIMPRESIÓN —" y nunca imprime
  /// comanda.
  Future<void> printSaleAndKitchen({
    required Order order,
    required List<OrderItem> items,
    required Payment payment,
    required Map<String, String> settings,
    required Employee employee,
    bool includeKitchen = true,
    bool reprint = false,
  }) async {
    if (!printingEnabled(settings)) return;
    try {
      if (printerMode(settings) == 'grafica') {
        // Ruta gráfica: PDF a la impresora de Windows seleccionada.
        final printerName = (settings['printer_address'] ?? '').trim();
        final ticket = await buildSalesTicketPdf(
          order: order,
          items: items,
          payment: payment,
          settings: settings,
          employee: employee,
          reprint: reprint,
        );
        await printPdfToWindows(
            printerName, ticket, 'Ticket ${order.orderNumber}');

        if (includeKitchen && !reprint) {
          final kitchen = await buildKitchenTicketPdf(
            order: order,
            items: items,
            settings: settings,
          );
          await printPdfToWindows(
              printerName, kitchen, 'Comanda ${order.orderNumber}');
        }
        return;
      }

      // Ruta térmica ESC/POS (sin cambios).
      final transport = transportFor(settings);
      final ticket = await buildSalesTicket(
        order: order,
        items: items,
        payment: payment,
        settings: settings,
        employee: employee,
        reprint: reprint,
      );
      await queue.enqueue(
          transport, ticket, 'Ticket ${order.orderNumber}');

      if (includeKitchen && !reprint) {
        final kitchen = await buildKitchenTicket(
          order: order,
          items: items,
          settings: settings,
        );
        await queue.enqueue(
            transport, kitchen, 'Comanda ${order.orderNumber}');
      }
    } catch (e, st) {
      appLogger.warn('No se pudo construir el documento de impresión.', e, st);
    }
  }

  /// Imprime solo la comanda de cocina (envío a cocina sin cobrar). No-op si
  /// `impresion_activa` está OFF. Nunca lanza.
  Future<void> printKitchenOnly({
    required Order order,
    required List<OrderItem> items,
    required Map<String, String> settings,
  }) async {
    if (!printingEnabled(settings)) return;
    try {
      if (printerMode(settings) == 'grafica') {
        final printerName = (settings['printer_address'] ?? '').trim();
        final kitchen = await buildKitchenTicketPdf(
          order: order,
          items: items,
          settings: settings,
        );
        await printPdfToWindows(
            printerName, kitchen, 'Comanda ${order.orderNumber}');
        return;
      }

      final transport = transportFor(settings);
      final kitchen = await buildKitchenTicket(
        order: order,
        items: items,
        settings: settings,
      );
      await queue.enqueue(
          transport, kitchen, 'Comanda ${order.orderNumber}');
    } catch (e, st) {
      appLogger.warn('No se pudo construir la comanda de cocina.', e, st);
    }
  }

  /// Reimprime en cocina una comanda marcada "CANCELADO" para una línea anulada
  /// (4.3), para que la cocina sepa no preparar (o descartar) ese item. Es
  /// best-effort y detrás de `impresion_activa`; nunca rompe la anulación.
  Future<void> printItemCancellation({
    required Order order,
    required OrderItem item,
    required Map<String, String> settings,
  }) async {
    if (!printingEnabled(settings)) return;
    try {
      // En modo gráfico reusamos la comanda de cocina de un solo item (sin el
      // realce ESC/POS); el aviso "CANCELADO" queda en el nombre del documento.
      if (printerMode(settings) == 'grafica') {
        final printerName = (settings['printer_address'] ?? '').trim();
        final pdf = await buildKitchenTicketPdf(
          order: order,
          items: [item],
          settings: settings,
        );
        await printPdfToWindows(
            printerName, pdf, 'CANCELADO ${order.orderNumber}');
        return;
      }

      final profile = await _profile();
      final g = Generator(_paperSize(settings), profile);
      final bytes = <int>[];
      bytes.addAll(g.reset());
      bytes.addAll(g.text(_san('*** CANCELADO ***'),
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          )));
      bytes.addAll(g.text(_san('Folio: ${order.orderNumber}'),
          styles: const PosStyles(align: PosAlign.center)));
      bytes.addAll(g.hr());
      bytes.addAll(g.text(_san('CANCELADO: ${item.quantity}x ${item.productName}'),
          styles: const PosStyles(
              bold: true, height: PosTextSize.size2, width: PosTextSize.size2)));
      bytes.addAll(g.cut());

      final transport = transportFor(settings);
      await queue.enqueue(
          transport, bytes, 'Cancelación ${order.orderNumber}');
    } catch (e, st) {
      appLogger.warn('No se pudo imprimir la comanda de cancelación.', e, st);
    }
  }

  /// Dispara el pulso de apertura de la gaveta. No-op si `gaveta_activa` está
  /// OFF. El registro en auditoría lo hace el caller (distinto según sea
  /// apertura manual sin venta o automática al cobrar en efectivo).
  Future<void> openDrawer(Map<String, String> settings) async {
    if (!drawerEnabled(settings)) return;
    // La gaveta abre por un pulso ESC/POS a través de la impresora térmica; una
    // impresora de inyección/láser (modo 'grafica') no tiene puerto de gaveta.
    if (printerMode(settings) == 'grafica') {
      appLogger.warn(
          'Apertura de gaveta omitida: solo funciona con impresora térmica.');
      return;
    }
    final transport = transportFor(settings);
    await queue.enqueue(transport, buildDrawerKick(), 'Gaveta');
  }

  /// Ticket de ejemplo para el botón "Imprimir ticket de prueba" de Settings.
  Future<List<int>> buildTestTicket(Map<String, String> settings) async {
    final profile = await _profile();
    final g = Generator(_paperSize(settings), profile);
    final businessName = settings['business_name'] ?? 'La Tercia';

    final bytes = <int>[];
    bytes.addAll(g.reset());
    bytes.addAll(g.text(_san(businessName),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        )));
    bytes.addAll(g.text('TICKET DE PRUEBA',
        styles: const PosStyles(align: PosAlign.center, bold: true)));
    bytes.addAll(g.hr());
    bytes.addAll(g.text(_san(
        'Ancho: ${settings['printer_width'] ?? '80'}mm')));
    bytes.addAll(g.text(_san(
        'Transporte: ${settings['printer_transport'] ?? 'red'}')));
    bytes.addAll(g.text(_san(formatDateTime(DateTime.now()))));
    bytes.addAll(g.hr());
    bytes.addAll(g.text('Si lees esto, la impresora funciona.',
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.cut());
    return bytes;
  }

  /// Envía el ticket de prueba por el transporte configurado. Devuelve `true`
  /// si se imprimió. Usado por el botón de Settings.
  Future<bool> printTestTicket(Map<String, String> settings) async {
    if (printerMode(settings) == 'grafica') {
      final printerName = (settings['printer_address'] ?? '').trim();
      final pdf = await buildTestTicketPdf(settings);
      return printPdfToWindows(printerName, pdf, 'Ticket de prueba');
    }
    final transport = transportFor(settings);
    final bytes = await buildTestTicket(settings);
    return queue.enqueue(transport, bytes, 'Ticket de prueba');
  }
}

final printServiceProvider = Provider<PrintService>((ref) {
  return PrintService();
});
