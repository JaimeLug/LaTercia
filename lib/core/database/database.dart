import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../utils/app_logger.dart';
import '../utils/pin_hasher.dart';
import 'seeder.dart';
import 'daos/products_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/modifiers_dao.dart';
import 'daos/orders_dao.dart';
import 'daos/order_items_dao.dart';
import 'daos/payments_dao.dart';
import 'daos/tables_dao.dart';
import 'daos/customers_dao.dart';
import 'daos/employees_dao.dart';
import 'daos/shifts_dao.dart';
import 'daos/discounts_dao.dart';
import 'daos/expenses_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/reports_dao.dart';
import 'daos/audit_log_dao.dart';
import 'daos/cash_movements_dao.dart';
import 'daos/refunds_dao.dart';

part 'database.g.dart';

// ─── Table definitions ───────────────────────────────────────────────────────

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  @override
  Set<Column> get primaryKey => {key};
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  TextColumn get icon => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  RealColumn get cost => real().withDefault(const Constant(0))();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get sku => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get available => boolean().withDefault(const Constant(true))();
  BoolColumn get trackInventory => boolean().withDefault(const Constant(false))();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(5))();
  // FASE 4.5 — Impuesto por producto. Ambas nullable: null = heredar el default
  // global (`tax_rate` / `tax_included` en Settings). Un valor explícito manda.
  RealColumn get taxRate => real().nullable()();
  BoolColumn get taxIncluded => boolean().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Modifiers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get priceDelta => real().withDefault(const Constant(0))();
  TextColumn get categoryScope => text().nullable()();
}

class Discounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'percentage' | 'fixed'
  RealColumn get value => real()();
  RealColumn get minOrderAmount => real().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get validFrom => dateTime().nullable()();
  DateTimeColumn get validUntil => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TablesLayout extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get capacity => integer().withDefault(const Constant(4))();
  TextColumn get status =>
      text().withDefault(const Constant('available'))(); // 'available' | 'occupied' | 'reserved'
  TextColumn get notes => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  IntColumn get visits => integer().withDefault(const Constant(0))();
  RealColumn get totalSpent => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get pin => text().unique()();
  TextColumn get role => text()(); // 'admin' | 'cashier' | 'kitchen' | 'gerente'
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get startingCash => real().withDefault(const Constant(0))();
  RealColumn get endingCash => real().nullable()();
  RealColumn get totalSales => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  IntColumn get zNumber => integer().nullable()();
}

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderNumber => text().unique()();
  TextColumn get type => text()(); // 'mesa' | 'para_llevar' | 'delivery'
  IntColumn get tableId => integer().nullable().references(TablesLayout, #id)();
  TextColumn get customerName => text().nullable()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  IntColumn get employeeId => integer().references(Employees, #id)();
  IntColumn get shiftId => integer().nullable().references(Shifts, #id)();
  TextColumn get note => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('pendiente'))(); // 'pendiente'|'en_preparacion'|'listo'|'entregado'|'cancelado'
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('pendiente'))(); // 'pendiente'|'pagado'|'cancelado'
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  TextColumn get cancelReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  TextColumn get modifiersJson => text().nullable()();
  TextColumn get itemNote => text().nullable()();
  TextColumn get itemStatus =>
      text().withDefault(const Constant('pendiente'))(); // 'pendiente' | 'listo'
}

