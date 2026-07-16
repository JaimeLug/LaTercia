import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';
import 'package:latercia/core/services/checkout_service.dart';
import 'package:latercia/core/services/print_service.dart';

/// Transporte falso que falla las primeras [failTimes] veces y luego "imprime".
class _FakeTransport implements PrinterTransport {
  _FakeTransport({required this.failTimes});

  final int failTimes;
  int attempts = 0;

  @override
  Future<void> send(List<int> bytes) async {
    attempts++;
    if (attempts <= failTimes) {
      throw Exception('impresora no responde (intento $attempts)');
    }
  }
}

/// ¿[haystack] termina exactamente con [needle]?
bool _endsWith(List<int> haystack, List<int> needle) {
  if (haystack.length < needle.length) return false;
  final tail = haystack.sublist(haystack.length - needle.length);
  for (var i = 0; i < needle.length; i++) {
    if (tail[i] != needle[i]) return false;
  }
  return true;
}

void main() {
  // CapabilityProfile.load() usa rootBundle para leer el asset del paquete.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // formatDateTime/formatTime usan el locale 'es_MX'.
    await initializeDateFormatting('es_MX', null);
  });

  late AppDatabase db;
  late PrintService printService;
  late CheckoutService checkout;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    printService = PrintService();
    checkout = CheckoutService(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Crea una venta real (con un item que lleva un modificador) y devuelve la
  /// orden + items + pago + empleado, para alimentar los builders de bytes.
  Future<
      ({
        Order order,
        List<OrderItem> items,
        Payment payment,
        Employee employee,
      })> makeSale() async {
    final products = await db.productsDao.getAllProducts();
    final product = products.first;
    final mods = await db.modifiersDao.getAllModifiers();

    final result = await checkout.checkout(
      cartItems: [
        CartItem(
          product: product,
          modifiers: mods.isNotEmpty ? [mods.first] : const [],
          quantity: 2,
          note: 'sin hielo',
        ),
      ],
      type: 'mesa',
      employeeId: 1,
      tableId: null,
      note: 'mesa junto a la ventana',
      subtotal: product.price * 2,
      discountAmount: 5,
      taxAmount: 3,
      total: product.price * 2 - 5 + 3,
      paymentMethod: 'efectivo',
      amountTendered: 500,
      changeGiven: 100,
    );

    final payments = await db.paymentsDao.getPaymentsForOrder(result.order.id);
    final employees = await db.employeesDao.getAllEmployees();
    final employee = employees.firstWhere((e) => e.id == 1);

    return (
      order: result.order,
      items: result.items,
      payment: payments.last,
      employee: employee,
    );
  }

  group('ticket de venta (bytes)', () {
    // GS V 0 = corte total en esc_pos_utils_plus.
    const cutSequence = [0x1D, 0x56, 0x30];

    test('a 80mm genera bytes no vacíos y termina en el corte de papel',
        () async {
      final sale = await makeSale();
      final bytes = await printService.buildSalesTicket(
        order: sale.order,
        items: sale.items,
        payment: sale.payment,
        settings: const {'printer_width': '80', 'currency_symbol': r'$'},
        employee: sale.employee,
      );

      expect(bytes, isNotEmpty);
      expect(_endsWith(bytes, cutSequence), isTrue,
          reason: 'el documento debe terminar con el corte de papel');
    });

    test('a 58mm genera bytes no vacíos y termina en el corte de papel',
        () async {
      final sale = await makeSale();
      final bytes = await printService.buildSalesTicket(
        order: sale.order,
        items: sale.items,
        payment: sale.payment,
        settings: const {'printer_width': '58', 'currency_symbol': r'$'},
        employee: sale.employee,
      );

      expect(bytes, isNotEmpty);
      expect(_endsWith(bytes, cutSequence), isTrue);
    });

    test('la reimpresión no rompe la generación (marca REIMPRESIÓN)',
        () async {
      final sale = await makeSale();
      final bytes = await printService.buildSalesTicket(
        order: sale.order,
        items: sale.items,
        payment: sale.payment,
        settings: const {'printer_width': '80'},
        employee: sale.employee,
        reprint: true,
      );
      expect(bytes, isNotEmpty);
      expect(_endsWith(bytes, cutSequence), isTrue);
    });
  });

  group('comanda de cocina', () {
    test('genera bytes no vacíos y termina en el corte de papel', () async {
      final sale = await makeSale();
      final bytes = await printService.buildKitchenTicket(
        order: sale.order,
        items: sale.items,
        settings: const {'printer_width': '80'},
      );
      expect(bytes, isNotEmpty);
      expect(_endsWith(bytes, [0x1D, 0x56, 0x30]), isTrue);
    });

    test('kitchenTicketLines incluye nombre de producto y modificadores '
        'parseados, sin precios', () async {
      final sale = await makeSale();
      final product = sale.items.first.productName;
      final mods = await db.modifiersDao.getAllModifiers();
      final modName = mods.first.name;

      final lines = kitchenTicketLines(sale.order, sale.items);
      final joined = lines.join('\n');

      expect(joined, contains(product));
      expect(joined, contains(modName));
      // La nota del item y de la orden aparecen.
      expect(joined, contains('sin hielo'));
      expect(joined, contains('mesa junto a la ventana'));
      // Es MESA.
      expect(lines.first, 'MESA');
      // Sin precios: no aparece el símbolo de moneda.
      expect(joined, isNot(contains(r'$')));
    });
  });

  group('builders PDF (modo grafica)', () {
    // Header de un documento PDF: "%PDF".
    const pdfHeader = [0x25, 0x50, 0x44, 0x46];

    bool startsWithPdf(List<int> bytes) {
      if (bytes.length < pdfHeader.length) return false;
      for (var i = 0; i < pdfHeader.length; i++) {
        if (bytes[i] != pdfHeader[i]) return false;
      }
      return true;
    }

    for (final width in ['58', '80']) {
      test('buildSalesTicketPdf a ${width}mm produce un PDF válido', () async {
        final sale = await makeSale();
        final bytes = await printService.buildSalesTicketPdf(
          order: sale.order,
          items: sale.items,
          payment: sale.payment,
          settings: {'printer_width': width, 'currency_symbol': r'$'},
          employee: sale.employee,
        );
        expect(bytes, isNotEmpty);
        expect(startsWithPdf(bytes), isTrue,
            reason: 'debe empezar con el header %PDF');
      });

      test('buildKitchenTicketPdf a ${width}mm produce un PDF válido',
          () async {
        final sale = await makeSale();
        final bytes = await printService.buildKitchenTicketPdf(
          order: sale.order,
          items: sale.items,
          settings: {'printer_width': width},
        );
        expect(bytes, isNotEmpty);
        expect(startsWithPdf(bytes), isTrue);
      });

      test('buildTestTicketPdf a ${width}mm produce un PDF válido', () async {
        final bytes = await printService.buildTestTicketPdf(
          {'printer_width': width, 'business_name': 'La Tercia'},
        );
        expect(bytes, isNotEmpty);
        expect(startsWithPdf(bytes), isTrue);
      });
    }

    test('el ticket de venta PDF con reimpresión sigue siendo válido',
        () async {
      final sale = await makeSale();
      final bytes = await printService.buildSalesTicketPdf(
        order: sale.order,
        items: sale.items,
        payment: sale.payment,
        settings: const {'printer_width': '80'},
        employee: sale.employee,
        reprint: true,
      );
      expect(startsWithPdf(bytes), isTrue);
    });
  });

  group('pulso de gaveta', () {
    test('produce exactamente los bytes ESC p 0 25 250', () {
      expect(printService.buildDrawerKick(), [0x1B, 0x70, 0x00, 0x19, 0xFA]);
      expect(kDrawerKickBytes, [0x1B, 0x70, 0x00, 0x19, 0xFA]);
    });
  });

  group('selección de transporte (6.1 Linux)', () {
    test('usb en Windows sigue devolviendo el spooler win32', () {
      final t = printerTransportFromSettings(
          {'printer_transport': 'usb', 'printer_address': 'EPSON-TM'});
      // El runner de test es Windows: no debe romper el camino existente.
      expect(t, isA<WindowsRawPrinterTransport>());
    });

    test('red devuelve NetworkPrinterTransport con host:puerto', () {
      final t = printerTransportFromSettings(
          {'printer_transport': 'red', 'printer_address': '192.168.1.50:9100'});
      expect(t, isA<NetworkPrinterTransport>());
    });

    test('LinuxPrinterTransport lanza fuera de Linux', () {
      expect(
        () => LinuxPrinterTransport('/dev/usb/lp0').send([0x1B]),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('sin dirección devuelve null (impresora no configurada)', () {
      expect(
          printerTransportFromSettings(
              {'printer_transport': 'usb', 'printer_address': ''}),
          isNull);
    });
  });

  group('cola de impresión (best-effort con reintento)', () {
    test('reintenta N veces y reporta fallo sin lanzar hacia el caller',
        () async {
      final queue = PrintQueue(maxRetries: 3, baseBackoff: Duration.zero);
      final transport = _FakeTransport(failTimes: 999);

      final ok = await queue.enqueue(transport, [1, 2, 3], 'ticket');

      expect(ok, isFalse);
      expect(transport.attempts, 3, reason: 'debe agotar los 3 intentos');
      expect(queue.lastJobFailed, isTrue);
      expect(queue.lastError, 'ticket');
    });

    test('reintenta y tiene éxito antes de agotar los intentos', () async {
      final queue = PrintQueue(maxRetries: 3, baseBackoff: Duration.zero);
      final transport = _FakeTransport(failTimes: 2);

      final ok = await queue.enqueue(transport, [1, 2, 3], 'ticket');

      expect(ok, isTrue);
      expect(transport.attempts, 3);
      expect(queue.lastJobFailed, isFalse);
    });

    test('transporte nulo (impresora no configurada) reporta fallo', () async {
      final queue = PrintQueue(maxRetries: 3, baseBackoff: Duration.zero);
      final ok = await queue.enqueue(null, [1, 2, 3], 'ticket');
      expect(ok, isFalse);
      expect(queue.lastJobFailed, isTrue);
    });
  });
}
