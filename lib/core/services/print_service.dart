import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:win32/win32.dart';

import '../database/database.dart';
import '../utils/app_logger.dart';
import '../utils/formatters.dart';
import '../utils/pricing.dart';
import 'shift_service.dart' show ShiftSummary;

// Servicio de impresión ESC/POS térmica + PDF + gaveta. `docs/impresion.md`.

/// Pulso ESC/POS estándar de apertura de gaveta (no `Generator.drawer()`).
/// `docs/impresion.md` §Gaveta.
const List<int> kDrawerKickBytes = [0x1B, 0x70, 0x00, 0x19, 0xFA];

/// Comando alterno `DLE DC4 0 1 0` que algunas gavetas usan. `docs/impresion.md`.
const List<int> kDrawerKickAltBytes = [0x10, 0x14, 0x00, 0x01, 0x00];

// ─── Transportes (docs/impresion.md §Transportes) ────────────────────────────

/// Canal que envía bytes crudos ESC/POS. Lanza si falla; la [PrintQueue]
/// reintenta y reporta sin romper la venta. `docs/impresion.md`.
abstract class PrinterTransport {
  Future<void> send(List<int> bytes);
}

/// Impresora de red (socket RAW 9100): escribe, flush y **cierra grácilmente**
/// (`destroy()` solo como red de seguridad). `docs/impresion.md` §Red — ahí
/// está el bug del cierre abrupto que se comía el ticket de venta.
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
      // Cierre grácil (entrega completa, a diferencia de destroy()), con
      // timeout para no colgar la cola. docs/impresion.md §Red.
      await socket.close().timeout(timeout);
    } finally {
      socket.destroy();
    }
  }
}

