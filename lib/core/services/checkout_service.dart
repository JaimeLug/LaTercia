import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../models/order_with_items.dart';
import '../providers/database_provider.dart';
import '../utils/formatters.dart';
import 'audit_service.dart';

/// Creates an order and charges it as a single atomic operation.
///
/// Before this existed, checking out was three separate write paths glued
/// together by the caller: `OrdersNotifier.sendToKitchen` created the order
/// (itself already transactional), then the UI inserted a payment row
/// directly via `paymentsDao`, then called `OrdersNotifier.markPaid`, then
/// (maybe) `customersDao.incrementVisits` — four independent commits. A
/// failure between any two of them could leave an order with no payment, a
/// payment on a half-built order, or inventory decremented for a sale that
/// was never actually charged.
///
/// [checkout] folds all of that into one `db.transaction`: if anything
/// throws partway through, drift rolls back everything — no order, no items,
/// no inventory movement, no payment, and no customer update survive.
/// Un pago (parcial o total) que compone el cobro de una orden. Para pagos
/// mixtos (4.2) el modal produce varios; para el cobro simple, uno solo.
///
/// [amountTendered]/[changeGiven] son lo entregado y el cambio (el cambio solo
/// aparece en el tramo en efectivo que cierra el saldo). [tipAmount] es la
/// propina asociada a este pago (4.1).
class PaymentDraft {
  final String method;
  final double amountTendered;
  final double changeGiven;
  final double tipAmount;
  final String? reference;

  const PaymentDraft({
    required this.method,
    required this.amountTendered,
    this.changeGiven = 0,
    this.tipAmount = 0,
    this.reference,
  });
}

class CheckoutService {
  CheckoutService(this._db);

  final AppDatabase _db;

  /// Resuelve la lista de pagos a insertar: la explícita [payments] (mixtos) o
  /// un único pago armado desde los parámetros legados.
  List<PaymentDraft> _resolvePayments(
    List<PaymentDraft>? payments,
    String? method,
    double? amountTendered,
    double changeGiven,
    double tipAmount,
    String? reference,
  ) {
    if (payments != null && payments.isNotEmpty) return payments;
    return [
      PaymentDraft(
        method: method!,
        amountTendered: amountTendered!,
        changeGiven: changeGiven,
        tipAmount: tipAmount,
        reference: reference,
      ),
    ];
  }

  /// Defensa en profundidad (M1): lo aplicado por los pagos (entregado − cambio)
  /// debe cubrir el total antes de marcar la orden pagada. La propina infla lo
  /// aplicado por encima del total, así que ≥ es correcto.
  void _assertCovers(List<PaymentDraft> drafts, double total) {
    final applied =
        drafts.fold(0.0, (a, d) => a + d.amountTendered - d.changeGiven);
    if (applied + 0.001 < total) {
      throw StateError(
          'Los pagos (${applied.toStringAsFixed(2)}) no cubren el total (${total.toStringAsFixed(2)}).');
    }
  }

