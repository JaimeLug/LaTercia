import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/models/order_with_items.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/providers/combos_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/delivery_zones_provider.dart';
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
  (
    'para_llevar',
    'Para llevar',
    Icons.shopping_bag_outlined,
    LaTerciaColors.llevar
  ),
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
  // Zona de envío obligatoria cuando _orderType == 'delivery'.
  int? _selectedZoneId;
  String? _customerName;
  // Fidelización (docs/fidelizacion.md): cliente real vinculado a la venta
  // (antes el campo de arriba era solo texto libre, sin ligar a un Customer).
  Customer? _selectedCustomer;
  List<Customer> _customerSuggestions = const [];
  Timer? _customerSearchDebounce;
  // El cajero decidió canjear la recompensa ganada — NUNCA automático. Sellos
  // y puntos son mecánicas independientes (ambas pueden estar activas a la
  // vez), así que cada una tiene su propio toggle. `docs/fidelizacion.md`.
  bool _stampsRewardApplied = false;
  bool _pointsRewardApplied = false;
  // Datos de reparto: solo se usan cuando _orderType == 'delivery'.
  String? _customerPhone;
  String? _customerAddress;
  // Pago esperado del delivery: método + con cuánto paga en efectivo (para el
  // cambio en la comanda de reparto). Transferencia marca la orden pagada.
  String _deliveryMethod = 'efectivo';
  String? _orderNote;
  Discount? _selectedDiscount;
  // Si el cajero tocó "Sin desc." mientras había una promo programada, no se
  // vuelve a auto-aplicar en esta orden (se resetea al vaciar el carrito).
  // docs/promociones.md.
  bool _autoDismissed = false;

  // UI state
  int? _selectedCategoryId;
  // Chip "Combos" en la barra de categorías: reemplaza la cuadrícula de
  // productos por tarjetas de combo. docs/combos.md.
  bool _showingCombos = false;
  String _searchQuery = '';
  Timer? _clockTimer;
  // Barra de categorías: controller + una key por chip (null = "Todos") para,
  // al tocar una, centrarla y revelar las vecinas escondidas en el kiosco.
  final _catScrollController = ScrollController();
  final Map<int?, GlobalKey> _catKeys = {};
  // Barra de descuentos: mismo patrón de auto-scroll que la de categorías —
  // con más de 3 descuentos activos, el elegido puede quedar fuera de vista.
  // Key null = "Sin desc.". Feedback de sitio 2026-07-22.
  final _discScrollController = ScrollController();
  final Map<int?, GlobalKey> _discKeys = {};

  // Controllers
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();
  final _deliveryCashController = TextEditingController();

  @override
  void dispose() {
    _clockTimer?.cancel();
    _customerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    _deliveryCashController.dispose();
    _catScrollController.dispose();
    _discScrollController.dispose();
    _customerSearchDebounce?.cancel();
    super.dispose();
  }

  /// Centra suavemente la categoría [id] en la barra para revelar las vecinas
  /// (en el kiosco no se puede arrastrar la barra a mano).
  void _selectCategory(int? id) {
    setState(() {
      _selectedCategoryId = id;
      _showingCombos = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _catKeys[id]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Centra suavemente el descuento [id] (null = "Sin desc.") en su barra —
  /// mismo patrón que `_selectCategory`. Feedback de sitio 2026-07-22.
  void _scrollToSelectedDiscount(int? id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _discKeys[id]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Cambia a la vista de Combos (reemplaza la cuadrícula de productos).
  /// docs/combos.md.
  void _selectCombosView() {
    setState(() {
      _showingCombos = true;
      _selectedCategoryId = null;
    });
  }

  /// El campo de cliente ahora también busca (debounce 250ms) — si el cajero
  /// escribe algo distinto al cliente ya elegido, se pierde la selección (hay
  /// que volver a elegir de las sugerencias). `docs/fidelizacion.md`.
  void _onCustomerNameChanged(String v) {
    _customerName = v.isEmpty ? null : v;
    if (_selectedCustomer != null && v != _selectedCustomer!.name) {
      setState(() {
        _selectedCustomer = null;
        _stampsRewardApplied = false;
        _pointsRewardApplied = false;
      });
    }
    _customerSearchDebounce?.cancel();
    if (v.trim().length < 2) {
      if (_customerSuggestions.isNotEmpty) {
        setState(() => _customerSuggestions = const []);
      }
      return;
    }
    _customerSearchDebounce =
        Timer(const Duration(milliseconds: 250), () async {
      final results = await ref
          .read(databaseProvider)
          .customersDao
          .searchCustomers(v.trim());
      if (mounted) setState(() => _customerSuggestions = results);
    });
  }

  void _selectCustomer(Customer c) {
    setState(() {
      _selectedCustomer = c;
      _customerName = c.name;
      _customerController.text = c.name;
      _customerSuggestions = const [];
      _stampsRewardApplied = false;
      _pointsRewardApplied = false;
    });
  }

  // ─── Calculations ─────────────────────────────────────────────────────────

  double get _subtotal => _cart.fold(0.0, (sum, item) => sum + item.lineTotal);

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

  /// Cada línea del carrito para calcular promociones (precio, cantidad,
  /// producto) — el alcance de promos/fidelización es por producto, no por
  /// categoría. `docs/promociones.md`.
  List<PromoLine> get _promoLines => _cart
      .map((item) => (
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            productName: item.product.name,
          ))
      .toList();

  /// La promoción elegida (si hay) + la(s) recompensa(s) de fidelización que
  /// el cajero canjeó (sellos y/o puntos, independientes entre sí), ya
  /// resueltas a UN monto fijo en efectivo — se suman porque son cosas
  /// distintas (una promo de horario y un premio por lealtad pueden
  /// coexistir). Se pasa a `computeTaxedTotals` como 'fixed' ya calculado —
  /// el prorrateo de IVA no cambia.
  /// `docs/promociones.md` + `docs/fidelizacion.md`.
  Discount? get _resolvedDiscount {
    var amount = 0.0;
    var label = '';
    final d = _selectedDiscount;
    if (d != null) {
      amount += discountAmountForCart(d, _promoLines);
      label = d.name;
    }
    if (_stampsRewardApplied || _pointsRewardApplied) {
      final settings = ref.read(settingsProvider).valueOrNull ?? {};
      if (_stampsRewardApplied) {
        final rewardProduct = settings['loyalty_stamps_reward_product'] ?? '';
        amount += loyaltyRewardAmount(_promoLines, rewardProduct);
      }
      if (_pointsRewardApplied) {
        final rewardProduct = settings['loyalty_points_reward_product'] ?? '';
        amount += loyaltyRewardAmount(_promoLines, rewardProduct);
      }
      label = label.isEmpty ? 'Recompensa' : '$label + Recompensa';
    }
    if (amount <= 0) return null;
    return Discount(
      id: d?.id ?? -1,
      name: label,
      type: 'fixed',
      value: amount,
      minOrderAmount: 0,
      active: true,
      createdAt: d?.createdAt ?? DateTime.now(),
    );
  }

  OrderTotals get _totals => computeTaxedTotals(
        lines: _taxLines,
        discount: _resolvedDiscount,
      );

  double get _discountAmount => _totals.discount;
  double get _taxAmount => _totals.tax;

  /// FASE 8 — cargo de envío de la zona elegida (0 si no aplica o no se ha
  /// elegido zona todavía). Se suma al total, igual que el IVA.
  double get _deliveryFee {
    if (_orderType != 'delivery' || _selectedZoneId == null) return 0;
    final zones = ref.read(deliveryZonesProvider).valueOrNull ?? [];
    final zone = zones.where((z) => z.id == _selectedZoneId).firstOrNull;
    return zone?.fee ?? 0;
  }

  String? get _deliveryZoneName {
    if (_orderType != 'delivery' || _selectedZoneId == null) return null;
    final zones = ref.read(deliveryZonesProvider).valueOrNull ?? [];
    return zones.where((z) => z.id == _selectedZoneId).firstOrNull?.name;
  }

  double get _total => _totals.total + _deliveryFee;

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
      final chosen = await showDialog<ModifierSelection>(
        context: context,
        builder: (_) => ModifierDialog(product: product, modifiers: mods),
      );
      if (chosen == null) return; // cancelled
      _doAddToCart(product, chosen.modifiers, chosen.includedIds);
    } else {
      _doAddToCart(product, [], {});
    }
  }

  void _doAddToCart(
      Product product, List<Modifier> modifiers, Set<int> includedIds) {
    setState(() {
      final existing = _cart.where((c) =>
          c.product.id == product.id &&
          c.modifiers.map((m) => m.id).join() ==
              modifiers.map((m) => m.id).join() &&
          c.includedModifierIds.join(',') == includedIds.join(','));
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(CartItem(
            product: product,
            modifiers: modifiers,
            includedModifierIds: includedIds));
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

  /// Agrega una instancia del [combo] al carrito: expande sus componentes en
  /// líneas normales (precio prorrateado, mismo id de producto para
  /// inventario/KDS), pidiendo modificadores por componente si aplica. Si se
  /// cancela cualquier paso, NO se agrega nada parcial. `docs/combos.md`.
  Future<void> _addComboToCart(Combo combo) async {
    final db = ref.read(databaseProvider);
    final components = await db.combosDao.getComboComponents(combo.id);
    if (components.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Este combo no tiene productos configurados.')));
      return;
    }

    final prorated = proratedComboPrices(combo.price, [
      for (final c in components)
        (basePrice: c.product.price, quantity: c.quantity),
    ]);
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    final catNameById = {for (final c in cats) c.id: c.name};
    final instanceId = const Uuid().v4();

    final lines = <CartItem>[];
    for (var i = 0; i < components.length; i++) {
      final comp = components[i];
      final catName = catNameById[comp.product.categoryId];
      final mods = await db.modifiersDao.getModifiersForCategoryName(catName);
      List<Modifier> chosenMods = const [];
      Set<int> includedIds = const {};
      if (mods.isNotEmpty) {
        if (!mounted) return;
        final chosen = await showDialog<ModifierSelection>(
          context: context,
          builder: (_) =>
              ModifierDialog(product: comp.product, modifiers: mods),
        );
        if (chosen == null) return; // canceló: se aborta el combo completo
        chosenMods = chosen.modifiers;
        includedIds = chosen.includedIds;
      }
      lines.add(CartItem(
        product: comp.product.copyWith(price: prorated[i]),
        modifiers: chosenMods,
        includedModifierIds: includedIds,
        quantity: comp.quantity,
        comboInstanceId: instanceId,
        comboName: combo.name,
      ));
    }

    if (!mounted) return;
    setState(() => _cart.addAll(lines));
  }

  /// Quita TODAS las líneas de una instancia de combo a la vez — nunca queda
  /// un combo a medias. `docs/combos.md`.
  void _removeComboGroup(String instanceId) {
    setState(() => _cart.removeWhere((c) => c.comboInstanceId == instanceId));
  }

  // Aplicar descuento es `descuento_manual` (pide PIN de supervisor al cajero);
  // quitarlo no está restringido. docs/permisos-y-auditoria.md.
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
    _scrollToSelectedDiscount(discount.id);
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _selectedDiscount = null;
      _autoDismissed = false;
      _selectedZoneId = null;
      _noteController.clear();
      _customerController.clear();
      _phoneController.clear();
      _addressController.clear();
      _orderNote = null;
      _customerName = null;
      _customerPhone = null;
      _customerAddress = null;
      _deliveryMethod = 'efectivo';
      _deliveryCashController.clear();
      _selectedCustomer = null;
      _customerSuggestions = const [];
      _stampsRewardApplied = false;
      _pointsRewardApplied = false;
    });
  }

  // ─── Order submission ──────────────────────────────────────────────────────

  /// Delivery requiere zona, teléfono y dirección — sin esto no se puede
  /// armar una comanda de reparto útil para el repartidor. Devuelve el
  /// mensaje del primer dato que falte, o `null` si está completo.
  String? _missingDeliveryData() {
    if (_orderType != 'delivery') return null;
    if (_selectedZoneId == null) return 'Elige la zona de envío.';
    if (_customerName == null || _customerName!.trim().isEmpty) {
      return 'Captura el nombre del cliente.';
    }
    if (_customerPhone == null || _customerPhone!.trim().isEmpty) {
      return 'Captura el teléfono del cliente.';
    }
    if (_customerAddress == null || _customerAddress!.trim().isEmpty) {
      return 'Captura la dirección de entrega.';
    }
    return null;
  }

  Future<void> _sendToKitchen() async {
    if (_cart.isEmpty) return;
    final employee = ref.read(sessionProvider);
    if (employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu PIN primero.')),
      );
      return;
    }
    final missing = _missingDeliveryData();
    if (missing != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(missing)));
      return;
    }

    try {
      final orderId = await ref.read(ordersProvider.notifier).sendToKitchen(
            cartItems: List.from(_cart),
            type: _orderType,
            employeeId: employee.id,
            tableId: _orderType == 'mesa' ? _selectedTableId : null,
            customerName: _customerName,
            customerId: _selectedCustomer?.id,
            customerPhone: _orderType == 'delivery' ? _customerPhone : null,
            customerAddress: _orderType == 'delivery' ? _customerAddress : null,
            note: _orderNote,
            subtotal: _subtotal,
            discountAmount: _discountAmount,
            taxAmount: _taxAmount,
            deliveryZone: _deliveryZoneName,
            deliveryFee: _deliveryFee,
            total: _total,
            deliveryPaymentMethod:
                _orderType == 'delivery' ? _deliveryMethod : null,
            deliveryCashAmount:
                (_orderType == 'delivery' && _deliveryMethod == 'efectivo')
                    ? double.tryParse(
                        _deliveryCashController.text.replaceAll(',', '.'))
                    : null,
          );

      // Delivery por transferencia: se cobra de una vez (el dinero ya cayó),
      // para que la orden no quede "por cobrar". El efectivo queda pendiente y
      // el repartidor cobra al entregar. docs/impresion.md §Reparto.
      if (_orderType == 'delivery' && _deliveryMethod == 'transferencia') {
        await ref.read(checkoutServiceProvider).chargeExistingOrder(
              orderId: orderId,
              employeeId: employee.id,
              paymentMethod: 'transferencia',
              amountTendered: _total,
            );
      }

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

  /// Disponible solo sin descuento/promo/combo/recompensa activos — prorratear
  /// eso por persona es ambiguo, mejor no adivinar. `docs/division-cuenta.md`.
  bool get _canSplitByItem =>
      _cart.length >= 2 &&
      _selectedDiscount == null &&
      !_stampsRewardApplied &&
      !_pointsRewardApplied;

  /// Líneas de impuesto de un subconjunto del carrito (para calcular el total
  /// de un grupo al dividir por artículo). Mismo cálculo que `_taxLines`, pero
  /// sobre [items] en vez de todo `_cart`. `docs/division-cuenta.md`.
  List<TaxLine> _taxLinesFor(List<CartItem> items) {
    final settings = ref.read(settingsProvider).valueOrNull ?? {};
    final globalRate = double.tryParse(settings['tax_rate'] ?? '0') ?? 0;
    final globalIncluded = settings['tax_included'] != 'false';
    return items
        .map((item) => TaxLine(
              lineTotal: item.lineTotal,
              taxRate: effectiveTaxRate(item.product.taxRate, globalRate),
              taxIncluded: effectiveTaxIncluded(
                  item.product.taxIncluded, globalIncluded),
            ))
        .toList();
  }

  /// Cobra el subconjunto [items] de UNA persona como su propia orden
  /// independiente (mismo `checkout()` de siempre) — no hay descuento porque
  /// `_canSplitByItem` ya lo exige. `docs/division-cuenta.md`.
  Future<OrderWithItems?> _checkoutGroup(
      List<CartItem> items, List<PaymentDraft> payments) async {
    final employee = ref.read(sessionProvider);
    if (employee == null) return null;
    final totals = computeTaxedTotals(lines: _taxLinesFor(items));
    // Redondeado a centavos — el MISMO número que `_startItemSplit` calculó
    // y mostró/cobró en el PaymentModal. Sin este redondeo, un total crudo
    // de combo (ej. $35.594) puede quedar por encima de lo YA cobrado
    // ($35.59) y `_assertCovers` lo rechaza con "los pagos no cubren el
    // total" aunque ambos se vean idénticos redondeados a 2 decimales.
    // `docs/division-cuenta.md`.
    final total = (totals.total * 100).round() / 100;
    final order = await ref.read(checkoutServiceProvider).checkout(
          cartItems: items,
          type: _orderType,
          employeeId: employee.id,
          tableId: _orderType == 'mesa' ? _selectedTableId : null,
          customerName: _customerName,
          subtotal: totals.subtotal,
          taxAmount: totals.tax,
          total: total,
          payments: payments,
        );
    await ref.read(ordersProvider.notifier).loadActiveOrders();
    return order;
  }

  /// Pide asignar cada línea del carrito a una persona y cobra a cada quien
  /// por separado (un `PaymentModal` por persona, en secuencia) — cada uno
  /// termina siendo su propia orden, con su propio ticket.
  /// `docs/division-cuenta.md`.
  Future<void> _startItemSplit() async {
    if (!_canSplitByItem) return;
    final employee = ref.read(sessionProvider);
    if (employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu PIN primero.')),
      );
      return;
    }
    final missing = _missingDeliveryData();
    if (missing != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(missing)));
      return;
    }

    final groups = await showDialog<List<List<CartItem>>>(
      context: context,
      builder: (_) => _SplitByItemDialog(cart: List.of(_cart)),
    );
    if (groups == null) return;

    // Solo se quitan del carrito las líneas de las personas que SÍ pagaron —
    // si alguien cancela a medio split, sus artículos se quedan (no se pierde
    // la orden completa). `docs/division-cuenta.md`.
    final paidItems = <CartItem>[];
    // Un recibo en pantalla POR PERSONA se amontonaba con el PaymentModal de
    // la siguiente (que se abre en cuanto este se cierra, sin esperar a que
    // el cajero cierre el recibo anterior) — feedback de sitio 2026-07-22.
    // Se juntan aquí y se muestra UN resumen combinado al final.
    // `docs/division-cuenta.md`.
    final paidOrders = <OrderWithItems>[];
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (group.isEmpty) continue;
      if (!mounted) return;
      // Redondeado a centavos: el total que se muestra/compara en el modal
      // debe ser el mismo número exacto, sin arrastrar el ruido de punto
      // flotante de un precio prorrateado de combo. docs/division-cuenta.md.
      final rawTotal = computeTaxedTotals(lines: _taxLinesFor(group)).total;
      final total = (rawTotal * 100).round() / 100;
      OrderWithItems? paid;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PaymentModal(
          total: total,
          personLabel: 'Cuenta de la persona ${i + 1} de ${groups.length}',
          showReceiptOnConfirm: false,
          onCheckout: ({required payments}) async {
            paid = await _checkoutGroup(group, payments);
            return paid;
          },
        ),
      );
      if (paid != null) {
        paidItems.addAll(group);
        paidOrders.add(paid!);
      }
    }

    if (mounted && paidItems.isNotEmpty) {
      setState(() {
        _cart.removeWhere(paidItems.contains);
        if (_cart.isEmpty) {
          _selectedTableId = null;
          _selectedCustomer = null;
          _customerSuggestions = const [];
          _stampsRewardApplied = false;
          _pointsRewardApplied = false;
        }
      });
    }

    if (mounted && paidOrders.isNotEmpty) {
      final settings = ref.read(settingsProvider).valueOrNull ?? {};
      final symbol = settings['currency_symbol'] ?? r'$';
      await showDialog(
        context: context,
        builder: (_) =>
            _SplitReceiptsSummaryDialog(orders: paidOrders, symbol: symbol),
      );
      // Re-bloqueo opcional tras la venta (`lock_tras_venta`) — UNA sola vez
      // al final de todas las personas, no por cada una (el PaymentModal ya
      // no lo dispara mientras showReceiptOnConfirm es false).
      if (settings['lock_tras_venta'] == 'true' && mounted) {
        ref.read(sessionProvider.notifier).state = null;
      }
    }
  }

  void _openPayment({bool autoStartEvenSplit = false}) {
    if (_cart.isEmpty) return;
    final employee = ref.read(sessionProvider);
    if (employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu PIN primero.')),
      );
      return;
    }
    final missing = _missingDeliveryData();
    if (missing != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(missing)));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => PaymentModal(
        total: _total,
        onCheckout: _checkout,
        autoStartEvenSplit: autoStartEvenSplit,
      ),
    );
  }

  /// El botón "Dividir cuenta" del carrito ofrece las DOS mecánicas en un
  /// solo lugar — antes "partes iguales" solo vivía escondida dentro del
  /// `PaymentModal` y el cajero solo encontraba "por artículo" desde el
  /// carrito (feedback de sitio 2026-07-22). `docs/division-cuenta.md`.
  Future<void> _showSplitChoice() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Dividir cuenta'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'partes_iguales'),
            child: const ListTile(
              leading: Icon(Icons.groups_outlined),
              title: Text('Partes iguales'),
              subtitle: Text('El total se reparte entre N personas.'),
            ),
          ),
          SimpleDialogOption(
            onPressed: _canSplitByItem
                ? () => Navigator.pop(context, 'por_producto')
                : null,
            child: ListTile(
              enabled: _canSplitByItem,
              leading: const Icon(Icons.call_split),
              title: const Text('Por producto'),
              subtitle: Text(_canSplitByItem
                  ? 'Cada persona paga solo lo que pidió.'
                  : 'Quita el descuento/recompensa primero.'),
            ),
          ),
        ],
      ),
    );
    if (choice == 'partes_iguales') {
      _openPayment(autoStartEvenSplit: true);
    } else if (choice == 'por_producto') {
      _startItemSplit();
    }
  }

  // Crea y cobra la orden en una transacción atómica (CheckoutService) y
  // refresca el estado compartido. docs/ventas-cobro-turnos.md.
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
          customerId: _selectedCustomer?.id,
          customerPhone: _orderType == 'delivery' ? _customerPhone : null,
          customerAddress: _orderType == 'delivery' ? _customerAddress : null,
          note: _orderNote,
          subtotal: _subtotal,
          discountAmount: _discountAmount,
          taxAmount: _taxAmount,
          deliveryZone: _deliveryZoneName,
          deliveryFee: _deliveryFee,
          total: _total,
          payments: payments,
          redeemStamps: _stampsRewardApplied,
          redeemPoints: _pointsRewardApplied,
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
            const Icon(Icons.check_circle,
                color: LaTerciaColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if (_orderType == 'delivery') ...[
                const SizedBox(width: 12),
                Builder(builder: (context) {
                  final zones =
                      ref.watch(deliveryZonesProvider).valueOrNull ?? [];
                  return _PillDropdown<int?>(
                    value: _selectedZoneId,
                    hint: 'Zona de envío *',
                    items: zones
                        .map((z) => DropdownMenuItem<int?>(
                              value: z.id,
                              child: Text(z.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedZoneId = v),
                  );
                }),
              ],
              if (showCustomer) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 220,
                  height: 44,
                  child: TextField(
                    controller: _customerController,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: _orderType == 'delivery'
                          ? 'Cliente *'
                          : 'Cliente (opcional, buscar...)',
                      isDense: true,
                      suffixIcon: _selectedCustomer != null
                          ? const Icon(Icons.check_circle,
                              size: 16, color: LaTerciaColors.success)
                          : null,
                    ),
                    onChanged: _onCustomerNameChanged,
                  ),
                ),
              ],
            ],
          ),
          // Sugerencias de clientes al buscar. docs/fidelizacion.md.
          if (_customerSuggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in _customerSuggestions)
                    ActionChip(
                      avatar: const Icon(Icons.person, size: 15),
                      label: Text(c.phone != null && c.phone!.isNotEmpty
                          ? '${c.name} · ${c.phone}'
                          : c.name),
                      onPressed: () => _selectCustomer(c),
                    ),
                ],
              ),
            ),
          // Progreso de fidelización + pill de recompensa. docs/fidelizacion.md.
          if (_selectedCustomer != null) _buildLoyaltyStatus(),
          // Datos de entrega (2026-07-20): solo para delivery — alimentan la
          // comanda de reparto (nombre + teléfono + dirección + zona), para
          // que el repartidor sepa a dónde y con quién.
          if (_orderType == 'delivery') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 180,
                  height: 44,
                  child: TextField(
                    controller: _phoneController,
                    style: const TextStyle(fontSize: 13.5),
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Teléfono *',
                      isDense: true,
                      prefixIcon: Icon(Icons.phone_outlined, size: 18),
                    ),
                    onChanged: (v) => _customerPhone = v.isEmpty ? null : v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _addressController,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Dirección de entrega *',
                        isDense: true,
                        prefixIcon: Icon(Icons.place_outlined, size: 18),
                      ),
                      onChanged: (v) => _customerAddress = v.isEmpty ? null : v,
                    ),
                  ),
                ),
              ],
            ),
            // Pago esperado del delivery: cómo va a pagar el cliente. En
            // efectivo se captura con cuánto paga para calcular el cambio del
            // repartidor. Transferencia marca la orden pagada.
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: 'efectivo',
                          label: Text('Efectivo'),
                          icon: Icon(Icons.payments_outlined, size: 16)),
                      ButtonSegment(
                          value: 'transferencia',
                          label: Text('Transferencia'),
                          icon: Icon(Icons.swap_horiz, size: 16)),
                    ],
                    selected: {_deliveryMethod},
                    onSelectionChanged: (s) =>
                        setState(() => _deliveryMethod = s.first),
                  ),
                ),
                if (_deliveryMethod == 'efectivo') ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 190,
                    height: 44,
                    child: TextField(
                      controller: _deliveryCashController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Paga con (opcional)',
                        isDense: true,
                        prefixIcon: Icon(Icons.attach_money, size: 18),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Progreso de fidelización del cliente elegido + pill de recompensa (el
  /// cajero decide si la aplica — nunca automático). Sellos y puntos son
  /// mecánicas independientes: si ambas están activas, se muestran las DOS
  /// filas de progreso a la vez. `docs/fidelizacion.md`.
  Widget _buildLoyaltyStatus() {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final sellosOn = settings['loyalty_sellos_activo'] == 'true';
    final puntosOn = settings['loyalty_puntos_activo'] == 'true';
    if (!sellosOn && !puntosOn) return const SizedBox.shrink();

    final customer = _selectedCustomer!;
    final rows = <Widget>[];

    if (sellosOn) {
      final stampsRequired =
          int.tryParse(settings['loyalty_stamps_required'] ?? '') ?? 0;
      final rewardProduct = settings['loyalty_stamps_reward_product'] ?? '';
      final eligible = rewardProduct.isNotEmpty &&
          loyaltyRewardAvailable(
            loyaltyType: 'sellos',
            stamps: customer.loyaltyStamps,
            stampsRequired: stampsRequired,
            points: 0,
            pointsRequired: 0,
          );
      rows.add(_loyaltyRewardRow(
        progress: '${customer.loyaltyStamps}/$stampsRequired sellos',
        eligible: eligible,
        applied: _stampsRewardApplied,
        onToggle: () =>
            setState(() => _stampsRewardApplied = !_stampsRewardApplied),
      ));
    }
    if (puntosOn) {
      final pointsRequired =
          int.tryParse(settings['loyalty_points_required'] ?? '') ?? 0;
      final rewardProduct = settings['loyalty_points_reward_product'] ?? '';
      final eligible = rewardProduct.isNotEmpty &&
          loyaltyRewardAvailable(
            loyaltyType: 'puntos',
            stamps: 0,
            stampsRequired: 0,
            points: customer.loyaltyPoints,
            pointsRequired: pointsRequired,
          );
      rows.add(_loyaltyRewardRow(
        progress: '${customer.loyaltyPoints}/$pointsRequired puntos',
        eligible: eligible,
        applied: _pointsRewardApplied,
        onToggle: () =>
            setState(() => _pointsRewardApplied = !_pointsRewardApplied),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  Widget _loyaltyRewardRow({
    required String progress,
    required bool eligible,
    required bool applied,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.loyalty, size: 14, color: LaTerciaColors.tan),
          const SizedBox(width: 6),
          Text(progress,
              style: const TextStyle(fontSize: 12, color: LaTerciaColors.tan)),
          if (eligible) ...[
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: applied
                      ? LaTerciaColors.success
                      : LaTerciaColors.successBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LaTerciaColors.success),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard,
                        size: 13,
                        color: applied ? Colors.white : LaTerciaColors.success),
                    const SizedBox(width: 4),
                    Text(
                      applied ? 'Recompensa aplicada' : 'Recompensa disponible',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: applied ? Colors.white : LaTerciaColors.success,
                      ),
                    ),
                  ],
                ),
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
    // Solo combos activos; el chip ni aparece si el dueño no configuró
    // ninguno. docs/combos.md.
    final activeCombos = (ref.watch(combosProvider).valueOrNull ?? [])
        .where((c) => c.active)
        .toList();

    return Column(
      children: [
        // Category chips
        categoriesAsync.when(
          data: (cats) => SizedBox(
            height: 52,
            child: ListView(
              controller: _catScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _CategoryChip(
                  key: _catKeys.putIfAbsent(null, () => GlobalKey()),
                  label: 'Todos',
                  selected: _selectedCategoryId == null && !_showingCombos,
                  onTap: () => _selectCategory(null),
                ),
                if (activeCombos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _CategoryChip(
                      label: 'Combos',
                      icon: Icons.fastfood_outlined,
                      selected: _showingCombos,
                      onTap: _selectCombosView,
                    ),
                  ),
                ...cats.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _CategoryChip(
                        key: _catKeys.putIfAbsent(c.id, () => GlobalKey()),
                        label: c.name,
                        dotColor: _parseColor(c.color),
                        selected:
                            _selectedCategoryId == c.id && !_showingCombos,
                        onTap: () => _selectCategory(c.id),
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
        // Product grid (o cuadrícula de Combos si _showingCombos).
        // docs/combos.md.
        Expanded(
          child: _showingCombos
              ? _buildComboGrid(activeCombos, symbol)
              : productsAsync.when(
                  data: (products) {
                    final cats =
                        ref.watch(categoriesProvider).valueOrNull ?? [];
                    final catMap = {for (final c in cats) c.id: c};

                    var filtered = products.where((p) {
                      if (_selectedCategoryId != null &&
                          p.categoryId != _selectedCategoryId) {
                        return false;
                      }
                      if (_searchQuery.isNotEmpty &&
                          !p.name
                              .toLowerCase()
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

  /// Cuadrícula de combos activos. `docs/combos.md`.
  Widget _buildComboGrid(List<Combo> combos, String symbol) {
    if (combos.isEmpty) {
      return const Center(
        child: Text('Sin combos activos',
            style: TextStyle(color: LaTerciaColors.tan)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        childAspectRatio: 0.86,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: combos.length,
      itemBuilder: (ctx, i) => _ComboCard(
        combo: combos[i],
        currencySymbol: symbol,
        onTap: () => _addComboToCart(combos[i]),
      ),
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
            if (product.description != null && product.description!.isNotEmpty)
              Text(product.description!),
            if (product.trackInventory) Text('Stock: ${product.stockQuantity}'),
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

  /// Filas del carrito: las líneas de combo salen agrupadas bajo un
  /// encabezado (sin precio/cantidad por línea; el ✕ del grupo quita todas
  /// juntas). El resto se ve igual que siempre. `docs/combos.md`.
  List<Widget> _buildCartRows(String symbol) {
    final widgets = <Widget>[];
    final seenCombo = <String>{};
    for (var i = 0; i < _cart.length; i++) {
      final item = _cart[i];
      final comboId = item.comboInstanceId;
      if (comboId != null && seenCombo.add(comboId)) {
        final groupTotal = _cart
            .where((c) => c.comboInstanceId == comboId)
            .fold(0.0, (s, c) => s + c.lineTotal);
        widgets.add(_ComboGroupHeader(
          name: item.comboName ?? 'Combo',
          total: groupTotal,
          symbol: symbol,
          onRemove: () => _removeComboGroup(comboId),
        ));
      }
      widgets.add(OrderItemRow(
        key: ValueKey('cart-$i'),
        item: item,
        currencySymbol: symbol,
        hidePrice: comboId != null,
        hideQuantity: comboId != null,
        onRemove: comboId != null
            ? () => _removeComboGroup(comboId)
            : () => _removeFromCart(i),
        onQuantityChanged: (q) => _updateQuantity(i, q),
        onNoteChanged: (n) => _updateItemNote(i, n),
      ));
    }
    return widgets;
  }

  Widget _buildOrderSidebar(String symbol, Map<String, String> settings) {
    final discountsAsync = ref.watch(discountsProvider);
    final now = DateTime.now();
    // Solo descuentos elegibles (activos, vigentes, mínimo alcanzado).
    // docs/precios-e-iva.md §"¿Cuándo se puede aplicar un descuento?".
    final activeDiscounts = discountsAsync.valueOrNull
            ?.where((d) => isDiscountEligible(d, _subtotal, now))
            .toList() ??
        [];

    // Si el descuento elegido dejó de calificar (bajó el subtotal), se quita.
    if (_selectedDiscount != null &&
        !activeDiscounts.any((d) => d.id == _selectedDiscount!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDiscount = null);
      });
    } else if (_selectedDiscount == null &&
        !_autoDismissed &&
        _cart.isNotEmpty) {
      // Auto-aplica la primera promoción PROGRAMADA elegible (happy hour,
      // 2x1 por horario) — un descuento manual normal nunca se auto-aplica.
      // docs/promociones.md.
      final scheduled = activeDiscounts.where(isScheduledDiscount).toList();
      if (scheduled.isNotEmpty) {
        final promo = scheduled.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedDiscount = promo);
          _scrollToSelectedDiscount(promo.id);
        });
      }
    }

    // El IVA ahora se calcula por producto (4.5); la fila del resumen se muestra
    // cuando hay IVA computado, sin depender de una única tasa global.
    final taxIncludedDefault = settings['tax_included'] != 'false';
    final typeInfo = _orderTypes.firstWhere((t) => t.$1 == _orderType,
        orElse: () => _orderTypes[0]);
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
                            (_orderType == 'mesa' ? 'Sin mesa' : typeInfo.$2),
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
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _buildCartRows(symbol),
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
                    controller: _discScrollController,
                    scrollDirection: Axis.horizontal,
                    children: [
                      _DiscountPill(
                        key: _discKeys.putIfAbsent(null, () => GlobalKey()),
                        label: 'Sin desc.',
                        selected: _selectedDiscount == null,
                        onTap: () {
                          setState(() {
                            _selectedDiscount = null;
                            _autoDismissed = true;
                          });
                          _scrollToSelectedDiscount(null);
                        },
                      ),
                      ...activeDiscounts.map((d) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _DiscountPill(
                              key: _discKeys.putIfAbsent(
                                  d.id, () => GlobalKey()),
                              label: switch (d.type) {
                                'percentage' =>
                                  '${d.name} (${d.value.toInt()}%)',
                                '2x1' => '${d.name} (2x1)',
                                _ =>
                                  '${d.name} (${formatCurrency(d.value, symbol)})',
                              },
                              // Reloj = promoción programada (se auto-aplicó
                              // sola). docs/promociones.md.
                              icon: isScheduledDiscount(d)
                                  ? Icons.schedule
                                  : null,
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
                  _summaryRow(taxIncludedDefault ? 'IVA (incluido)' : 'IVA',
                      formatCurrency(_taxAmount, symbol)),
                if (_deliveryFee > 0)
                  _summaryRow(
                      _deliveryZoneName != null
                          ? 'Envío ($_deliveryZoneName)'
                          : 'Envío',
                      formatCurrency(_deliveryFee, symbol)),
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
                // División de cuenta (docs/division-cuenta.md): un solo botón
                // que ofrece las dos mecánicas (partes iguales / por
                // producto) — antes partes iguales solo vivía escondida
                // dentro del PaymentModal. Feedback de sitio 2026-07-22.
                if (_cart.length >= 2) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _showSplitChoice,
                      icon: const Icon(Icons.call_split, size: 16),
                      label: const Text('Dividir cuenta'),
                    ),
                  ),
                ],
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
              style: const TextStyle(fontSize: 13, color: LaTerciaColors.tan)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    children: [
                      Icon(t.$3,
                          size: 16,
                          color:
                              selected ? Colors.white : LaTerciaColors.cocoa),
                      const SizedBox(width: 6),
                      Text(
                        t.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? Colors.white : LaTerciaColors.cocoa,
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
          style: const TextStyle(fontSize: 13.5, color: LaTerciaColors.cocoa),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Tarjeta de combo en la cuadrícula del POS — versión simplificada de
/// `ProductCard` (sin imagen ni stock). `docs/combos.md`.
class _ComboCard extends StatelessWidget {
  final Combo combo;
  final String currencySymbol;
  final VoidCallback onTap;
  const _ComboCard({
    required this.combo,
    required this.currencySymbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: LaTerciaColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        LaTerciaColors.burntOrange,
                        LaTerciaColors.goldDark,
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Positioned(
                        right: -6,
                        top: -6,
                        child: Icon(Icons.fastfood,
                            size: 56, color: Colors.white24),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                          child: Text(
                            combo.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'DM Serif Display',
                              fontSize: 17,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          formatCurrency(combo.price, currencySymbol),
                          style: const TextStyle(
                            fontFamily: 'DM Serif Display',
                            fontSize: 19,
                            color: LaTerciaColors.darkBrown,
                          ),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: LaTerciaColors.burntOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado de un grupo de líneas de combo en el carrito: nombre + precio
/// total del paquete + botón para quitarlo completo. `docs/combos.md`.
class _ComboGroupHeader extends StatelessWidget {
  final String name;
  final double total;
  final String symbol;
  final VoidCallback onRemove;
  const _ComboGroupHeader({
    required this.name,
    required this.total,
    required this.symbol,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LaTerciaColors.burntOrange.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(
            color: LaTerciaColors.burntOrange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fastfood,
              size: 15, color: LaTerciaColors.burntOrange),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Combo: $name',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: LaTerciaColors.burntOrange)),
          ),
          Text(formatCurrency(total, symbol),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: LaTerciaColors.burntOrange)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 16, color: LaTerciaColors.burntOrange),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final bool selected;
  final VoidCallback onTap;
  // Ícono en vez del punto de color (usado por el chip "Combos").
  // docs/combos.md.
  final IconData? icon;
  const _CategoryChip({
    super.key,
    required this.label,
    this.dotColor,
    required this.selected,
    required this.onTap,
    this.icon,
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
              if (icon != null)
                Icon(icon,
                    size: 15,
                    color: selected ? Colors.white : LaTerciaColors.tan)
              else
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

/// Resumen de las N órdenes de una división por artículo, con UN botón
/// "Aceptar" — reemplaza mostrar un `ReceiptDialog` por persona (se
/// amontonaban con el pago de la siguiente). `docs/division-cuenta.md`.
class _SplitReceiptsSummaryDialog extends StatelessWidget {
  final List<OrderWithItems> orders;
  final String symbol;
  const _SplitReceiptsSummaryDialog(
      {required this.orders, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LaTerciaColors.creamAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: LaTerciaColors.success, size: 40),
              const SizedBox(height: 12),
              Text(
                '${orders.length} cuenta${orders.length == 1 ? '' : 's'} cobrada${orders.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontFamily: 'DM Serif Display',
                  fontSize: 20,
                  color: LaTerciaColors.darkBrown,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cada una ya imprimió su propio ticket.',
                style: TextStyle(fontSize: 12, color: LaTerciaColors.tan),
              ),
              const SizedBox(height: 16),
              for (final o in orders)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Orden #${o.order.orderNumber}',
                          style: const TextStyle(color: LaTerciaColors.cocoa)),
                      Text(
                        formatCurrency(o.order.total, symbol),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: LaTerciaColors.burntOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Aceptar'),
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
  // Ícono opcional (reloj = promoción programada). docs/promociones.md.
  final IconData? icon;
  const _DiscountPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 13,
                    color: selected ? Colors.white : LaTerciaColors.tan),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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

/// Asigna cada línea del carrito a una persona, para dividir la cuenta por
/// artículo. Devuelve un grupo de [CartItem] por persona (`Navigator.pop`
/// con la lista) o `null` si se cancela. `docs/division-cuenta.md`.
class _SplitByItemDialog extends StatefulWidget {
  final List<CartItem> cart;
  const _SplitByItemDialog({required this.cart});

  @override
  State<_SplitByItemDialog> createState() => _SplitByItemDialogState();
}

class _SplitByItemDialogState extends State<_SplitByItemDialog> {
  int _people = 2;
  // Un combo no se puede repartir entre varias personas — cada "unidad"
  // asignable es UNA línea normal, o TODAS las líneas de un mismo combo
  // juntas (`groupCartUnitsForSplit`, pura, en pricing.dart). Cada elemento
  // de `_units` es la lista de índices de `widget.cart` que esa unidad
  // agrupa. `docs/division-cuenta.md`.
  late final List<List<int>> _units = groupCartUnitsForSplit(widget.cart);
  // Índice de unidad → índice de persona (null = sin asignar).
  late final List<int?> _assignment = List<int?>.filled(_units.length, null);

  bool get _allAssigned => !_assignment.contains(null);

  void _removePerson() {
    setState(() {
      _people--;
      // Las líneas que apuntaban a la persona quitada vuelven a "sin asignar".
      for (var i = 0; i < _assignment.length; i++) {
        if (_assignment[i] != null && _assignment[i]! >= _people) {
          _assignment[i] = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dividir por artículo'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toca a quién le toca cada línea. Todas deben quedar asignadas. '
              'Un combo se asigna completo a una sola persona.',
              style: TextStyle(fontSize: 12.5, color: LaTerciaColors.tan),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Personas',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: LaTerciaColors.darkBrown)),
                const Spacer(),
                IconButton(
                  onPressed: _people > 2 ? _removePerson : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(
                  width: 28,
                  child: Text('$_people',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed:
                      _people < 10 ? () => setState(() => _people++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var u = 0; u < _units.length; u++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _unitLabel(_units[u]),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              children: [
                                for (var p = 0; p < _people; p++)
                                  ChoiceChip(
                                    label: Text('P${p + 1}'),
                                    labelStyle: const TextStyle(fontSize: 11.5),
                                    visualDensity: VisualDensity.compact,
                                    selected: _assignment[u] == p,
                                    onSelected: (_) =>
                                        setState(() => _assignment[u] = p),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _allAssigned
              ? () {
                  final groups = List.generate(_people, (_) => <CartItem>[]);
                  for (var u = 0; u < _units.length; u++) {
                    for (final i in _units[u]) {
                      groups[_assignment[u]!].add(widget.cart[i]);
                    }
                  }
                  Navigator.pop(context, groups);
                }
              : null,
          child: const Text('Dividir'),
        ),
      ],
    );
  }

  /// "2× Café" para una línea normal; "Combo: Combo 1 (completo)" para un
  /// combo — no muestra sus componentes por separado porque van juntos a la
  /// misma persona. `docs/division-cuenta.md`.
  String _unitLabel(List<int> unit) {
    final first = widget.cart[unit.first];
    if (first.comboInstanceId == null) {
      return '${first.quantity}× ${first.product.name}';
    }
    return '${first.comboName ?? 'Combo'} (completo)';
  }
}
