import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/models/order_with_items.dart';
import 'package:latercia/core/providers/orders_provider.dart';
import 'package:latercia/core/database/daos/recipes_dao.dart';
import 'package:latercia/core/services/checkout_service.dart';
import 'package:latercia/core/services/refund_service.dart';
import 'package:latercia/core/services/shift_service.dart';

void main() {
  late AppDatabase db;
  late CheckoutService checkout;

  setUp(() async {
    // Fresh in-memory DB per test. onCreate runs the seeder, so the default
    // admin employee (id 1), tables (ids 1..6) and products already exist,
    // and the `orders` table starts empty.
    db = AppDatabase.forTesting(NativeDatabase.memory());
    checkout = CheckoutService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<Product> trackedProduct({int stock = 10}) async {
    final cats = await db.categoriesDao.getAllCategories();
    final id = await db.productsDao.insertProduct(
      ProductsCompanion.insert(
        name: 'Producto rastreado',
        price: 50,
        categoryId: cats.first.id,
        trackInventory: const Value(true),
        stockQuantity: Value(stock),
      ),
    );
    return (await db.productsDao.getAllProducts())
        .firstWhere((p) => p.id == id);
  }

  Future<int> stockOf(int productId) async =>
      (await db.productsDao.getAllProducts())
          .firstWhere((p) => p.id == productId)
          .stockQuantity;

  Future<Customer> anyCustomer() async {
    final id = await db.customersDao.insertCustomer(
      CustomersCompanion.insert(name: 'Cliente de prueba'),
    );
    return (await db.customersDao.getAllCustomers())
        .firstWhere((c) => c.id == id);
  }

  // ─── Happy path ────────────────────────────────────────────────────────

  test('camino feliz: orden + items + inventario + pago + visitas quedan '
      'consistentes tras una sola transacción', () async {
    final product = await trackedProduct(stock: 10);
    final customer = await anyCustomer();

    final result = await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 2)],
      type: 'mesa',
      employeeId: 1,
      tableId: 1,
      customerId: customer.id,
      subtotal: 100,
      total: 100,
      paymentMethod: 'efectivo',
      amountTendered: 100,
      changeGiven: 0,
    );

    expect(result.order.paymentStatus, 'pagado');
    expect(result.order.orderNumber.startsWith('tmp-'), isFalse);
    expect(result.items, hasLength(1));
    expect(result.items.first.quantity, 2);

    expect(await stockOf(product.id), 8, reason: 'inventario descontado');

    final payments = await db.paymentsDao.getPaymentsForOrder(result.order.id);
    expect(payments, hasLength(1));
    expect(payments.first.method, 'efectivo');
    expect(payments.first.amountTendered, 100);

    final table = (await db.tablesDao.getAllTables())
        .firstWhere((t) => t.id == 1);
    expect(table.status, 'occupied');

    final refreshedCustomer = (await db.customersDao.getAllCustomers())
        .firstWhere((c) => c.id == customer.id);
    expect(refreshedCustomer.visits, 1);
    expect(refreshedCustomer.totalSpent, 100);

    final activeOrders = await db.ordersDao.getActiveOrders();
    expect(activeOrders.any((o) => o.id == result.order.id), isTrue);
  });

  // ─── Envío por zona (FASE 8) ────────────────────────────────────────────

  test('el checkout persiste la zona y el cargo de envío en la orden',
      () async {
    final product = await trackedProduct(stock: 10);

    final result = await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 1)],
      type: 'delivery',
      employeeId: 1,
      subtotal: 50,
      deliveryZone: 'Progreso 2',
      deliveryFee: 25,
      total: 75,
      paymentMethod: 'efectivo',
      amountTendered: 75,
    );

    expect(result.order.deliveryZone, 'Progreso 2');
    expect(result.order.deliveryFee, 25);
    expect(result.order.total, 75, reason: 'el cargo ya viene sumado en total');
  });

  test('una orden sin envío (mesa/para llevar) queda con deliveryFee en 0',
      () async {
    final product = await trackedProduct(stock: 10);

    final result = await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 1)],
      type: 'mesa',
      employeeId: 1,
      tableId: 1,
      subtotal: 50,
      total: 50,
      paymentMethod: 'efectivo',
      amountTendered: 50,
    );

    expect(result.order.deliveryZone, isNull);
    expect(result.order.deliveryFee, 0);
  });

  // ─── Insumos y recetas (FASE 7) ────────────────────────────────────────

  test('con insumos_activo=true, un producto con receta descuenta el insumo '
      'en vez del stock simple del producto', () async {
    final cats = await db.categoriesDao.getAllCategories();
    final ingredientId = await db.ingredientsDao.insertIngredient(
      IngredientsCompanion.insert(name: 'Café molido', unit: 'g'),
    );
    await db.ingredientsDao.adjustStock(ingredientId, 1000, 'ajuste', null);
    final productId = await db.productsDao.insertProduct(
      ProductsCompanion.insert(
        name: 'Latte',
        price: 45,
        categoryId: cats.first.id,
        usesRecipe: const Value(true),
      ),
    );
    await db.recipesDao.setRecipe(
        productId, [RecipeLineDraft(ingredientId: ingredientId, quantity: 18)]);
    await db.settingsDao.setValue('insumos_activo', 'true');
    final product =
        (await db.productsDao.getAllProducts()).firstWhere((p) => p.id == productId);

    await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 2)],
      type: 'mesa',
      employeeId: 1,
      subtotal: 90,
      total: 90,
      paymentMethod: 'efectivo',
      amountTendered: 90,
    );

    final ingredient = (await db.ingredientsDao.getAllIngredients())
        .firstWhere((i) => i.id == ingredientId);
    expect(ingredient.stockQuantity, 1000 - 18 * 2);
  });

  test('con insumos_activo=false, un producto con receta cargada NO toca '
      'insumos (el flag manda, no solo si el producto tiene receta)', () async {
    final cats = await db.categoriesDao.getAllCategories();
    final ingredientId = await db.ingredientsDao.insertIngredient(
      IngredientsCompanion.insert(name: 'Café molido', unit: 'g'),
    );
    await db.ingredientsDao.adjustStock(ingredientId, 1000, 'ajuste', null);
    final productId = await db.productsDao.insertProduct(
      ProductsCompanion.insert(
        name: 'Latte',
        price: 45,
        categoryId: cats.first.id,
        usesRecipe: const Value(true),
      ),
    );
    await db.recipesDao.setRecipe(
        productId, [RecipeLineDraft(ingredientId: ingredientId, quantity: 18)]);
    await db.settingsDao.setValue('insumos_activo', 'false');
    final product =
        (await db.productsDao.getAllProducts()).firstWhere((p) => p.id == productId);

    await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 2)],
      type: 'mesa',
      employeeId: 1,
      subtotal: 90,
      total: 90,
      paymentMethod: 'efectivo',
      amountTendered: 90,
    );

    final ingredient = (await db.ingredientsDao.getAllIngredients())
        .firstWhere((i) => i.id == ingredientId);
    expect(ingredient.stockQuantity, 1000, reason: 'flag apagado — sin tocar insumos');
  });

  // ─── Atomicity ─────────────────────────────────────────────────────────

  test('un fallo a mitad del checkout revierte todo: sin orden, sin pago, '
      'sin inventario descontado, sin cliente actualizado', () async {
    final product = await trackedProduct(stock: 10);
    final customer = await anyCustomer();

    // Orders in a fresh test db start empty, so this decoy insert claims
    // id=1, which means checkout()'s own order (inserted next) will get
    // id=2 and try to assign itself orderNumber "#0002" once it derives the
    // human-readable number from its id. Pre-claiming "#0002" here for the
    // decoy makes that assignment collide with the `orderNumber` unique
    // constraint partway through the transaction (after the order, items
    // and inventory movement have already been written), forcing a full
    // rollback of the checkout.
    await db.ordersDao.insertOrder(
      OrdersCompanion.insert(
        orderNumber: '#0002',
        type: 'mesa',
        employeeId: 1,
      ),
    );

    await expectLater(
      checkout.checkout(
        cartItems: [CartItem(product: product, quantity: 3)],
        type: 'mesa',
        employeeId: 1,
        tableId: 2,
        customerId: customer.id,
        subtotal: 150,
        total: 150,
        paymentMethod: 'efectivo',
        amountTendered: 150,
        changeGiven: 0,
      ),
      throwsA(anything),
    );

    // Only the decoy order should exist — the real checkout must not have
    // left a second order behind.
    final allOrders = await db.ordersDao.getOrdersByDateRange(
      DateTime(2000),
      DateTime(2100),
    );
    expect(allOrders, hasLength(1));
    expect(allOrders.single.orderNumber, '#0002');

    // No order items, no payments, for the failed checkout's would-be order.
    final items = await db.orderItemsDao.getItemsForOrder(2);
    expect(items, isEmpty);
    final payments = await db.paymentsDao.getPaymentsForOrder(2);
    expect(payments, isEmpty);

    // Inventory must not have been decremented.
    expect(await stockOf(product.id), 10, reason: 'rollback total del inventario');

    // Table must not have been marked occupied.
    final table = (await db.tablesDao.getAllTables())
        .firstWhere((t) => t.id == 2);
    expect(table.status, 'available');

    // Customer visits/spend must be untouched.
    final refreshedCustomer = (await db.customersDao.getAllCustomers())
        .firstWhere((c) => c.id == customer.id);
    expect(refreshedCustomer.visits, 0);
    expect(refreshedCustomer.totalSpent, 0);
  });

  // ─── Cobro de orden pendiente (flujo enviar-a-cocina-sin-cobrar) ─────────

  /// Creates an unpaid order the way "Enviar a Cocina" does (order + items +
  /// inventory, no payment), returning its id.
  Future<int> sendToKitchenUnpaid(Product product,
      {int qty = 2, int? tableId, int? customerId}) async {
    return db.transaction(() async {
      final id = await db.ordersDao.insertOrder(
        OrdersCompanion.insert(
          orderNumber: 'tmp-pending',
          type: tableId != null ? 'mesa' : 'para_llevar',
          employeeId: 1,
          tableId: Value(tableId),
          customerId: Value(customerId),
          subtotal: Value(product.price * qty),
          total: Value(product.price * qty),
        ),
      );
      await db.ordersDao.updateOrderNumber(id, 'A-$id');
      await db.orderItemsDao.insertOrderItems([
        OrderItemsCompanion.insert(
          orderId: id,
          productId: product.id,
          productName: product.name,
          quantity: qty,
          unitPrice: product.price,
        ),
      ]);
      await db.inventoryDao.decrementStock(product.id, qty);
      if (tableId != null) {
        await db.tablesDao.updateTableStatus(tableId, 'occupied');
      }
      return id;
    });
  }

  test('cobrar una orden pendiente registra el pago y la marca pagada sin '
      'volver a descontar inventario', () async {
    final product = await trackedProduct(stock: 10);
    final customer = await anyCustomer();

    final orderId = await sendToKitchenUnpaid(product,
        qty: 2, tableId: 1, customerId: customer.id);
    expect(await stockOf(product.id), 8, reason: 'descontado al enviar');

    final result = await checkout.chargeExistingOrder(
      orderId: orderId,
      employeeId: 1,
      paymentMethod: 'efectivo',
      amountTendered: 100,
      changeGiven: 0,
    );

    expect(result.order.paymentStatus, 'pagado');
    // El inventario NO se vuelve a descontar al cobrar.
    expect(await stockOf(product.id), 8, reason: 'sin doble descuento');

    final payments = await db.paymentsDao.getPaymentsForOrder(orderId);
    expect(payments, hasLength(1));
    expect(payments.first.amountTendered, 100);

    // Visita del cliente contada una sola vez, al cobrar.
    final refreshedCustomer = (await db.customersDao.getAllCustomers())
        .firstWhere((c) => c.id == customer.id);
    expect(refreshedCustomer.visits, 1);
  });

  test('cobrar una orden ya lista la entrega y libera la mesa', () async {
    final product = await trackedProduct(stock: 10);
    final orderId = await sendToKitchenUnpaid(product, qty: 1, tableId: 3);

    // La cocina la terminó antes de cobrar.
    await db.ordersDao.updateOrderStatus(orderId, 'listo');

    await checkout.chargeExistingOrder(
      orderId: orderId,
      employeeId: 1,
      paymentMethod: 'tarjeta',
      amountTendered: 50,
    );

    final order = await db.ordersDao.getOrderById(orderId);
    expect(order!.status, 'entregado');
    expect(order.paymentStatus, 'pagado');
    final table =
        (await db.tablesDao.getAllTables()).firstWhere((t) => t.id == 3);
    expect(table.status, 'available');
  });

  test('cobrar una orden ya pagada falla (no duplica el pago)', () async {
    final product = await trackedProduct(stock: 10);
    final orderId = await sendToKitchenUnpaid(product, qty: 1);

    await checkout.chargeExistingOrder(
      orderId: orderId,
      employeeId: 1,
      paymentMethod: 'efectivo',
      amountTendered: 50,
    );

    await expectLater(
      checkout.chargeExistingOrder(
        orderId: orderId,
        employeeId: 1,
        paymentMethod: 'efectivo',
        amountTendered: 50,
      ),
      throwsA(isA<StateError>()),
    );

    final payments = await db.paymentsDao.getPaymentsForOrder(orderId);
    expect(payments, hasLength(1), reason: 'el segundo cobro no debe registrarse');
  });

  // ─── Propinas (4.1) ──────────────────────────────────────────────────────

  test('la propina se guarda en el pago y NO altera el total de la venta',
      () async {
    final product = await trackedProduct(stock: 10);

    final result = await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 1)],
      type: 'para_llevar',
      employeeId: 1,
      subtotal: 50,
      total: 50,
      paymentMethod: 'tarjeta',
      amountTendered: 60, // 50 venta + 10 propina
      tipAmount: 10,
    );

    expect(result.order.total, 50, reason: 'la venta sigue siendo 50');
    final payments = await db.paymentsDao.getPaymentsForOrder(result.order.id);
    expect(payments.first.tipAmount, 10);
  });

  test('el corte de turno suma las propinas como línea aparte', () async {
    final shift = await ShiftService(db)
        .openShift(employeeId: 1, startingCash: 0);
    final product = await trackedProduct(stock: 10);

    await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 1)],
      type: 'para_llevar',
      employeeId: 1,
      subtotal: 50,
      total: 50,
      paymentMethod: 'efectivo',
      amountTendered: 65, // 50 venta + 15 propina
      changeGiven: 0,
      tipAmount: 15,
    );

    final summary = await ShiftService(db).computeSummary(shift.id);
    expect(summary.tipsTotal, 15);
  });

  // ─── Pagos mixtos (4.2) ──────────────────────────────────────────────────

  test('un cobro con dos tramos (tarjeta + efectivo) registra dos pagos y el '
      'cambio solo en el efectivo', () async {
    final product = await trackedProduct(stock: 10);

    final result = await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 2)], // 100
      type: 'para_llevar',
      employeeId: 1,
      subtotal: 100,
      total: 100,
      payments: const [
        PaymentDraft(method: 'tarjeta', amountTendered: 60), // parcial
        PaymentDraft(
            method: 'efectivo', amountTendered: 50, changeGiven: 10), // 40 aplica
      ],
    );

    expect(result.order.paymentStatus, 'pagado');
    final payments = await db.paymentsDao.getPaymentsForOrder(result.order.id);
    expect(payments, hasLength(2));
    final applied =
        payments.fold(0.0, (a, p) => a + p.amountTendered - p.changeGiven);
    expect(applied, 100, reason: 'los tramos cubren exactamente el total');
    expect(
        payments.firstWhere((p) => p.method == 'efectivo').changeGiven, 10);
    expect(
        payments.firstWhere((p) => p.method == 'tarjeta').changeGiven, 0);
  });

  // ─── Anulación de línea (4.3) ────────────────────────────────────────────

  test('anular una línea de una orden no pagada devuelve su stock y reduce los '
      'montos de la orden', () async {
    final product = await trackedProduct(stock: 10);

    // Orden con dos líneas de 1 unidad (subtotal 100), aún sin pagar.
    final orderId = await db.transaction(() async {
      final id = await db.ordersDao.insertOrder(
        OrdersCompanion.insert(
          orderNumber: 'tmp-void',
          type: 'para_llevar',
          employeeId: 1,
          subtotal: const Value(100),
          total: const Value(100),
        ),
      );
      await db.ordersDao.updateOrderNumber(id, 'A-$id');
      await db.orderItemsDao.insertOrderItems([
        OrderItemsCompanion.insert(
            orderId: id,
            productId: product.id,
            productName: product.name,
            quantity: 1,
            unitPrice: 50),
        OrderItemsCompanion.insert(
            orderId: id,
            productId: product.id,
            productName: product.name,
            quantity: 1,
            unitPrice: 50),
      ]);
      await db.inventoryDao.decrementStock(product.id, 2);
      return id;
    });
    expect(await stockOf(product.id), 8);

    final notifier = OrdersNotifier(db);
    try {
      final items = await db.orderItemsDao.getItemsForOrder(orderId);
      await notifier.voidOrderItem(
        orderId: orderId,
        item: items.first,
        reason: 'cliente cambió de opinión',
        employeeId: 1,
      );
    } finally {
      notifier.dispose();
    }

    expect(await stockOf(product.id), 9, reason: 'stock de la línea devuelto');
    final order = await db.ordersDao.getOrderById(orderId);
    expect(order!.subtotal, 50, reason: 'queda solo la otra línea');
    expect(order.total, 50);
    final items = await db.orderItemsDao.getItemsForOrder(orderId);
    expect(items.where((i) => i.itemStatus == 'cancelado'), hasLength(1));
  });

  // ─── Reembolsos (4.4) ────────────────────────────────────────────────────

  test('reembolsar una orden pagada registra el contra-movimiento, devuelve '
      'stock y lo resta del efectivo esperado del turno', () async {
    final shift =
        await ShiftService(db).openShift(employeeId: 1, startingCash: 100);
    final product = await trackedProduct(stock: 10);

    // Venta en efectivo de 100.
    final sale = await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 2)],
      type: 'para_llevar',
      employeeId: 1,
      subtotal: 100,
      total: 100,
      paymentMethod: 'efectivo',
      amountTendered: 100,
    );
    expect(await stockOf(product.id), 8);

    final before = await ShiftService(db).computeSummary(shift.id);
    expect(before.expectedCash, 200); // 100 fondo + 100 venta

    final refund = await RefundService(db).refund(
      orderId: sale.order.id,
      amount: 40,
      reason: 'producto con defecto',
      employeeId: 1,
      supervisorId: 1,
      restock: true,
    );
    expect(refund.amount, 40);

    // Con restock devuelve el stock de la orden completa (2 unidades).
    expect(await stockOf(product.id), 10);

    final after = await ShiftService(db).computeSummary(shift.id);
    expect(after.refundsTotal, 40);
    expect(after.expectedCash, 160, reason: '200 − 40 reembolsado');
  });

  test('no se puede reembolsar una orden no pagada', () async {
    final product = await trackedProduct(stock: 10);
    final orderId = await sendToKitchenUnpaid(product, qty: 1);
    await expectLater(
      RefundService(db).refund(orderId: orderId, amount: 10, employeeId: 1),
      throwsA(isA<StateError>()),
    );
  });

  test('no se puede reembolsar más de lo pagado (tope A2)', () async {
    final product = await trackedProduct(stock: 10);
    final sale = await checkout.checkout(
      cartItems: [CartItem(product: product, quantity: 2)], // total 100
      type: 'para_llevar',
      employeeId: 1,
      subtotal: 100,
      total: 100,
      paymentMethod: 'efectivo',
      amountTendered: 100,
    );
    // Primer reembolso parcial válido.
    await RefundService(db)
        .refund(orderId: sale.order.id, amount: 60, employeeId: 1);
    // El segundo excede lo reembolsable (quedan 40).
    await expectLater(
      RefundService(db)
          .refund(orderId: sale.order.id, amount: 50, employeeId: 1),
      throwsA(isA<StateError>()),
    );
    // 40 exacto sí pasa.
    final ok = await RefundService(db)
        .refund(orderId: sale.order.id, amount: 40, employeeId: 1);
    expect(ok.amount, 40);
  });

  test('el cobro rechaza pagos que no cubren el total (M1)', () async {
    final product = await trackedProduct(stock: 10);
    await expectLater(
      checkout.checkout(
        cartItems: [CartItem(product: product, quantity: 2)], // total 100
        type: 'para_llevar',
        employeeId: 1,
        subtotal: 100,
        total: 100,
        payments: const [
          PaymentDraft(method: 'tarjeta', amountTendered: 60), // solo 60
        ],
      ),
      throwsA(isA<StateError>()),
    );
    // Y no dejó orden a medias.
    final active = await db.ordersDao.getActiveOrders();
    expect(active, isEmpty);
  });
}