  Future<OrderWithItems> checkout({
    required List<CartItem> cartItems,
    required String type,
    required int employeeId,
    int? tableId,
    String? customerName,
    int? customerId,
    String? note,
    double subtotal = 0,
    double discountAmount = 0,
    double taxAmount = 0,
    double total = 0,
    String? paymentMethod,
    double? amountTendered,
    double changeGiven = 0,
    double tipAmount = 0,
    String? reference,
    List<PaymentDraft>? payments,
  }) {
    final drafts = _resolvePayments(
        payments, paymentMethod, amountTendered, changeGiven, tipAmount, reference);
    return _db.transaction(() async {
      _assertCovers(drafts, total);
      // Insert with a temporary unique placeholder, then derive the real,
      // human-readable order number from the autoincrement id — mirrors
      // OrdersNotifier.sendToKitchen, see its docs for why (avoids a
      // max(id)+1 race between the POS and KDS processes).
      final tempNumber = 'tmp-${const Uuid().v4()}';
      final openShift = await _db.shiftsDao.getCurrentOpenShift();
      final orderId = await _db.ordersDao.insertOrder(
        OrdersCompanion.insert(
          orderNumber: tempNumber,
          type: type,
          employeeId: employeeId,
          shiftId: Value(openShift?.id),
          tableId: Value(tableId),
          customerName: Value(customerName),
          customerId: Value(customerId),
          note: Value(note),
          subtotal: Value(subtotal),
          discountAmount: Value(discountAmount),
          taxAmount: Value(taxAmount),
          total: Value(total),
          status: const Value('pendiente'),
          paymentStatus: const Value('pendiente'),
        ),
      );
      await _db.ordersDao.updateOrderNumber(orderId, formatOrderNumber(orderId));

      if (tableId != null) {
        await _db.tablesDao.updateTableStatus(tableId, 'occupied');
      }

      final itemCompanions = cartItems.map((ci) {
        final modJson = jsonEncode(
          ci.modifiers
              .map((m) => {'name': m.name, 'priceDelta': m.priceDelta})
              .toList(),
        );
        return OrderItemsCompanion.insert(
          orderId: orderId,
          productId: ci.product.id,
          productName: ci.product.name,
          quantity: ci.quantity,
          unitPrice: ci.unitPrice,
          modifiersJson: Value(ci.modifiers.isEmpty ? null : modJson),
          itemNote: Value(ci.note),
        );
      }).toList();
      await _db.orderItemsDao.insertOrderItems(itemCompanions);

      for (final ci in cartItems) {
        await _db.inventoryDao.decrementStock(ci.product.id, ci.quantity);
      }

      // Record the payment(s) — one row per tramo (pago mixto 4.2).
      for (final d in drafts) {
        await _db.paymentsDao.insertPayment(
          PaymentsCompanion.insert(
            orderId: orderId,
            shiftId: Value(openShift?.id),
            method: d.method,
            amountTendered: d.amountTendered,
            changeGiven: Value(d.changeGiven),
            tipAmount: Value(d.tipAmount),
            reference: Value(d.reference),
          ),
        );
      }

      // Mark it paid. Mirrors OrdersNotifier.markPaid: paying does not by
      // itself deliver the order (that would hide it from the kitchen) — it
      // only completes the order here if the kitchen had *already* marked it
      // ready before the cashier charged it, which can't happen for a
      // brand-new order but keeps this in lock-step with markPaid's
      // semantics for future callers.
      await _db.ordersDao.updateOrderPaymentStatus(orderId, 'pagado');
      var order = await _db.ordersDao.getOrderById(orderId);
      if (order != null && order.status == 'listo') {
        await _db.ordersDao.markDelivered(orderId);
        if (tableId != null) {
          await _db.tablesDao.updateTableStatus(tableId, 'available');
        }
        order = await _db.ordersDao.getOrderById(orderId);
      }

      if (customerId != null) {
        await _db.customersDao.incrementVisits(customerId, total);
      }

      // Logged inside the same transaction as the sale itself so the audit
      // trail is atomic with the checkout: if anything above rolls back,
      // this row never lands either.
      final tipTotal = drafts.fold(0.0, (a, d) => a + d.tipAmount);
      await AuditService(_db).log(
        employeeId: employeeId,
        action: 'venta',
        entity: 'order',
        entityId: orderId,
        detail: {
          'total': total,
          'method': drafts.length > 1 ? 'mixto' : drafts.first.method,
          if (drafts.length > 1)
            'methods': drafts.map((d) => d.method).toList(),
          if (tipTotal > 0) 'tip': tipTotal,
        },
      );

      final items = await _db.orderItemsDao.getItemsForOrder(orderId);
      return OrderWithItems(order: order!, items: items);
    });
  }

