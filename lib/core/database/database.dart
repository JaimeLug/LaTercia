import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
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
import 'daos/combos_dao.dart';
import 'daos/expenses_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/reports_dao.dart';
import 'daos/audit_log_dao.dart';
import 'daos/cash_movements_dao.dart';
import 'daos/refunds_dao.dart';
import 'daos/ingredients_dao.dart';
import 'daos/suppliers_dao.dart';
import 'daos/purchases_dao.dart';
import 'daos/recipes_dao.dart';
import 'daos/delivery_zones_dao.dart';

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
  BoolColumn get trackInventory =>
      boolean().withDefault(const Constant(false))();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(5))();
  // FASE 4.5 — Impuesto por producto. Ambas nullable: null = heredar el default
  // global (`tax_rate` / `tax_included` en Settings). Un valor explícito manda.
  RealColumn get taxRate => real().nullable()();
  BoolColumn get taxIncluded => boolean().nullable()();
  // FASE 7 — Insumos y recetas. Si es true, el producto se descuenta por
  // receta ([RecipeItems]) en vez de por trackInventory/stockQuantity — las
  // dos formas de rastrear stock son mutuamente excluyentes por producto.
  BoolColumn get usesRecipe => boolean().withDefault(const Constant(false))();
  // Facturación (CFDI 4.0): se llenan una vez por producto. docs/facturacion.md.
  TextColumn get claveProdServ => text().nullable()(); // c_ClaveProdServ
  TextColumn get claveUnidad => text().nullable()(); // c_ClaveUnidad
  TextColumn get objetoImp => text().nullable()(); // c_ObjetoImp (01/02/03)
  // Fidelización por puntos (v15): puntos que este producto otorga por unidad
  // vendida. docs/fidelizacion.md.
  IntColumn get loyaltyPointsValue =>
      integer().withDefault(const Constant(0))();
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
  // Promociones programadas (v13): ventana de día/hora (happy hour) y alcance
  // por producto (no por categoría — Jaime prefiere "2x1" sobre productos
  // específicos, no categorías enteras; feedback de sitio 2026-07-22).
  // `type` ahora también acepta '2x1'. docs/promociones.md.
  TextColumn get daysOfWeek => text().nullable()(); // CSV 1=lun..7=dom
  TextColumn get startTime => text().nullable()(); // "HH:mm"
  TextColumn get endTime => text().nullable()(); // "HH:mm"
  TextColumn get productScope => text().nullable()(); // CSV nombres de producto
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Paquetes de productos a precio especial (v14). Se EXPANDEN a sus productos
/// reales al agregarse al carrito — no son un concepto nuevo en la orden.
/// docs/combos.md.
class Combos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get price => real()(); // precio fijo del paquete
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Componentes de un combo: qué producto y cuántas unidades. docs/combos.md.
class ComboItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get comboId => integer().references(Combos, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
}

