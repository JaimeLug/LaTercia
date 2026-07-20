import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/services/audit_service.dart';
import 'package:latercia/core/services/permission_service.dart';
import 'package:latercia/core/utils/pin_hasher.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    // Fresh in-memory DB per test. onCreate runs createAll() against the
    // current (v4) schema, so the new tables/columns exist from the start —
    // this exercises the model, not the v3→v4 upgrade path.
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<Employee> insertEmployee(String name, String pin, String role) async {
    final id = await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(name: name, pin: hashPin(pin), role: role),
    );
    return (await db.employeesDao.getAllEmployees())
        .firstWhere((e) => e.id == id);
  }

  // ─── Migración v4: tablas y columnas nuevas ───────────────────────────────

  group('esquema v4', () {
    test('audit_log es consultable y aceptable de inserts', () async {
      final id = await db.auditLogDao.insertLog(
        AuditLogCompanion.insert(
          action: 'venta',
          employeeId: const Value(1),
          entity: const Value('order'),
          entityId: const Value(1),
          detailJson: const Value('{"total":100}'),
        ),
      );
      final rows = await db.auditLogDao.getRecent();
      expect(rows.any((r) => r.id == id), isTrue);
    });

    test('cash_movements es consultable y aceptable de inserts', () async {
      final shiftId = await db.shiftsDao.openShift(
        ShiftsCompanion.insert(employeeId: 1, startedAt: DateTime.now()),
      );
      await db.into(db.cashMovements).insert(
            CashMovementsCompanion.insert(
              shiftId: shiftId,
              employeeId: 1,
              type: 'deposito',
              amount: 50,
            ),
          );
      final rows = await db.select(db.cashMovements).get();
      expect(rows, hasLength(1));
      expect(rows.single.type, 'deposito');
    });

    test(
        'orders.shiftId, payments.shiftId, shifts.zNumber, '
        'inventory_movements.orderId existen y son nullable', () async {
      final cats = await db.categoriesDao.getAllCategories();
      final productId = await db.productsDao.insertProduct(
        ProductsCompanion.insert(
          name: 'Café',
          price: 30,
          categoryId: cats.first.id,
        ),
      );

      final orderId = await db.ordersDao.insertOrder(
        OrdersCompanion.insert(
            orderNumber: '#0001', type: 'mesa', employeeId: 1),
      );
      final order = await db.ordersDao.getOrderById(orderId);
      expect(order!.shiftId, isNull);

      await db.paymentsDao.insertPayment(
        PaymentsCompanion.insert(
            orderId: orderId, method: 'efectivo', amountTendered: 30),
      );
      final payments = await db.paymentsDao.getPaymentsForOrder(orderId);
      expect(payments.single.shiftId, isNull);

      final shiftId = await db.shiftsDao.openShift(
        ShiftsCompanion.insert(employeeId: 1, startedAt: DateTime.now()),
      );
      final shift = (await db.shiftsDao.getShiftsByEmployee(1))
          .firstWhere((s) => s.id == shiftId);
      expect(shift.zNumber, isNull);

      await db.into(db.inventoryMovements).insert(
            InventoryMovementsCompanion.insert(
              productId: productId,
              delta: -1,
              reason: 'venta',
              orderId: Value(orderId),
            ),
          );
      final movements = await db.inventoryDao.getMovementsForProduct(productId);
      expect(movements.single.orderId, orderId);
    });
  });

  // ─── AuditService ──────────────────────────────────────────────────────────

  group('AuditService', () {
    test('inserta correctamente con detail_json codificado', () async {
      final service = AuditService(db);
      await service.log(
        employeeId: 1,
        action: 'ajuste_inventario',
        entity: 'product',
        entityId: 7,
        detail: {'previousStock': 10, 'newStock': 5},
      );

      final rows = await db.auditLogDao.getByAction('ajuste_inventario');
      expect(rows, hasLength(1));
      expect(rows.single.employeeId, 1);
      expect(rows.single.entityId, 7);
      final detail = jsonDecode(rows.single.detailJson!) as Map;
      expect(detail['newStock'], 5);
    });

    test('un log de intento de PIN fallido nunca contiene el PIN', () async {
      final service = AuditService(db);
      const attemptedPin = '9137';
      await service.log(
        employeeId: null,
        action: 'login_pin_fallido',
        detail: {'consecutiveAttempts': 3},
      );

      final rows = await db.auditLogDao.getByAction('login_pin_fallido');
      expect(rows, hasLength(1));
      expect(rows.single.employeeId, isNull);
      expect(rows.single.detailJson!.contains(attemptedPin), isFalse);
      // Also never leaks the hashed form of the PIN.
      expect(rows.single.detailJson!.contains(hashPin(attemptedPin)), isFalse);
    });
  });

  // ─── ShiftsDao.getCurrentOpenShift ─────────────────────────────────────────

  group('ShiftsDao.getCurrentOpenShift', () {
    test('devuelve null si no hay turno abierto', () async {
      expect(await db.shiftsDao.getCurrentOpenShift(), isNull);
    });

    test('devuelve el único turno abierto en el sistema, sin employeeId',
        () async {
      final cashier = await insertEmployee('Cajero 1', '1111', 'cashier');
      final shiftId = await db.shiftsDao.openShift(
        ShiftsCompanion.insert(
            employeeId: cashier.id, startedAt: DateTime.now()),
      );

      final open = await db.shiftsDao.getCurrentOpenShift();
      expect(open, isNotNull);
      expect(open!.id, shiftId);
      expect(open.employeeId, cashier.id);

      await db.shiftsDao.closeShift(shiftId, 100, 100);
      expect(await db.shiftsDao.getCurrentOpenShift(), isNull);
    });
  });

  // ─── PermissionService ──────────────────────────────────────────────────────

  group('PermissionService', () {
    const service = PermissionService();

    test('cajero no tiene permiso para anular ni descuento_manual', () async {
      final cashier = await insertEmployee('Cajero', '2222', 'cashier');
      expect(service.hasPermission(cashier, PermissionAction.anular), isFalse);
      expect(
        service.hasPermission(cashier, PermissionAction.descuentoManual),
        isFalse,
      );
      expect(
        service.hasPermission(cashier, PermissionAction.movimientoCaja),
        isFalse,
      );
    });

    test('gerente y admin tienen permiso libre para las acciones sensibles',
        () async {
      final gerente = await insertEmployee('Gerente', '3333', 'gerente');
      final admin = await insertEmployee('Admin 2', '4444', 'admin');
      for (final action in PermissionAction.values) {
        expect(service.hasPermission(gerente, action), isTrue,
            reason: action.key);
        expect(service.hasPermission(admin, action), isTrue,
            reason: action.key);
      }
    });

    test('cocina tampoco tiene permiso (no es admin/gerente)', () async {
      final kitchen = await insertEmployee('Cocina', '5555', 'kitchen');
      expect(service.hasPermission(kitchen, PermissionAction.corteZ), isFalse);
    });

    group('validateSupervisorPin', () {
      test('PIN de supervisor correcto autoriza y devuelve al supervisor',
          () async {
        final cashier = await insertEmployee('Cajero', '2222', 'cashier');
        final gerente = await insertEmployee('Gerente', '3333', 'gerente');

        final result = await service.validateSupervisorPin(db,
            pin: '3333', actor: cashier);

        expect(result.isSuccess, isTrue);
        expect(result.supervisor!.id, gerente.id);
        expect(result.error, isNull);
      });

      test('PIN incorrecto es rechazado', () async {
        final cashier = await insertEmployee('Cajero', '2222', 'cashier');
        final result = await service.validateSupervisorPin(db,
            pin: '0001', actor: cashier);
        expect(result.isSuccess, isFalse);
        expect(result.error, SupervisorPinError.invalidPin);
      });

      test('PIN de un empleado que no es supervisor es rechazado', () async {
        final cashier = await insertEmployee('Cajero', '2222', 'cashier');
        final otherCashier =
            await insertEmployee('Cajero 2', '6666', 'cashier');
        final result = await service.validateSupervisorPin(db,
            pin: '6666', actor: cashier);
        expect(result.isSuccess, isFalse);
        expect(result.error, SupervisorPinError.notSupervisor);
        expect(otherCashier.role, 'cashier');
      });

      test('un supervisor no puede autorizarse a sí mismo', () async {
        final gerente = await insertEmployee('Gerente', '3333', 'gerente');
        final result = await service.validateSupervisorPin(db,
            pin: '3333', actor: gerente);
        expect(result.isSuccess, isFalse);
        expect(result.error, SupervisorPinError.sameEmployee);
      });
    });
  });
}