  /// Charges an order that was already created (and sent to the kitchen)
  /// without being paid — the "Enviar a Cocina" / pay-at-the-end mesa flow.
  ///
  /// Unlike [checkout], this does NOT create the order, its items, or the
  /// inventory movements (those already happened when the order was sent to
  /// the kitchen). It only records the payment against the current open shift
  /// and marks the order paid — mirroring `OrdersNotifier.markPaid`'s
  /// delivery/table semantics — all in one transaction so the payment and the
  /// paid-status flip either both land or neither does.
  ///
  /// The order's monetary amounts (subtotal/discount/tax/total) are already
  /// fixed from when it was built, so nothing is recomputed here; if the order
  /// carried a manual discount it already passed the supervisor gate at
  /// send-to-kitchen time.
  Future<OrderWithItems> chargeExistingOrder({
    required int orderId,
    required int employeeId,
    String? paymentMethod,
    double? amountTendered,
    double changeGiven = 0,
    double tipAmount = 0,
    String? reference,
    List<PaymentDraft>? payments,
  }) {
    final drafts = _resolvePayments(
        payments, paymentMethod, amountTendered, changeGiven, tipAmount, reference);
    return _db.transaction(() async {
      final existing = await _db.ordersDao.getOrderById(orderId);
      if (existing == null) {
        throw StateError('La orden $orderId no existe.');
      }
      if (existing.paymentStatus == 'pagado') {
        throw StateError('La orden ${existing.orderNumber} ya está pagada.');
      }
      if (existing.status == 'cancelado') {
        throw StateError(
            'La orden ${existing.orderNumber} está cancelada; no se puede cobrar.');
      }
      _assertCovers(drafts, existing.total);

      final openShift = await _db.shiftsDao.getCurrentOpenShift();

      // Atribuye la orden al turno que la cobra si aún no tenía turno (fue
      // creada con "Enviar a Cocina" antes de cobrar), para que el corte Z
      // cuente su venta.
      if (existing.shiftId == null && openShift != null) {
        await _db.ordersDao.updateOrderShift(orderId, openShift.id);
      }

      for (final d in drafts) {
        await _db.paymentsDao.insertPayment(
          PaymentsCompanion.insert(
            orderId: orderId,
            shiftId: Value(openShift?.id),
            method: d.method,
            amountTendered: d.amountTendered,
            changeGiven: Value(d.changeGiven),
            tipAmount: Value(d.tipAmount),
            reference: Value(d.reference),
          ),
        );
      }

      // Same rule as OrdersNotifier.markPaid: paying doesn't by itself deliver
      // the order (that would hide it from the kitchen). It's only delivered
      // here if the kitchen already marked it 'listo'; otherwise it stays
      // visible on the KDS until the kitchen finishes it.
      await _db.ordersDao.updateOrderPaymentStatus(orderId, 'pagado');
      var order = await _db.ordersDao.getOrderById(orderId);
      if (order != null && order.status == 'listo') {
        await _db.ordersDao.markDelivered(orderId);
        if (order.tableId != null) {
          await _db.tablesDao.updateTableStatus(order.tableId!, 'available');
        }
        order = await _db.ordersDao.getOrderById(orderId);
      }

      if (order!.customerId != null) {
        await _db.customersDao.incrementVisits(order.customerId!, order.total);
      }

      final tipTotal = drafts.fold(0.0, (a, d) => a + d.tipAmount);
      await AuditService(_db).log(
        employeeId: employeeId,
        action: 'venta',
        entity: 'order',
        entityId: orderId,
        detail: {
          'total': order.total,
          'method': drafts.length > 1 ? 'mixto' : drafts.first.method,
          if (drafts.length > 1)
            'methods': drafts.map((d) => d.method).toList(),
          'deferred': true,
          if (tipTotal > 0) 'tip': tipTotal,
        },
      );

      final items = await _db.orderItemsDao.getItemsForOrder(orderId);
      return OrderWithItems(order: order, items: items);
    });
  }
}

final checkoutServiceProvider = Provider<CheckoutService>((ref) {
  return CheckoutService(ref.watch(databaseProvider));
});