class TablesLayout extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get capacity => integer().withDefault(const Constant(4))();
  TextColumn get status => text().withDefault(
      const Constant('available'))(); // 'available' | 'occupied' | 'reserved'
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
  // Datos fiscales (opcionales; solo si el cliente pide factura).
  // docs/facturacion.md.
  TextColumn get rfc => text().nullable()();
  TextColumn get razonSocial => text().nullable()();
  TextColumn get cpFiscal => text().nullable()();
  TextColumn get regimenFiscal => text().nullable()(); // c_RegimenFiscal
  TextColumn get usoCfdiPreferido => text().nullable()(); // c_UsoCFDI (def G03)
  // Fidelización (v15): contadores propios, distintos de `visits` (que es un
  // total histórico y nunca se resetea). docs/fidelizacion.md.
  IntColumn get loyaltyStamps => integer().withDefault(const Constant(0))();
  IntColumn get loyaltyPoints => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get pin => text().unique()();
  TextColumn get role =>
      text()(); // 'admin' | 'cashier' | 'kitchen' | 'gerente'
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
  // Soft delete (v11): un corte "eliminado" queda en la BD pero se oculta del
  // historial de cortes y de los reportes. docs/soft-delete.md.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderNumber => text().unique()();
  TextColumn get type => text()(); // 'mesa' | 'para_llevar' | 'delivery'
  IntColumn get tableId => integer().nullable().references(TablesLayout, #id)();
  TextColumn get customerName => text().nullable()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  // Datos de entrega para la comanda de DELIVERY (2026-07-20): el nombre ya
  // existía, pero faltaban teléfono y dirección — sin ellos no se podía
  // armar un ticket de reparto útil para el repartidor. Solo se capturan
  // cuando type == 'delivery'; nulos para mesa/para llevar.
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerAddress => text().nullable()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  IntColumn get shiftId => integer().nullable().references(Shifts, #id)();
  TextColumn get note => text().nullable()();
  TextColumn get status => text().withDefault(const Constant(
      'pendiente'))(); // 'pendiente'|'en_preparacion'|'listo'|'entregado'|'cancelado'
  TextColumn get paymentStatus => text().withDefault(
      const Constant('pendiente'))(); // 'pendiente'|'pagado'|'cancelado'
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  // FASE 8 — Envío por zona (solo aplica a type == 'delivery'). deliveryFee
  // ya está sumado dentro de [total] (mismo patrón que taxAmount); ambas
  // columnas existen para desglosar la línea en ticket/recibo.
  TextColumn get deliveryZone => text().nullable()();
  RealColumn get deliveryFee => real().withDefault(const Constant(0))();
  // Pago esperado del delivery (v12): método ('efectivo'|'transferencia') y, en
  // efectivo, con cuánto paga el cliente — para el cambio en la comanda de
  // reparto. Transferencia marca la orden pagada. docs/impresion.md §Reparto.
  TextColumn get deliveryPaymentMethod => text().nullable()();
  RealColumn get deliveryCashAmount => real().nullable()();
  TextColumn get cancelReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  // Soft delete (v11): una orden "eliminada" queda en la BD pero se oculta de
  // las listas, los reportes y los cortes. Distinto de 'cancelado' (que sí se
  // muestra). docs/soft-delete.md.
  DateTimeColumn get deletedAt => dateTime().nullable()();
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
  TextColumn get itemStatus => text()
      .withDefault(const Constant('pendiente'))(); // 'pendiente' | 'listo'
  // Combos (v14): agrupa las líneas de una misma compra de combo (Uuid, el
  // mismo combo pedido 2 veces en la orden usa dos ids distintos) + el nombre
  // denormalizado para el ticket. docs/combos.md.
  TextColumn get comboInstanceId => text().nullable()();
  TextColumn get comboName => text().nullable()();
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
  IntColumn get delta =>
      integer()(); // positive = increase, negative = decrease
  TextColumn get reason => text()(); // 'venta' | 'ajuste' | 'compra' | 'merma'
  TextColumn get note => text().nullable()();
  IntColumn get orderId => integer().nullable().references(Orders, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Bitácora append-only de acciones sensibles. Nunca escribir [Employees.pin]
/// en [detailJson]. `docs/permisos-y-auditoria.md`.
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

/// Reembolsos post-pago (contra-movimiento inmutable). [orderItemId] null =
/// reembolso total; con valor = de una línea. `docs/ventas-cobro-turnos.md`
/// §Reembolsos.
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

/// FASE 7 — Insumos y recetas (activable vía Settings `insumos_activo`).
/// Proveedores de insumos, para el ciclo de compras.
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get contactName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Materia prima (café, leche, vasos...). Stock y cantidades en `real` para
/// soportar unidades fraccionarias (g, ml). `unit` es texto libre elegido por
/// el usuario (sin conversión entre unidades — decisión de diseño).
class Ingredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  RealColumn get stockQuantity => real().withDefault(const Constant(0))();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  RealColumn get lastUnitCost => real().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Espejo de [InventoryMovements] pero para insumos — bitácora de cada
/// entrada/salida de stock (venta, ajuste, compra, merma, cancelación,
/// reembolso).
class IngredientMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get delta => real()(); // positivo = entrada, negativo = salida
  TextColumn get reason => text()();
  TextColumn get note => text().nullable()();
  IntColumn get orderId => integer().nullable().references(Orders, #id)();
  IntColumn get purchaseId =>
      integer().nullable().references(IngredientPurchases, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Cabecera de una compra a proveedor — repone stock de N insumos a la vez.
class IngredientPurchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get supplierId => integer().nullable().references(Suppliers, #id)();
  IntColumn get employeeId => integer().references(Employees, #id)();
  RealColumn get totalCost => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class IngredientPurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId => integer().references(IngredientPurchases, #id)();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real()();
}

/// Receta = las filas de esta tabla para un `productId` dado (sin tabla de
/// cabecera; relación 1 producto → N insumos).
class RecipeItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get quantity => real()();
}

/// FASE 8 — Zonas de envío (cargo fijo por zona en órdenes `delivery`).
class DeliveryZones extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get fee => real().withDefault(const Constant(0))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

/// Cabecera de un documento fiscal (prellenado CFDI 4.0), con el snapshot
/// congelado del receptor. `docs/facturacion.md`.
class FiscalDocs extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Null en la factura global consolidada; con valor en la individual.
  IntColumn get orderId => integer().nullable().references(Orders, #id)();
  // Receptor congelado al emitir el documento (no se lee del cliente al exportar).
  TextColumn get receptorRfc => text().nullable()();
  TextColumn get receptorRazonSocial => text().nullable()();
  TextColumn get receptorCpFiscal => text().nullable()();
  TextColumn get receptorRegimen => text().nullable()();
  TextColumn get receptorUsoCfdi => text().nullable()();
  TextColumn get tipo => text()(); // 'individual' | 'global'
  TextColumn get estado => text()
      .withDefault(const Constant('pendiente'))(); // 'pendiente'|'exportada'
  TextColumn get periodoRef =>
      text().nullable()(); // global: día/semana/mes+año
  DateTimeColumn get exportedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Conceptos congelados de un [FiscalDocs] (snapshot inmutable con el IVA ya
/// desglosado base/impuesto). `docs/facturacion.md`.
class FiscalDocItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fiscalDocId => integer().references(FiscalDocs, #id)();
  TextColumn get claveProdServ => text().nullable()();
  TextColumn get claveUnidad => text().nullable()();
  TextColumn get descripcion => text()();
  RealColumn get cantidad => real()();
  RealColumn get valorUnitario => real()(); // sin IVA
  RealColumn get importe => real()(); // sin IVA (cantidad × valorUnitario)
  RealColumn get descuento => real().withDefault(const Constant(0))();
  TextColumn get objetoImp => text().nullable()();
  RealColumn get base => real()(); // base gravable (importe − descuento)
  RealColumn get tasaIva => real().withDefault(const Constant(0))(); // ej. 0.16
  RealColumn get importeIva => real().withDefault(const Constant(0))();
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
  Suppliers,
  Ingredients,
  IngredientMovements,
  IngredientPurchases,
  IngredientPurchaseItems,
  RecipeItems,
  DeliveryZones,
  FiscalDocs,
  FiscalDocItems,
  Combos,
  ComboItems,
])

/// Base de datos SQLite (Drift). `docs/base-de-datos.md`.
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Base sobre un executor explícito — para tests con SQLite en memoria.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // A1: fuerza foreign_keys en cada apertura (incl. tests).
        // docs/base-de-datos.md §"Integridad referencial".
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (Migrator m) async {
          await m.createAll();
          await SeederService(this).seedIfNeeded();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v2: PINs ahora hasheados. Re-hashea los PINs en claro de instala-
          // ciones existentes para que el login siga funcionando.
          if (from < 2) {
            final existing = await select(employees).get();
            for (final e in existing) {
              await (update(employees)..where((t) => t.id.equals(e.id)))
                  .write(EmployeesCompanion(pin: Value(hashPin(e.pin))));
            }
          }
          if (from < 3) {
            // Rediseño: aplica los nuevos defaults de marca donde no se hayan
            // cambiado.
            await SeederService(this).syncBrandDefaults();
          }
          if (from < 4) {
            // v4: bitácora de auditoría, movimientos de caja y las columnas de
            // enlace (turno/orden/pago/movimiento) que necesitan.
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
            // v6: al forzar foreign_keys, detecta filas huérfanas viejas y las
            // deja en el log (no bloquea). docs/base-de-datos.md §Migraciones.
            try {
              final violations =
                  await customSelect('PRAGMA foreign_key_check').get();
              if (violations.isNotEmpty) {
                appLogger.warn(
                    'foreign_key_check encontró ${violations.length} filas '
                    'huérfanas al activar FKs (v6). Revisar integridad.');
              }
            } catch (e, st) {
              appLogger.warn(
                  'No se pudo correr foreign_key_check en v6.', e, st);
            }
          }
          if (from < 7) {
            // FASE 7: insumos y recetas (activable, default OFF).
            await m.createTable(suppliers);
            await m.createTable(ingredients);
            await m.createTable(ingredientMovements);
            await m.createTable(ingredientPurchases);
            await m.createTable(ingredientPurchaseItems);
            await m.createTable(recipeItems);
            await m.addColumn(products, products.usesRecipe);
            await settingsDao.setValue('insumos_activo', 'false');
          }
          if (from < 8) {
            // FASE 8: envío por zona.
            await m.createTable(deliveryZones);
            await m.addColumn(orders, orders.deliveryZone);
            await m.addColumn(orders, orders.deliveryFee);
          }
          if (from < 9) {
            // Ticket de delivery (2026-07-20): datos del cliente para armar
            // la comanda de reparto (nombre ya existía desde antes).
            await m.addColumn(orders, orders.customerPhone);
            await m.addColumn(orders, orders.customerAddress);
          }
          if (from < 10) {
            // v10: facturación (prellenado CFDI 4.0). docs/facturacion.md.
            await m.addColumn(products, products.claveProdServ);
            await m.addColumn(products, products.claveUnidad);
            await m.addColumn(products, products.objetoImp);
            await m.addColumn(customers, customers.rfc);
            await m.addColumn(customers, customers.razonSocial);
            await m.addColumn(customers, customers.cpFiscal);
            await m.addColumn(customers, customers.regimenFiscal);
            await m.addColumn(customers, customers.usoCfdiPreferido);
            await m.createTable(fiscalDocs);
            await m.createTable(fiscalDocItems);
          }
          if (from < 11) {
            // v11: soft delete de órdenes y cortes. docs/soft-delete.md.
            await m.addColumn(orders, orders.deletedAt);
            await m.addColumn(shifts, shifts.deletedAt);
          }
          if (from < 12) {
            // v12: pago esperado del delivery (método + con cuánto paga).
            // docs/impresion.md §"Comanda de reparto".
            await m.addColumn(orders, orders.deliveryPaymentMethod);
            await m.addColumn(orders, orders.deliveryCashAmount);
          }
          if (from < 13) {
            // v13: promociones programadas (día/hora + 2x1). El alcance
            // (`productScope`) NO se agrega aquí — se movió a v16 para no
            // duplicar la columna en instalaciones que ya habían corrido
            // esta migración con el nombre viejo `categoryScope` (ver v16).
            // docs/promociones.md.
            await m.addColumn(discounts, discounts.daysOfWeek);
            await m.addColumn(discounts, discounts.startTime);
            await m.addColumn(discounts, discounts.endTime);
          }
          if (from < 14) {
            // v14: combos/paquetes. docs/combos.md.
            await m.createTable(combos);
            await m.createTable(comboItems);
            await m.addColumn(orderItems, orderItems.comboInstanceId);
            await m.addColumn(orderItems, orderItems.comboName);
          }
          if (from < 15) {
            // v15: fidelización (sellos/puntos). `loyaltyPointsValue` de
            // Products NO se agrega aquí — se movió a v16 (mismo motivo que
            // el alcance de arriba). docs/fidelizacion.md.
            await m.addColumn(customers, customers.loyaltyStamps);
            await m.addColumn(customers, customers.loyaltyPoints);
          }
          if (from < 16) {
            // v16: rediseño de Promociones/Fidelización tras feedback de VM
            // (2026-07-22) — alcance por producto en vez de categoría, y
            // puntos por producto. Migración NUEVA (no reusa v13/v15) porque
            // esas dos YA se habían aplicado en la VM con el diseño viejo
            // (`categoryScope`, sin `loyaltyPointsValue`); si esto se
            // hubiera metido de vuelta en v13/v15, una base ya migrada a
            // v15 se habría quedado sin `schemaVersion` nuevo que disparara
            // la migración, y una base fresca habría intentado agregar la
            // columna dos veces. La columna vieja `category_scope` de
            // Discounts queda huérfana en las bases que ya la tenían — no
            // estorba (Drift no la referencia) y no vale la pena migrarle el
            // dato: significaba "categoría", no "producto", así que
            // copiarlo tal cual daría un alcance que no matchea nada; mejor
            // que el cajero/dueño lo vuelva a configurar por producto.
            //
            // Defensivo (idempotente): antes de cada ALTER se checa si la
            // columna YA existe. La app corre multiproceso (POS+KDS sobre el
            // mismo archivo, docs/base-de-datos.md §"Acceso multiproceso") y
            // en sitio ya se vio DOS instancias abrir la base casi a la vez
            // (`flutter run` sin cerrar + el .exe recién compilado) — ambas
            // leen `user_version` ANTES de que la primera termine de
            // escribirlo, así que las dos intentan correr v16, y la segunda
            // revienta con "duplicate column name" al querer agregar una
            // columna que la primera ya agregó. Sin este checkeo, un choque
            // así deja la base sin terminar de abrir — ni el login carga.
            // docs/promociones.md, docs/fidelizacion.md.
            final discountCols =
                await customSelect('PRAGMA table_info(discounts)').get();
            if (!discountCols.any((r) => r.data['name'] == 'product_scope')) {
              await m.addColumn(discounts, discounts.productScope);
            }
            final productCols =
                await customSelect('PRAGMA table_info(products)').get();
            if (!productCols
                .any((r) => r.data['name'] == 'loyalty_points_value')) {
              await m.addColumn(products, products.loyaltyPointsValue);
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
  late final CombosDao combosDao = CombosDao(this);
  late final ExpensesDao expensesDao = ExpensesDao(this);
  late final InventoryDao inventoryDao = InventoryDao(this);
  late final SettingsDao settingsDao = SettingsDao(this);
  late final ReportsDao reportsDao = ReportsDao(this);
  late final AuditLogDao auditLogDao = AuditLogDao(this);
  late final CashMovementsDao cashMovementsDao = CashMovementsDao(this);
  late final RefundsDao refundsDao = RefundsDao(this);
  late final IngredientsDao ingredientsDao = IngredientsDao(this);
  late final SuppliersDao suppliersDao = SuppliersDao(this);
  late final PurchasesDao purchasesDao = PurchasesDao(this);
  late final RecipesDao recipesDao = RecipesDao(this);
  late final DeliveryZonesDao deliveryZonesDao = DeliveryZonesDao(this);
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'latercia',
    native: DriftNativeOptions(
      // A3: la base vive en la carpeta de soporte, NO en Documentos (donde
      // sí van los backups). docs/base-de-datos.md §Ubicación, docs/backups.md.
      databaseDirectory: getApplicationSupportDirectory,
      // WAL + busy_timeout para el acceso multiproceso POS/KDS al mismo archivo.
      // docs/base-de-datos.md §"Ubicación y acceso multiproceso".
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL;');
        db.execute('PRAGMA busy_timeout=5000;');
      },
    ),
  );
}
