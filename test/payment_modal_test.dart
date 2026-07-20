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
    await tester.tap(find.textContaining('Agregar'));
    await tester.pumpAndSettle();

    // Tramo 2: efectivo cubre el resto (40) con 50 recibido → cambio 10.
    await tester.enterText(find.byType(TextField).first, '50');
    await tester.pumpAndSettle();
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
}
