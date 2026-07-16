import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/models/order_with_items.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/discounts_provider.dart';
import '../../core/providers/modifiers_provider.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/products_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/tables_provider.dart';
import '../../core/services/checkout_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/print_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pricing.dart';
import '../auth/supervisor_pin_dialog.dart';
import 'widgets/modifier_dialog.dart';
import 'widgets/order_item_row.dart';
import 'widgets/order_queue_panel.dart';
import 'widgets/payment_modal.dart';
import 'widgets/product_card.dart';

const _orderTypes = [
  ('mesa', 'Mesa', Icons.table_restaurant, LaTerciaColors.mesa),
  ('para_llevar', 'Para llevar', Icons.shopping_bag_outlined,
      LaTerciaColors.llevar),
  ('delivery', 'Delivery', Icons.delivery_dining, LaTerciaColors.delivery),
];

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  // Cart state
  final List<CartItem> _cart = [];
  String _orderType = 'mesa';
  int? _selectedTableId;
  String? _customerName;
  String? _orderNote;
  Discount? _selectedDiscount;

  // UI state
  int? _selectedCategoryId;
  String _searchQuery = '';
  Timer? _clockTimer;

  // Controllers
  final _customerController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _clockTimer?.cancel();
    _customerController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Calculations ─────────────────────────────────────────────────────────

  double get _subtotal =>
      _cart.fold(0.0, (sum, item) => sum + item.lineTotal);

  /// Cada línea del carrito con su IVA efectivo resuelto contra el default
  /// global (`tax_rate` / `tax_included`), para el cálculo por producto (4.5).
  List<TaxLine> get _taxLines {
    final settings = ref.read(settingsProvider).valueOrNull ?? {};
    final globalRate = double.tryParse(settings['tax_rate'] ?? '0') ?? 0;
    final globalIncluded = settings['tax_included'] != 'false';
    return _cart
        .map((item) => TaxLine(
              lineTotal: item.lineTotal,
              taxRate: effectiveTaxRate(item.product.taxRate, globalRate),
              taxIncluded: effectiveTaxIncluded(
                  item.product.taxIncluded, globalIncluded),
            ))
        .toList();
  }

  OrderTotals get _totals => computeTaxedTotals(
        lines: _taxLines,
        discount: _selectedDiscount,
      );

  double get _discountAmount => _totals.discount;
  double get _taxAmount => _totals.tax;
  double get _total => _totals.total;

  // ─── Cart operations ───────────────────────────────────────────────────────

  Future<void> _addToCart(Product product) async {
    final db = ref.read(databaseProvider);
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    String? catName;
    for (final c in cats) {
      if (c.id == product.categoryId) {
        catName = c.name;
        break;
      }
    }
    final mods = await db.modifiersDao.getModifiersForCategoryName(catName);

    if (mods.isNotEmpty) {
      if (!mounted) return;
      final chosen = await showDialog<List<Modifier>>(
        context: context,
        builder: (_) => ModifierDialog(product: product, modifiers: mods),
      );
      if (chosen == null) return; // cancelled
      _doAddToCart(product, chosen);
    } else {
      _doAddToCart(product, []);
    }
  }

  void _doAddToCart(Product product, List<Modifier> modifiers) {
    setState(() {
      final existing = _cart.where((c) =>
          c.product.id == product.id &&
          c.modifiers.map((m) => m.id).join() ==
              modifiers.map((m) => m.id).join());
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(CartItem(product: product, modifiers: modifiers));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _updateQuantity(int index, int qty) {
    setState(() => _cart[index].quantity = qty);
  }

  void _updateItemNote(int index, String? note) {
    setState(() => _cart[index].note = note);
  }

  // Applying a discount is `descuento_manual` in the permission matrix: a
  // cashier needs a supervisor PIN, admin/gerente go through with no dialog.
  // Clearing the discount (picking "Sin desc.") isn't gated — it's the safe
  // direction.
  Future<void> _selectDiscount(Discount discount) async {
    final actor = ref.read(sessionProvider);
    if (actor != null) {
      final allowed = await SupervisorPinDialog.ensure(
        context,
        ref,
        actor: actor,
        action: PermissionAction.descuentoManual,
        entity: 'discount',
        entityId: discount.id,
      );
      if (!allowed) return;
    }
    if (mounted) setState(() => _selectedDiscount = discount);
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _selectedDiscount = null;
      _noteController.clear();
      _customerController.clear();
      _orderNote = null;
      _customerName = null;
    });
  }

  // ─── Order submission ──────────────────────────────────────────────────────

  Future<void> _sendToKitchen() async {
    if (_cart.isEmpty) return;
    final employee = ref.read(sessionProvider);
    if (employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu PIN primero.')),
      );
      return;
    }

    try {
      final orderId = await ref.read(ordersProvider.notifier).sendToKitchen(
            cartItems: List.from(_cart),
            type: _orderType,
            employeeId: employee.id,
            tableId: _orderType == 'mesa' ? _selectedTableId : null,
            customerName: _customerName,
            note: _orderNote,
            subtotal: _subtotal,
            discountAmount: _discountAmount,
            taxAmount: _taxAmount,
            total: _total,
          );

      // Comanda de cocina best-effort tras el commit (detrás de
      // `impresion_activa`; no-op si está OFF). Nunca rompe el envío.
      final db = ref.read(databaseProvider);
      final order = await db.ordersDao.getOrderById(orderId);
      final items = await db.orderItemsDao.getItemsForOrder(orderId);
      final settings = ref.read(settingsProvider).valueOrNull ?? {};
      if (order != null) {
        unawaited(ref.read(printServiceProvider).printKitchenOnly(
              order: order,
              items: items,
              settings: settings,
            ));
      }

      if (mounted) {
        _showToast('Pedido ${formatOrderNumber(orderId)} enviado a cocina');
      }
      _clearCart();
      setState(() => _selectedTableId = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _openPayment() {
    if (_cart.isEmpty) return;
    final employee = ref.read(sessionProvider);
    if (employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu PIN primero.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => PaymentModal(
        total: _total,
        onCheckout: _checkout,
      ),
    );
  }

  // Creates the order and charges it in a single atomic transaction via
  // CheckoutService (order + items + inventory + payment + customer visit),
  // then refreshes the shared orders state so the KDS/queue panel see it.
  // Called when the cashier confirms payment in the payment modal.
  Future<OrderWithItems?> _checkout({
    required List<PaymentDraft> payments,
  }) async {
    final employee = ref.read(sessionProvider);
    if (employee == null) return null;

    final order = await ref.read(checkoutServiceProvider).checkout(
          cartItems: List.from(_cart),
          type: _orderType,
          employeeId: employee.id,
          tableId: _orderType == 'mesa' ? _selectedTableId : null,
          customerName: _customerName,
          note: _orderNote,
          subtotal: _subtotal,
          discountAmount: _discountAmount,
          taxAmount: _taxAmount,
          total: _total,
          payments: payments,
        );

    await ref.read(ordersProvider.notifier).loadActiveOrders();

    _clearCart();
    setState(() => _selectedTableId = null);

    if (mounted) _showToast('Cobro registrado y enviado a cocina');

    return order;
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: LaTerciaColors.darkBrown,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: LaTerciaColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final showCustomer = settings['show_customer_field'] == 'true';
    final enableTables = settings['enable_tables'] == 'true';
    final defaultType = settings['default_order_type'] ?? 'mesa';

    if (_orderType == 'mesa' && defaultType != 'mesa' && _cart.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _orderType = defaultType);
      });
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOrderSidebar(symbol, settings),
                Expanded(
                  child: Column(
                    children: [
                      _buildOrderTypeRow(enableTables, showCustomer),
                      Expanded(child: _buildProductArea(symbol)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const OrderQueuePanel(),
        ],
      ),
    );
  }

  // ─── Order type row ────────────────────────────────────────────────────────

  Widget _buildOrderTypeRow(bool enableTables, bool showCustomer) {
    final tables = ref.watch(tablesProvider).valueOrNull ?? [];
    final available = tables.where((t) => t.status == 'available').toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          _OrderTypeSegment(
            value: _orderType,
            onChanged: (v) => setState(() => _orderType = v),
          ),
          if (_orderType == 'mesa' && enableTables) ...[
            const SizedBox(width: 12),
            _PillDropdown<int?>(
              value: _selectedTableId,
              hint: 'Mesa',
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('Sin mesa')),
                ...available.map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedTableId = v),
            ),
          ],
          if (showCustomer) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 220,
              height: 44,
              child: TextField(
                controller: _customerController,
                style: const TextStyle(fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Cliente (opcional)',
                  isDense: true,
                ),
                onChanged: (v) => _customerName = v.isEmpty ? null : v,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Product area ──────────────────────────────────────────────────────────

  Widget _buildProductArea(String symbol) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final modifiers = ref.watch(modifiersProvider).valueOrNull ?? [];

    return Column(
      children: [
        // Category chips
        categoriesAsync.when(
          data: (cats) => SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _CategoryChip(
                  label: 'Todos',
                  selected: _selectedCategoryId == null,
                  onTap: () => setState(() => _selectedCategoryId = null),
                ),
                ...cats.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _CategoryChip(
                        label: c.name,
                        dotColor: _parseColor(c.color),
                        selected: _selectedCategoryId == c.id,
                        onTap: () =>
                            setState(() => _selectedCategoryId = c.id),
                      ),
                    )),
              ],
            ),
          ),
          loading: () => const SizedBox(height: 52),
          error: (_, __) => const SizedBox(height: 52),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
        // Product grid
        Expanded(
          child: productsAsync.when(
            data: (products) {
              final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
              final catMap = {for (final c in cats) c.id: c};

              var filtered = products.where((p) {
                if (_selectedCategoryId != null &&
                    p.categoryId != _selectedCategoryId) {
                  return false;
                }
                if (_searchQuery.isNotEmpty &&
                    !p.name.toLowerCase()
                        .contains(_searchQuery.toLowerCase())) {
                  return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('Sin productos',
                      style: TextStyle(color: LaTerciaColors.tan)),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 210,
                  childAspectRatio: 0.86,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final product = filtered[i];
                  final cat = catMap[product.categoryId];
                  final hasMods =
                      categoryHasModifiers(modifiers, cat?.name);

                  return ProductCard(
                    product: product,
                    category: cat,
                    currencySymbol: symbol,
                    hasModifiers: hasMods,
                    onTap: () => _addToCart(product),
                    onLongPress: () => _showProductInfo(context, product),
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  void _showProductInfo(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.description != null &&
                product.description!.isNotEmpty)
              Text(product.description!),
            if (product.trackInventory)
              Text('Stock: ${product.stockQuantity}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // ─── Order sidebar (cart) ──────────────────────────────────────────────────

  Widget _buildOrderSidebar(String symbol, Map<String, String> settings) {
    final discountsAsync = ref.watch(discountsProvider);
    final now = DateTime.now();
    // Only offer discounts that are active, within their validity window, and
    // whose minimum-order requirement the current subtotal already meets.
    // These rules were configured in admin but never enforced at checkout.
    final activeDiscounts = discountsAsync.valueOrNull
            ?.where((d) => isDiscountEligible(d, _subtotal, now))
            .toList() ??
        [];

    // If the selected discount stopped qualifying (e.g. items were removed and
    // the subtotal fell below its minimum), drop it.
    if (_selectedDiscount != null &&
        !activeDiscounts.any((d) => d.id == _selectedDiscount!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDiscount = null);
      });
    }

    // El IVA ahora se calcula por producto (4.5); la fila del resumen se muestra
    // cuando hay IVA computado, sin depender de una única tasa global.
    final taxIncludedDefault = settings['tax_included'] != 'false';
    final typeInfo =
        _orderTypes.firstWhere((t) => t.$1 == _orderType, orElse: () => _orderTypes[0]);
    final tables = ref.watch(tablesProvider).valueOrNull ?? [];
    TablesLayoutData? selectedTable;
    if (_selectedTableId != null) {
      for (final t in tables) {
        if (t.id == _selectedTableId) {
          selectedTable = t;
          break;
        }
      }
    }

    return Container(
      width: 360,
      color: LaTerciaColors.cream,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Orden actual',
                          style: TextStyle(
                              fontFamily: 'DM Serif Display', fontSize: 22)),
                      Text(
                        selectedTable?.name ??
                            (_orderType == 'mesa'
                                ? 'Sin mesa'
                                : typeInfo.$2),
                        style: const TextStyle(
                            fontSize: 12.5, color: LaTerciaColors.tan),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: typeInfo.$4.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    typeInfo.$2.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: typeInfo.$4,
                    ),
                  ),
                ),
                if (_cart.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: LaTerciaColors.tan),
                    onPressed: _clearCart,
                    tooltip: 'Vaciar orden',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          // Items list
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: LaTerciaColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_cart_outlined,
                              color: LaTerciaColors.tan, size: 26),
                        ),
                        const SizedBox(height: 14),
                        const Text('Sin artículos',
                            style: TextStyle(
                                color: LaTerciaColors.cocoa,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Toca un producto del catálogo para comenzar la orden.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: LaTerciaColors.tan),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _cart.length,
                    itemBuilder: (ctx, i) => OrderItemRow(
                      item: _cart[i],
                      currencySymbol: symbol,
                      onRemove: () => _removeFromCart(i),
                      onQuantityChanged: (q) => _updateQuantity(i, q),
                      onNoteChanged: (n) => _updateItemNote(i, n),
                    ),
                  ),
          ),
          // Summary
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: const BoxDecoration(
              color: LaTerciaColors.creamAlt,
              border: Border(top: BorderSide(color: LaTerciaColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Discount pills
                const Row(
                  children: [
                    Text('Descuento',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LaTerciaColors.tan)),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _DiscountPill(
                        label: 'Sin desc.',
                        selected: _selectedDiscount == null,
                        onTap: () =>
                            setState(() => _selectedDiscount = null),
                      ),
                      ...activeDiscounts.map((d) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _DiscountPill(
                              label: d.type == 'percentage'
                                  ? '${d.name} (${d.value.toInt()}%)'
                                  : '${d.name} (${formatCurrency(d.value, symbol)})',
                              selected: _selectedDiscount?.id == d.id,
                              onTap: () => _selectDiscount(d),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _summaryRow('Subtotal', formatCurrency(_subtotal, symbol)),
                if (_discountAmount > 0)
                  _summaryRow(
                    'Descuento',
                    '-${formatCurrency(_discountAmount, symbol)}',
                    color: LaTerciaColors.success,
                  ),
                if (_taxAmount > 0)
                  _summaryRow(
                      taxIncludedDefault ? 'IVA (incluido)' : 'IVA',
                      formatCurrency(_taxAmount, symbol)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: LaTerciaColors.cocoa)),
                    Text(
                      formatCurrency(_total, symbol),
                      style: const TextStyle(
                        fontFamily: 'DM Serif Display',
                        fontSize: 26,
                        color: LaTerciaColors.burntOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Nota de la orden...',
                    isDense: true,
                  ),
                  onChanged: (v) => _orderNote = v.isEmpty ? null : v,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _cart.isNotEmpty ? _sendToKitchen : null,
                    icon: const Icon(Icons.send, size: 17),
                    label: const Text('Enviar a Cocina'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LaTerciaColors.darkBrown,
                      side: const BorderSide(color: LaTerciaColors.darkBrown),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _cart.isNotEmpty ? _openPayment : null,
                    icon: const Icon(Icons.payments, size: 17),
                    label: const Text('Cobrar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: LaTerciaColors.tan)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? LaTerciaColors.cocoa)),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return LaTerciaColors.catCaliente;
    }
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _OrderTypeSegment extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _OrderTypeSegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LaTerciaColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _orderTypes.map((t) {
          final selected = t.$1 == value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: selected ? LaTerciaColors.darkBrown : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onChanged(t.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  child: Row(
                    children: [
                      Icon(t.$3,
                          size: 16,
                          color: selected
                              ? Colors.white
                              : LaTerciaColors.cocoa),
                      const SizedBox(width: 6),
                      Text(
                        t.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color:
                              selected ? Colors.white : LaTerciaColors.cocoa,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PillDropdown<T> extends StatelessWidget {
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _PillDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LaTerciaColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13.5)),
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
              fontSize: 13.5, color: LaTerciaColors.cocoa),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    this.dotColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LaTerciaColors.darkBrown : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? LaTerciaColors.darkBrown
                    : LaTerciaColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor ?? LaTerciaColors.gold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : LaTerciaColors.cocoa,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscountPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DiscountPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LaTerciaColors.burntOrange : Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
                color: selected
                    ? LaTerciaColors.burntOrange
                    : LaTerciaColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : LaTerciaColors.cocoa,
            ),
          ),
        ),
      ),
    );
  }
}