/// Impresora de Windows (USB) vía spooler, bytes RAW. `docs/impresion.md`
/// §Windows.
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
        throw OSError('OpenPrinter falló para "$printerName"', GetLastError());
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

            if (WritePrinter(hPrinter, dataPtr, bytes.length, bytesWritten) ==
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

/// Impresora USB/local en Linux: `/dev/...` (RAW directo) o cola CUPS
/// (`lp -o raw`). `docs/impresion.md` §Linux.
class LinuxPrinterTransport implements PrinterTransport {
  LinuxPrinterTransport(this.target,
      {this.timeout = const Duration(seconds: 8)});

  final String target;
  final Duration timeout;

  @override
  Future<void> send(List<int> bytes) async {
    if (!Platform.isLinux) {
      throw UnsupportedError(
          'La impresión USB/local por CUPS solo está disponible en Linux.');
    }

    if (target.startsWith('/dev/')) {
      // Escritura RAW directa al dispositivo, con timeout (por si el USB se
      // desconecta a media escritura). docs/impresion.md §Linux.
      final raf = await File(target).open(mode: FileMode.writeOnlyAppend);
      try {
        await raf.writeFrom(bytes).timeout(timeout);
        await raf.flush().timeout(timeout);
      } finally {
        await raf.close();
      }
      return;
    }

    // Cola CUPS vía `lp -o raw` por stdin. `lp` devuelve 0 al encolar, no al
    // imprimir: un 0 no garantiza impresión real. docs/impresion.md §Linux.
    final process = await Process.start('lp', ['-d', target, '-o', 'raw']);
    process.stdin.add(bytes);
    await process.stdin.flush();
    await process.stdin.close();
    int code;
    try {
      code = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      process.kill();
      throw Exception(
          'lp no respondió en ${timeout.inSeconds}s (impresora desconectada o CUPS colgado).');
    }
    if (code != 0) {
      final err = await process.stderr.transform(systemEncoding.decoder).join();
      throw Exception('lp devolvió $code: $err');
    }
  }
}

/// Enumera las impresoras instaladas en Windows (`EnumPrinters`) para el
/// desplegable de Configuración. Vacía fuera de Windows. `docs/impresion.md`.
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

/// Impresoras virtuales (PDF/XPS/OneNote/Fax) que no entienden ESC/POS crudo,
/// para avisar en la UI. `docs/impresion.md` §Utilidades.
bool isVirtualPrinter(String name) {
  final n = name.toLowerCase();
  return n.contains('pdf') ||
      n.contains('xps') ||
      n.contains('onenote') ||
      n.contains('fax') ||
      n.contains('microsoft print to');
}

/// Columnas del papel: 32 a 58 mm, 48 a 80 mm. `docs/impresion.md` §Utilidades.
int paperColumns(Map<String, String> settings) =>
    settings['printer_width'] == '58' ? 32 : 48;

/// Sanea texto para impresión (Unicode → ASCII, descarta >0xFF), para no romper
/// los bytes ni el PDF. `docs/impresion.md` §Utilidades.
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

/// Texto plano del ticket de prueba al ancho real, para vista previa en
/// pantalla sin impresora. `docs/impresion.md` §Utilidades.
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

/// Elige el transporte según los settings (red/usb, por plataforma); null si no
/// hay dirección configurada. `docs/impresion.md` §Transportes.
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

/// Líneas de texto de la comanda de cocina (sin ESC/POS, sin precios), aislada
/// para poder testearla. `docs/impresion.md` §Documentos.
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
      lines
          .add(mod.included ? '  + ${mod.name} (incluido)' : '  + ${mod.name}');
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

/// Cola FIFO de impresión con reintento + backoff. Nunca lanza hacia el caller
/// (best-effort: no rompe la venta). `docs/impresion.md` §Cola.
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
      appLogger
          .warn('Impresión omitida ($description): impresora no configurada.');
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

  /// Sanea texto (latin1 no codifica "—" y lanzaría). `docs/impresion.md`.
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

    // Encabezado: logo arriba (best-effort; si no carga, sigue el nombre).
    final logo = await _resolveThermalLogo(settings);
    if (logo != null) {
      bytes.addAll(g.image(logo, align: PosAlign.center));
    }
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

    bytes.addAll(_brandDivider(g, settings));

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

    // TOTAL en video invertido (`reverse`, capacidad nativa de la impresora,
    // no imagen). docs/impresion.md §Documentos.
    bytes.addAll(g.row([
      PosColumn(
        text: 'TOTAL',
        width: 6,
        styles: const PosStyles(
            bold: true, height: PosTextSize.size2, reverse: true),
      ),
      PosColumn(
        text: _san(money(order.total)),
        width: 6,
        styles: const PosStyles(
          bold: true,
          align: PosAlign.right,
          height: PosTextSize.size2,
          reverse: true,
        ),
      ),
    ]));

    bytes.addAll(_brandDivider(g, settings));

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

  /// Separador de marca (patrón ASCII repetido, no imagen; ASCII para que se
  /// vea igual en cualquier impresora). `docs/impresion.md` §Documentos.
  List<int> _brandDivider(Generator g, Map<String, String> settings) {
    const unit = '*  ';
    final width = paperColumns(settings);
    final line = (unit * (width ~/ unit.length + 1)).substring(0, width);
    return g.text(line);
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

    final typeLabel = _orderTypeLabels[order.type] ?? order.type.toUpperCase();

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
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2)));
      for (final mod in _parseModifiers(item.modifiersJson)) {
        bytes.addAll(g.text(_san(
            mod.included ? '  + ${mod.name} (incluido)' : '  + ${mod.name}')));
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

  // ─── Comanda de reparto (delivery) ──────────────────────────────────────

  /// Comanda de REPARTO: datos del cliente + items; marca "COBRAR AL ENTREGAR"
  /// si no está pagada. `docs/impresion.md` §Documentos.
  Future<List<int>> buildDeliveryTicket({
    required Order order,
    required List<OrderItem> items,
    required Map<String, String> settings,
  }) async {
    final profile = await _profile();
    final g = Generator(_paperSize(settings), profile);
    final symbol = settings['currency_symbol'] ?? r'$';
    final decimals = int.tryParse(settings['currency_decimals'] ?? '2') ?? 2;
    String money(double v) => formatCurrency(v, symbol, decimals: decimals);

    final bytes = <int>[];
    bytes.addAll(g.reset());

    bytes.addAll(g.text(_san('COMANDA DE REPARTO'),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        )));
    bytes.addAll(g.text(_san('Folio: ${order.orderNumber}'),
        styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.text(_san('Hora: ${formatTime(order.createdAt)}'),
        styles: const PosStyles(align: PosAlign.center)));

    bytes.addAll(g.hr());

    // Datos del cliente — lo que necesita el repartidor para llegar.
    bytes.addAll(g.text(_san('Cliente: ${order.customerName ?? "—"}'),
        styles: const PosStyles(bold: true)));
    if (order.customerPhone != null && order.customerPhone!.trim().isNotEmpty) {
      bytes.addAll(g.text(_san('Tel: ${order.customerPhone}'),
          styles: const PosStyles(bold: true, height: PosTextSize.size2)));
    }
    if (order.deliveryZone != null) {
      bytes.addAll(g.text(_san('Zona: ${order.deliveryZone}')));
    }
    if (order.customerAddress != null &&
        order.customerAddress!.trim().isNotEmpty) {
      bytes.addAll(g.text(_san('Dirección:')));
      bytes.addAll(g.text(_san(order.customerAddress!),
          styles: const PosStyles(bold: true)));
    }

    bytes.addAll(g.hr());

    // Lista corta de lo que lleva (sin precios ni modificadores: eso ya lo
    // tiene la comanda de cocina; aquí solo interesa el bulto a entregar).
    for (final item in items) {
      bytes.addAll(g.text(_san('${item.quantity}x ${item.productName}')));
    }

    bytes.addAll(g.hr());

    if (order.paymentStatus != 'pagado') {
      bytes.addAll(g.text(_san('COBRAR AL ENTREGAR'),
          styles: const PosStyles(align: PosAlign.center, bold: true)));
      bytes.addAll(g.row([
        PosColumn(
            text: 'TOTAL',
            width: 6,
            styles: const PosStyles(bold: true, height: PosTextSize.size2)),
        PosColumn(
          text: _san(money(order.total)),
          width: 6,
          styles: const PosStyles(
              bold: true, align: PosAlign.right, height: PosTextSize.size2),
        ),
      ]));
    } else {
      bytes.addAll(g.text(_san('YA PAGADO — no cobrar'),
          styles: const PosStyles(align: PosAlign.center, bold: true)));
    }

    bytes.addAll(g.cut());
    return bytes;
  }

  // ─── Corte X/Z ────────────────────────────────────────────────────────────

  /// Documento ESC/POS del corte X (abierto) o Z (cerrado). `docs/impresion.md`
  /// §Documentos.
  Future<List<int>> buildCutTicket({
    required ShiftSummary summary,
    required Map<String, String> settings,
    required bool isZ,
  }) async {
    final profile = await _profile();
    final g = Generator(_paperSize(settings), profile);
    final symbol = settings['currency_symbol'] ?? r'$';
    final decimals = int.tryParse(settings['currency_decimals'] ?? '2') ?? 2;
    final businessName = settings['business_name'] ?? 'La Tercia';
    final shift = summary.shift;

    String money(double v) => formatCurrency(v, symbol, decimals: decimals);
    const center = PosStyles(align: PosAlign.center);

    final bytes = <int>[];
    bytes.addAll(g.reset());

    bytes.addAll(g.text(_san(businessName),
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2)));
    bytes.addAll(g.text(_san(isZ ? 'CORTE Z' : 'CORTE X (PARCIAL)'),
        styles: const PosStyles(align: PosAlign.center, bold: true)));
    if (isZ && shift.zNumber != null) {
      bytes.addAll(g.text(_san('Folio Z-${shift.zNumber}'), styles: center));
    }
    bytes.addAll(g.text(_san('Turno #${shift.id}'), styles: center));
    bytes.addAll(g.text(
        _san(formatDateTime(shift.startedAt) +
            (shift.endedAt != null
                ? ' — ${formatDateTime(shift.endedAt!)}'
                : '')),
        styles: center));

    bytes.addAll(g.hr());
    bytes.addAll(_kv(g, 'Fondo inicial', money(shift.startingCash)));
    bytes.addAll(_kv(g, 'Ventas efectivo', money(summary.cashSales)));
    bytes.addAll(_kv(g, 'Depósitos', money(summary.deposits)));
    bytes.addAll(_kv(g, 'Retiros', '-${money(summary.withdrawals)}'));
    bytes.addAll(_kv(g, 'Esperado en caja', money(summary.expectedCash)));
    if (summary.countedCash != null) {
      bytes.addAll(_kv(g, 'Efectivo contado', money(summary.countedCash!)));
      bytes.addAll(_kv(g, 'Diferencia',
          '${summary.difference! >= 0 ? '+' : ''}${money(summary.difference!)}'));
    }

    bytes.addAll(g.hr());
    bytes.addAll(g.text(_san('Desglose por método de pago'),
        styles: const PosStyles(bold: true)));
    if (summary.paymentsByMethod.isEmpty) {
      bytes.addAll(g.text(_san('Sin pagos registrados')));
    } else {
      for (final e in summary.paymentsByMethod.entries) {
        bytes.addAll(_kv(g, e.key, money(e.value)));
      }
    }

    bytes.addAll(g.hr());
    bytes.addAll(_kv(g, 'Descuentos otorgados', money(summary.discountsTotal)));
    if (summary.tipsTotal > 0) {
      bytes.addAll(_kv(g, 'Propinas', money(summary.tipsTotal)));
    }
    if (summary.refundsTotal > 0) {
      bytes.addAll(_kv(g, 'Reembolsos', '-${money(summary.refundsTotal)}'));
    }
    bytes.addAll(_kv(g, 'Cancelaciones',
        '${summary.cancelledCount} (${money(summary.cancelledAmount)})'));
    bytes.addAll(g.row([
      PosColumn(
          text: 'TOTAL VENTAS',
          width: 6,
          styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
        text: _san(money(shift.totalSales)),
        width: 6,
        styles: const PosStyles(
            bold: true, align: PosAlign.right, height: PosTextSize.size2),
      ),
    ]));

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

  /// Divisor de marca del PDF (mismo patrón que [_brandDivider]).
  pw.Widget _brandDividerPdf() => _center('*  ' * 14, _mono);

  /// TOTAL en caja negra (el PDF pinta fondo real; la térmica usa `reverse`).
  /// `docs/impresion.md` §Documentos.
  pw.Widget _boxedTotalPdf(String label, String value) => pw.Container(
        color: PdfColors.black,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(sanitizeTicketText(label),
                style: _monoMed.copyWith(color: PdfColors.white)),
            pw.Text(sanitizeTicketText(value),
                style: _monoMed.copyWith(color: PdfColors.white)),
          ],
        ),
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

  /// Logo del ticket TÉRMICO (personalizado o default `8.png`), reescalado a
  /// ~300 px antes del ESC/POS. Best-effort. `docs/impresion.md` §Logo.
  Future<img.Image?> _resolveThermalLogo(Map<String, String> settings) async {
    const logoWidth = 300;
    img.Image? decoded;

    final path = (settings['logo_path'] ?? '').trim();
    if (path.isNotEmpty) {
      try {
        final file = File(path);
        if (await file.exists()) {
          decoded = img.decodeImage(await file.readAsBytes());
        }
      } catch (e, st) {
        appLogger.warn(
            'No se pudo cargar el logo personalizado para el ticket térmico.',
            e,
            st);
      }
    }

    if (decoded == null) {
      try {
        final data = await rootBundle.load('assets/images/8.png');
        decoded = img.decodePng(data.buffer.asUint8List());
      } catch (e, st) {
        appLogger.warn(
            'No se pudo cargar el logo por defecto para el ticket térmico.',
            e,
            st);
        return null;
      }
    }

    if (decoded == null) return null;
    return img.copyResize(decoded, width: logoWidth);
  }

  /// Logo del ticket PDF (el personalizado o el default). Best-effort.
  /// `docs/impresion.md` §Logo.
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
      appLogger.warn(
          'No se pudo cargar el logo por defecto para el ticket.', e, st);
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
          child: pw.SizedBox(height: 46, width: 46, child: pw.Image(logo)),
        ),
        pw.SizedBox(height: 4),
      ],
      _center(businessName, _monoBig),
      if (slogan.isNotEmpty) _center(slogan, _mono),
      if (reprint) _center('— REIMPRESIÓN —', _monoBold),
      _center(formatDateTime(order.createdAt), _mono),
      _center('Folio: ${order.orderNumber}', _mono),
      if (showEmployee) _center('Atendió: ${employee.name}', _mono),
      _brandDividerPdf(),
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
      pw.SizedBox(height: 3),
      _boxedTotalPdf('TOTAL', money(order.total)),
      pw.SizedBox(height: 3),
      _brandDividerPdf(),
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
            sanitizeTicketText(mod.included
                ? '  + ${mod.name} (incluido)'
                : '  + ${mod.name}'),
            style: _mono));
      }
      if (item.itemNote != null && item.itemNote!.trim().isNotEmpty) {
        children.add(pw.Text(sanitizeTicketText('  * ${item.itemNote!.trim()}'),
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

  /// PDF de la comanda de reparto — mismo contenido que [buildDeliveryTicket].
  Future<Uint8List> buildDeliveryTicketPdf({
    required Order order,
    required List<OrderItem> items,
    required Map<String, String> settings,
  }) async {
    final symbol = settings['currency_symbol'] ?? r'$';
    final decimals = int.tryParse(settings['currency_decimals'] ?? '2') ?? 2;
    String money(double v) => formatCurrency(v, symbol, decimals: decimals);

    final children = <pw.Widget>[
      _center('COMANDA DE REPARTO', _monoBig),
      _center('Folio: ${order.orderNumber}', _mono),
      _center('Hora: ${formatTime(order.createdAt)}', _mono),
      _hrPdf(),
      pw.Text(sanitizeTicketText('Cliente: ${order.customerName ?? "—"}'),
          style: _monoBold),
      if (order.customerPhone != null && order.customerPhone!.trim().isNotEmpty)
        pw.Text(sanitizeTicketText('Tel: ${order.customerPhone}'),
            style: _monoMed),
      if (order.deliveryZone != null)
        pw.Text(sanitizeTicketText('Zona: ${order.deliveryZone}'),
            style: _mono),
      if (order.customerAddress != null &&
          order.customerAddress!.trim().isNotEmpty) ...[
        pw.Text(sanitizeTicketText('Dirección:'), style: _mono),
        pw.Text(sanitizeTicketText(order.customerAddress!), style: _monoBold),
      ],
      _hrPdf(),
    ];

    for (final item in items) {
      children.add(pw.Text(
          sanitizeTicketText('${item.quantity}x ${item.productName}'),
          style: _mono));
    }

    children.add(_hrPdf());
    if (order.paymentStatus != 'pagado') {
      children
        ..add(_center('COBRAR AL ENTREGAR', _monoBold))
        ..add(pw.Text(sanitizeTicketText('TOTAL: ${money(order.total)}'),
            style: _monoBig));
    } else {
      children.add(_center('YA PAGADO — no cobrar', _monoBold));
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

  /// PDF del corte X/Z — mismo contenido que [buildCutTicket].
  Future<Uint8List> buildCutTicketPdf({
    required ShiftSummary summary,
    required Map<String, String> settings,
    required bool isZ,
  }) async {
    final symbol = settings['currency_symbol'] ?? r'$';
    final decimals = int.tryParse(settings['currency_decimals'] ?? '2') ?? 2;
    final businessName = settings['business_name'] ?? 'La Tercia';
    final shift = summary.shift;

    String money(double v) => formatCurrency(v, symbol, decimals: decimals);

    final children = <pw.Widget>[
      _center(businessName, _monoBig),
      _center(isZ ? 'CORTE Z' : 'CORTE X (PARCIAL)', _monoBold),
      if (isZ && shift.zNumber != null)
        _center('Folio Z-${shift.zNumber}', _mono),
      _center('Turno #${shift.id}', _mono),
      _center(
          formatDateTime(shift.startedAt) +
              (shift.endedAt != null
                  ? ' — ${formatDateTime(shift.endedAt!)}'
                  : ''),
          _mono),
      _hrPdf(),
      _kvPdf('Fondo inicial', money(shift.startingCash)),
      _kvPdf('Ventas efectivo', money(summary.cashSales)),
      _kvPdf('Depósitos', money(summary.deposits)),
      _kvPdf('Retiros', '-${money(summary.withdrawals)}'),
      _kvPdf('Esperado en caja', money(summary.expectedCash)),
      if (summary.countedCash != null) ...[
        _kvPdf('Efectivo contado', money(summary.countedCash!)),
        _kvPdf('Diferencia',
            '${summary.difference! >= 0 ? '+' : ''}${money(summary.difference!)}'),
      ],
      _hrPdf(),
      pw.Text(sanitizeTicketText('Desglose por método de pago'),
          style: _monoBold),
      if (summary.paymentsByMethod.isEmpty)
        pw.Text(sanitizeTicketText('Sin pagos registrados'), style: _mono)
      else
        for (final e in summary.paymentsByMethod.entries)
          _kvPdf(e.key, money(e.value)),
      _hrPdf(),
      _kvPdf('Descuentos otorgados', money(summary.discountsTotal)),
      if (summary.tipsTotal > 0) _kvPdf('Propinas', money(summary.tipsTotal)),
      if (summary.refundsTotal > 0)
        _kvPdf('Reembolsos', '-${money(summary.refundsTotal)}'),
      _kvPdf('Cancelaciones',
          '${summary.cancelledCount} (${money(summary.cancelledAmount)})'),
      _kvPdf('TOTAL VENTAS', money(shift.totalSales), style: _monoMed),
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

  /// Envía un PDF a una impresora de Windows por nombre (modo 'grafica').
  /// Best-effort, nunca lanza. `docs/impresion.md` §"Dos modos".
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
        appLogger
            .warn('Impresión gráfica ($jobName): no se encontró la impresora '
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

  /// Imprime el ticket de venta y (opcional) la comanda al cobrar. No-op si
  /// `impresion_activa` OFF; nunca lanza. [includeKitchen]=false en cobro
  /// diferido; [reprint] marca "REIMPRESIÓN" y no imprime comanda.
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
          // Comanda de reparto aparte (2026-07-20): solo en delivery, con los
          // datos del cliente para el repartidor.
          if (order.type == 'delivery') {
            final delivery = await buildDeliveryTicketPdf(
              order: order,
              items: items,
              settings: settings,
            );
            await printPdfToWindows(
                printerName, delivery, 'Reparto ${order.orderNumber}');
          }
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
      await queue.enqueue(transport, ticket, 'Ticket ${order.orderNumber}');

      if (includeKitchen && !reprint) {
        final kitchen = await buildKitchenTicket(
          order: order,
          items: items,
          settings: settings,
        );
        await queue.enqueue(transport, kitchen, 'Comanda ${order.orderNumber}');

        if (order.type == 'delivery') {
          final delivery = await buildDeliveryTicket(
            order: order,
            items: items,
            settings: settings,
          );
          await queue.enqueue(
              transport, delivery, 'Reparto ${order.orderNumber}');
        }
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
        if (order.type == 'delivery') {
          final delivery = await buildDeliveryTicketPdf(
            order: order,
            items: items,
            settings: settings,
          );
          await printPdfToWindows(
              printerName, delivery, 'Reparto ${order.orderNumber}');
        }
        return;
      }

      final transport = transportFor(settings);
      final kitchen = await buildKitchenTicket(
        order: order,
        items: items,
        settings: settings,
      );
      await queue.enqueue(transport, kitchen, 'Comanda ${order.orderNumber}');

      if (order.type == 'delivery') {
        final delivery = await buildDeliveryTicket(
          order: order,
          items: items,
          settings: settings,
        );
        await queue.enqueue(
            transport, delivery, 'Reparto ${order.orderNumber}');
      }
    } catch (e, st) {
      appLogger.warn('No se pudo construir la comanda de cocina.', e, st);
    }
  }

  /// Imprime el corte X (parcial, turno abierto) o Z (turno cerrado). No-op
  /// si `impresion_activa` está OFF. Nunca lanza — igual que el resto de la
  /// impresión, es best-effort tras el cierre/consulta del turno.
  Future<void> printCutTicket({
    required ShiftSummary summary,
    required Map<String, String> settings,
    required bool isZ,
  }) async {
    if (!printingEnabled(settings)) return;
    final label = isZ ? 'Corte Z' : 'Corte X';
    final jobName = '$label turno ${summary.shift.id}';
    try {
      if (printerMode(settings) == 'grafica') {
        final printerName = (settings['printer_address'] ?? '').trim();
        final pdf = await buildCutTicketPdf(
            summary: summary, settings: settings, isZ: isZ);
        await printPdfToWindows(printerName, pdf, jobName);
        return;
      }

      final transport = transportFor(settings);
      final ticket =
          await buildCutTicket(summary: summary, settings: settings, isZ: isZ);
      await queue.enqueue(transport, ticket, jobName);
    } catch (e, st) {
      appLogger.warn('No se pudo construir el corte para imprimir.', e, st);
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
      bytes.addAll(g.text(
          _san('CANCELADO: ${item.quantity}x ${item.productName}'),
          styles: const PosStyles(
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2)));
      bytes.addAll(g.cut());

      final transport = transportFor(settings);
      await queue.enqueue(transport, bytes, 'Cancelación ${order.orderNumber}');
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
    bytes.addAll(g.text(_san('Ancho: ${settings['printer_width'] ?? '80'}mm')));
    bytes.addAll(
        g.text(_san('Transporte: ${settings['printer_transport'] ?? 'red'}')));
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
