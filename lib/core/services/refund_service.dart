import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import 'audit_service.dart';

/// Reembolsos post-pago: contra-movimiento inmutable en `refunds`, nunca edita
/// la venta original. `docs/ventas-cobro-turnos.md` §Reembolsos.
class RefundService {
  RefundService(this._db);

  final AppDatabase _db;

  Future<Refund> refund({
    required int orderId,
    int? orderItemId,
    required double amount,
    String? reason,
    required int employeeId,
    int? supervisorId,
    bool restock = false,
  }) {
    return _db.transaction(() async {
      final order = await _db.ordersDao.getOrderById(orderId);
      if (order == null) {
        throw StateError('La orden $orderId no existe.');
      }
      if (order.paymentStatus != 'pagado') {
        throw StateError(
            'Solo se puede reembolsar una orden pagada (esta está "${order.paymentStatus}").');
      }
      if (amount <= 0) {
        throw StateError('El monto a reembolsar debe ser mayor que 0.');
      }

      // Tope: no más de lo pagado menos lo ya reembolsado (validado aquí, no
      // solo en la UI, por ser dinero). docs/ventas-cobro-turnos.md §Reembolsos.
      final previous = await _db.refundsDao.getRefundsForOrder(orderId);
      final alreadyRefunded = previous.fold(0.0, (a, r) => a + r.amount);
      final refundable = order.total - alreadyRefunded;
      if (amount > refundable + 0.001) {
        throw StateError(
            'El reembolso ($amount) excede lo reembolsable (${refundable.toStringAsFixed(2)}).');
      }

      final openShift = await _db.shiftsDao.getCurrentOpenShift();

      // Devolución de stock opcional: de la línea indicada o de toda la orden.
      if (restock) {
        final items = await _db.orderItemsDao.getItemsForOrder(orderId);
        final toRestock = orderItemId != null
            ? items.where((i) => i.id == orderItemId)
            : items.where((i) => i.itemStatus != 'cancelado');
        for (final i in toRestock) {
          await _db.inventoryDao.incrementForSale(
              i.productId, i.quantity, 'reembolso',
              orderId: orderId);
        }
      }

      final id = await _db.refundsDao.insertRefund(
        RefundsCompanion.insert(
          orderId: orderId,
          orderItemId: Value(orderItemId),
          shiftId: Value(openShift?.id),
          amount: amount,
          reason: Value(reason),
          restocked: Value(restock),
          employeeId: employeeId,
          supervisorId: Value(supervisorId),
        ),
      );

      await AuditService(_db).log(
        employeeId: employeeId,
        action: 'reembolso',
        entity: 'order',
        entityId: orderId,
        detail: {
          'amount': amount,
          if (orderItemId != null) 'orderItemId': orderItemId,
          'restock': restock,
          if (supervisorId != null) 'supervisor': supervisorId,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );

      final refunds = await _db.refundsDao.getRefundsForOrder(orderId);
      return refunds.firstWhere((r) => r.id == id);
    });
  }
}

final refundServiceProvider = Provider<RefundService>((ref) {
  return RefundService(ref.watch(databaseProvider));
});