class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get shiftId => integer().nullable().references(Shifts, #id)();
  TextColumn get method =>
      text()(); // 'efectivo' | 'tarjeta' | 'transferencia' | 'otro'
  RealColumn get amountTendered => real()();
  RealColumn get changeGiven => real().withDefault(const Constant(0))();
  TextColumn get reference => text().nullable()();
  // FASE 4.1 — Propina asociada a este pago. No afecta el total de la venta
  // (línea separada); se agrega por pago para soportar propina en pagos mixtos.
  RealColumn get tipAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category =>
      text()(); // 'Insumos'|'Renta'|'Servicios'|'Personal'|'Otro'
  TextColumn get description => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  IntColumn get createdById =>
      integer().nullable().references(Employees, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class InventoryMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get delta => integer()(); // positive = increase, negative = decrease
  TextColumn get reason =>
      text()(); // 'venta' | 'ajuste' | 'compra' | 'merma'
  TextColumn get note => text().nullable()();
  IntColumn get orderId => integer().nullable().references(Orders, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Append-only trail of sensitive actions (sales, cancellations, permission
/// overrides, settings changes, etc). Never write [Employees.pin] into
/// [detailJson] — see individual hook call sites for what each action logs.
class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get ts => dateTime().withDefault(currentDateAndTime)();
  IntColumn get employeeId => integer().nullable().references(Employees, #id)();
  TextColumn get action => text()();
  TextColumn get entity => text().nullable()();
  IntColumn get entityId => integer().nullable()();
  TextColumn get detailJson => text().nullable()();
}

class CashMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shiftId => integer().references(Shifts, #id)();
  IntColumn get employeeId => integer().references(Employees, #id)();
  TextColumn get type => text()(); // 'deposito' | 'retiro'
  RealColumn get amount => real()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get ts => dateTime().withDefault(currentDateAndTime)();
}

/// FASE 4.4 — Reembolsos post-pago. Nunca editan la venta original: son un
/// contra-movimiento inmutable. [orderItemId] nullable = reembolso total de la
/// orden; con valor = reembolso de una línea. [supervisorId] es el empleado que
/// autorizó con su PIN (obligatorio; el reembolso siempre pasa por supervisor).
/// [shiftId] liga el reembolso al turno para que el corte Z lo reste.
class Refunds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get orderItemId =>
      integer().nullable().references(OrderItems, #id)();
  IntColumn get shiftId => integer().nullable().references(Shifts, #id)();
  RealColumn get amount => real()();
  TextColumn get reason => text().nullable()();
  BoolColumn get restocked => boolean().withDefault(const Constant(false))();
  @ReferenceName('refundsIssued')
  IntColumn get employeeId => integer().references(Employees, #id)();
  @ReferenceName('refundsAuthorized')
  IntColumn get supervisorId =>
      integer().nullable().references(Employees, #id)();
  DateTimeColumn get ts => dateTime().withDefault(currentDateAndTime)();
}

// ─── Database class ──────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Settings,
  Categories,
  Products,
  Modifiers,
  Discounts,
  TablesLayout,
  Customers,
  Employees,
  Shifts,
  Orders,
  OrderItems,
  Payments,
  Expenses,
  InventoryMovements,
  AuditLog,
  CashMovements,
  Refunds,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Builds a database on top of an explicit executor — used by tests to run
  /// against an in-memory SQLite instance (NativeDatabase.memory()).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // A1: integridad referencial forzada por la BD. Se activa por conexión,
        // fuera de transacción (requisito de SQLite), en cada apertura —incl.
        // los tests, que usan `forTesting` y no pasan por `_openConnection`.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (Migrator m) async {
          await m.createAll();
          await SeederService(this).seedIfNeeded();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v2: PINs are now stored hashed. Re-hash the plaintext PINs that
          // existing installs still have so logins keep working.
          if (from < 2) {
            final existing = await select(employees).get();
            for (final e in existing) {
              await (update(employees)..where((t) => t.id.equals(e.id)))
                  .write(EmployeesCompanion(pin: Value(hashPin(e.pin))));
            }
          }
          if (from < 3) {
            // Redesign: apply new brand defaults where still unchanged.
            await SeederService(this).syncBrandDefaults();
          }
          if (from < 4) {
            // FASE 2 parte A: audit trail, cash movements, and the shift /
            // order / payment / inventory-movement linking columns they need.
            await m.createTable(auditLog);
            await m.createTable(cashMovements);
            await m.addColumn(inventoryMovements, inventoryMovements.orderId);
            await m.addColumn(orders, orders.shiftId);
            await m.addColumn(payments, payments.shiftId);
            await m.addColumn(shifts, shifts.zNumber);
          }
          if (from < 5) {
            // FASE 4: impuesto por producto, propinas y reembolsos.
            await m.addColumn(products, products.taxRate);
            await m.addColumn(products, products.taxIncluded);
            await m.addColumn(payments, payments.tipAmount);
            await m.createTable(refunds);
            // El default global de "IVA incluido" para instalaciones nuevas se
            // siembra en el seeder; para las existentes lo agregamos aquí para
            // no cambiar el comportamiento de precios sin avisar.
            await settingsDao.setValue('tax_included', 'true');
          }
          if (from < 6) {
            // A1: al empezar a forzar foreign_keys, una instalación existente
            // podría tener filas huérfanas de antes (cuando no se validaban).
            // No podemos borrarlas a ciegas; las detectamos y las dejamos en el
            // log para revisión manual (red de seguridad, no bloquea el arranque).
            try {
              final violations =
                  await customSelect('PRAGMA foreign_key_check').get();
              if (violations.isNotEmpty) {
                appLogger.warn(
                    'foreign_key_check encontró ${violations.length} filas '
                    'huérfanas al activar FKs (v6). Revisar integridad.');
              }
            } catch (e, st) {
              appLogger.warn('No se pudo correr foreign_key_check en v6.', e, st);
            }
          }
        },
      );

  // DAO accessors
  late final ProductsDao productsDao = ProductsDao(this);
  late final CategoriesDao categoriesDao = CategoriesDao(this);
  late final ModifiersDao modifiersDao = ModifiersDao(this);
  late final OrdersDao ordersDao = OrdersDao(this);
  late final OrderItemsDao orderItemsDao = OrderItemsDao(this);
  late final PaymentsDao paymentsDao = PaymentsDao(this);
  late final TablesDao tablesDao = TablesDao(this);
  late final CustomersDao customersDao = CustomersDao(this);
  late final EmployeesDao employeesDao = EmployeesDao(this);
  late final ShiftsDao shiftsDao = ShiftsDao(this);
  late final DiscountsDao discountsDao = DiscountsDao(this);
  late final ExpensesDao expensesDao = ExpensesDao(this);
  late final InventoryDao inventoryDao = InventoryDao(this);
  late final SettingsDao settingsDao = SettingsDao(this);
  late final ReportsDao reportsDao = ReportsDao(this);
  late final AuditLogDao auditLogDao = AuditLogDao(this);
  late final CashMovementsDao cashMovementsDao = CashMovementsDao(this);
  late final RefundsDao refundsDao = RefundsDao(this);
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'latercia',
    native: DriftNativeOptions(
      // POS and KDS are two separate processes sharing the same SQLite file.
      // WAL lets readers and writers proceed concurrently instead of
      // blocking on a single writer lock, and busy_timeout makes SQLite
      // retry for up to 5s instead of throwing "database is locked"
      // immediately when the two processes do collide on a write.
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL;');
        db.execute('PRAGMA busy_timeout=5000;');
      },
    ),
  );
}
