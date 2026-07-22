import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../models/order_with_items.dart';
import '../providers/database_provider.dart';
import '../utils/formatters.dart';
import 'audit_service.dart';

/// Un pago (parcial o total) que compone el cobro de una orden; para pagos
/// mixtos el modal produce varios. `docs/ventas-cobro-turnos.md` §Pagos.
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

/// Crea y cobra una orden como una sola operación atómica (una transacción).
/// `docs/ventas-cobro-turnos.md` §"Cobro atómico".
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

  /// Defensa en profundidad: los pagos deben cubrir el total. Compara en
  /// **centavos enteros** — una tolerancia fija en doubles (la que había
  /// antes, 0.001) no basta contra un total crudo de combo prorrateado
  /// (ej. $35.594 sin redondear): se ve idéntico a "35.59" en 2 decimales
  /// pero es varias milésimas más alto que lo ya cobrado, y el pago
  /// rechazaba con "no cubren el total" aunque en pantalla mostraran el
  /// mismo número. Mismo criterio que `_reachesCents` en
  /// `payment_modal.dart`. `docs/ventas-cobro-turnos.md` §Pagos,
  /// `docs/division-cuenta.md`.
  void _assertCovers(List<PaymentDraft> drafts, double total) {
    final applied =
        drafts.fold(0.0, (a, d) => a + d.amountTendered - d.changeGiven);
    final appliedCents = (applied * 100).round();
    final totalCents = (total * 100).round();
    if (appliedCents < totalCents) {
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
    // Ticket de delivery (2026-07-20): solo relevantes cuando type ==
    // 'delivery'; nulos para mesa/para llevar.
    String? customerPhone,
    String? customerAddress,
    String? note,
    double subtotal = 0,
    double discountAmount = 0,
    double taxAmount = 0,
    String? deliveryZone,
    double deliveryFee = 0,
    double total = 0,
    String? paymentMethod,
    double? amountTendered,
    double changeGiven = 0,
    double tipAmount = 0,
    String? reference,
    List<PaymentDraft>? payments,
    // Fidelización: si esta venta consume la recompensa de sellos y/o de
    // puntos ganada del cliente — independientes entre sí, ambas pueden
    // canjearse a la vez. Solo aplica en este cobro inmediato — no en "pagar
    // después". docs/fidelizacion.md.
    bool redeemStamps = false,
    bool redeemPoints = false,
  }) {
    final drafts = _resolvePayments(payments, paymentMethod, amountTendered,
        changeGiven, tipAmount, reference);
    return _db.transaction(() async {
      _assertCovers(drafts, total);
      // Placeholder temporal → número legible derivado del id (evita la carrera
      // max(id)+1 entre POS y KDS). docs/ventas-cobro-turnos.md.
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
          customerPhone: Value(customerPhone),
          customerAddress: Value(customerAddress),
          note: Value(note),
          subtotal: Value(subtotal),
          discountAmount: Value(discountAmount),
          taxAmount: Value(taxAmount),
          deliveryZone: Value(deliveryZone),
          deliveryFee: Value(deliveryFee),
          total: Value(total),
          status: const Value('pendiente'),
          paymentStatus: const Value('pendiente'),
        ),
      );
      await _db.ordersDao
          .updateOrderNumber(orderId, formatOrderNumber(orderId));

      if (tableId != null) {
        await _db.tablesDao.updateTableStatus(tableId, 'occupied');
      }

      final itemCompanions = cartItems.map((ci) {
        final modJson = jsonEncode(
          ci.modifiers
              .map((m) => {
                    'name': m.name,
                    'priceDelta': m.priceDelta,
                    'included': ci.includedModifierIds.contains(m.id),
                  })
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
          comboInstanceId: Value(ci.comboInstanceId),
          comboName: Value(ci.comboName),
        );
      }).toList();
      await _db.orderItemsDao.insertOrderItems(itemCompanions);

      for (final ci in cartItems) {
        await _db.inventoryDao
            .decrementForSale(ci.product.id, ci.quantity, orderId: orderId);
      }

      // Un renglón de pago por tramo (pago mixto).
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

      // Pagar no entrega la orden por sí solo. docs/ventas-cobro-turnos.md.
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
        await _db.customersDao.earnLoyalty(
          customerId,
          [
            for (final ci in cartItems)
              (productId: ci.product.id, quantity: ci.quantity)
          ],
        );
        if (redeemStamps || redeemPoints) {
          await _db.customersDao.redeemLoyalty(
            customerId,
            stamps: redeemStamps,
            points: redeemPoints,
          );
        }
      }

      // Auditoría dentro de la misma transacción que la venta.
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

  /// Cobra una orden ya creada y enviada a cocina sin pagar (flujo de mesa
  /// "pagar al final"). No recrea orden/items/inventario.
  /// `docs/ventas-cobro-turnos.md` §"Cobro atómico".
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
    final drafts = _resolvePayments(payments, paymentMethod, amountTendered,
        changeGiven, tipAmount, reference);
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

      // Atribuye la orden al turno que la cobra si aún no tenía (para que el
      // corte Z cuente su venta).
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

      // Pagar no entrega la orden por sí solo. docs/ventas-cobro-turnos.md.
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
