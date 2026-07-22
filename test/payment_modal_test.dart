import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/providers/database_provider.dart';
import 'package:latercia/core/services/checkout_service.dart';
import 'package:latercia/features/pos/widgets/payment_modal.dart';

/// FASE audit M4 — tests de widget de la lógica de dinero del PaymentModal:
/// cálculo de cambio (solo efectivo) y pagos mixtos (varios tramos).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  /// Monta el modal; [onPayments] captura los drafts. Devuelve null en
  /// onCheckout para no arrastrar impresión/recibo (el modal muestra un
  /// snackbar y termina; ya capturamos lo que nos importa).
  Future<void> pumpModal(
    WidgetTester tester, {
    required double total,
    required void Function(List<PaymentDraft>) onPayments,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: PaymentModal(
              total: total,
              printKitchenComanda: false,
              onCheckout: ({required List<PaymentDraft> payments}) async {
                onPayments(payments);
                return null;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('efectivo: el cambio es recibido − total y va en el draft',
      (tester) async {
    List<PaymentDraft>? captured;
    await pumpModal(tester, total: 100, onPayments: (p) => captured = p);

    // El campo de "Recibido" es el primero (método por defecto = efectivo).
    await tester.enterText(find.byType(TextField).first, '150');
    await tester.pumpAndSettle();

    // El modal es scrollable; con el botón "Dividir cuenta" arriba, el botón
    // de confirmar puede quedar fuera del viewport del test.
    await tester.ensureVisible(find.text('Confirmar pago'));
    await tester.tap(find.text('Confirmar pago'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured, hasLength(1));
    expect(captured!.first.method, 'efectivo');
    expect(captured!.first.amountTendered, 150);
    expect(captured!.first.changeGiven, 50);
  });

  testWidgets(
      'pagos mixtos: tarjeta parcial + efectivo, cambio solo en efectivo',
      (tester) async {
    List<PaymentDraft>? captured;
    await pumpModal(tester, total: 100, onPayments: (p) => captured = p);

    // Tramo 1: tarjeta por 60 (parcial).
    await tester.tap(find.text('Tarjeta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '60'); // campo "Monto"
    await tester.pumpAndSettle();

    // Agregar el parcial y seguir con el saldo.
    await tester.ensureVisible(find.textContaining('Agregar'));
    await tester.tap(find.textContaining('Agregar'));
    await tester.pumpAndSettle();

    // Tramo 2: efectivo cubre el resto (40) con 50 recibido → cambio 10.
    await tester.enterText(find.byType(TextField).first, '50');
    await tester.pumpAndSettle();
    // El modal es scrollable; con un pago parcial + el checkbox de factura el
    // botón puede quedar fuera del viewport del test — hay que traerlo a la vista.
    await tester.ensureVisible(find.textContaining('Cobrar resto'));
    await tester.tap(find.textContaining('Cobrar resto'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured, hasLength(2));
    final card = captured!.firstWhere((d) => d.method == 'tarjeta');
    final cash = captured!.firstWhere((d) => d.method == 'efectivo');
    expect(card.amountTendered, 60);
    expect(card.changeGiven, 0);
    expect(cash.amountTendered, 50);
    expect(cash.changeGiven, 10, reason: 'cambio solo sobre el efectivo');
    // Aplicado total = (60-0)+(50-10) = 100 = total.
    final applied =
        captured!.fold(0.0, (a, d) => a + d.amountTendered - d.changeGiven);
    expect(applied, 100);
  });

  testWidgets(
      'dividir cuenta: precarga cada tramo con su parte y suman el total '
      '(docs/division-cuenta.md)', (tester) async {
    List<PaymentDraft>? captured;
    await pumpModal(tester, total: 100, onPayments: (p) => captured = p);

    await tester.ensureVisible(find.text('Dividir cuenta'));
    await tester.tap(find.text('Dividir cuenta'));
    await tester.pumpAndSettle();

    // Diálogo "¿Entre cuántas personas?" — sube de 2 a 3 con el "+".
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dividir'));
    await tester.pumpAndSettle();

    // 100/3 → 33.34, 33.33, 33.33 (splitEvenly, el sobrante a la primera).
    expect(find.text('Dividido entre 3 — parte 1 de 3'), findsOneWidget);
    final firstField = tester.widget<TextField>(find.byType(TextField).first);
    expect(firstField.controller!.text, '33.34');

    // Tramo 1: acepta el monto precargado (parcial, no cierra el saldo).
    await tester.ensureVisible(find.textContaining('Agregar'));
    await tester.tap(find.textContaining('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('Dividido entre 3 — parte 2 de 3'), findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '33.33');

    // Tramo 2: igual, parcial.
    await tester.ensureVisible(find.textContaining('Agregar'));
    await tester.tap(find.textContaining('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('Dividido entre 3 — parte 3 de 3'), findsOneWidget);

    // Tramo 3 (último): cierra el saldo con el "Cobrar resto".
    await tester.ensureVisible(find.textContaining('Cobrar resto'));
    await tester.tap(find.textContaining('Cobrar resto'));
    await tester.pumpAndSettle();

    expect(captured, hasLength(3));
    final sum = captured!.fold(0.0, (a, d) => a + d.amountTendered);
    expect(sum, closeTo(100, 0.001));
  });
}
