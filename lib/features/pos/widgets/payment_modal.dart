import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/order_with_items.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/services/checkout_service.dart';
import '../../../core/services/print_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pricing.dart' show splitEvenly;
import 'factura_capture_dialog.dart';
import 'receipt_dialog.dart';

const _methods = [
  ('efectivo', 'Efectivo', Icons.payments_outlined),
  ('tarjeta', 'Tarjeta', Icons.credit_card),
  ('transferencia', 'Transferencia', Icons.swap_horiz),
];

String _methodLabel(String method) {
  for (final m in _methods) {
    if (m.$1 == method) return m.$2;
  }
  return method;
}

class PaymentModal extends ConsumerStatefulWidget {
  final double total;

  /// Cobra la orden con uno o más pagos (mixtos). docs/ventas-cobro-turnos.md
  /// §Pagos.
  final Future<OrderWithItems?> Function({
    required List<PaymentDraft> payments,
  }) onCheckout;

  /// Si además imprime la comanda tras cobrar. `false` en el cobro diferido
  /// (ya se imprimió al enviar a cocina). docs/ordenes-y-cocina.md.
  final bool printKitchenComanda;

  /// División de cuenta por artículo: "Cuenta de la persona 1 de 3" arriba
  /// del monto, para que quede claro a quién le toca este cobro.
  /// `docs/division-cuenta.md`.
  final String? personLabel;

  /// Abre el modal y de inmediato pide "¿entre cuántas personas?" (partes
  /// iguales) — para cuando el cajero ya eligió esa opción desde el diálogo
  /// de "Dividir cuenta" del carrito, en vez de tener que volver a tocar el
  /// botón "Dividir cuenta" de aquí adentro. `docs/division-cuenta.md`.
  final bool autoStartEvenSplit;

  const PaymentModal({
    super.key,
    required this.total,
    required this.onCheckout,
    this.printKitchenComanda = true,
    this.personLabel,
    this.autoStartEvenSplit = false,
  });

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  String _method = 'efectivo';
  final _receivedController = TextEditingController();
  final _referenceController = TextEditingController();
  final _tipController = TextEditingController();
  bool _processing = false;
  // Flujo A: si el cliente pide factura, tras cobrar se capturan sus datos
  // fiscales y se congela la factura. docs/facturacion.md §"Flujo A".
  bool _requiereFactura = false;
  // Propina (4.1). null = ningún preset seleccionado (monto libre o sin propina).
  int? _tipPreset;
  // Pagos parciales ya agregados (pago mixto, 4.2). El tramo en edición vive en
  // los controllers de arriba y se agrega/confirma con los botones.
  final List<PaymentDraft> _committed = [];
  // División de cuenta en partes iguales (docs/division-cuenta.md): reusa
  // exactamente el mecanismo de pago mixto de arriba — solo precarga cada
  // tramo con el monto que le toca a esa persona.
  List<double>? _evenSplit;
  int _evenSplitCursor = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoStartEvenSplit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startEvenSplit());
    }
  }

  @override
  void dispose() {
    _receivedController.dispose();
    _referenceController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  double get _tip {
    final t = double.tryParse(_tipController.text.replaceAll(',', '.')) ?? 0;
    return t < 0 ? 0 : t;
  }

  /// Lo que el cliente paga: la venta más la propina. La propina NO altera el
  /// total de la venta (se guarda como línea aparte en el/los pago(s)).
  double get _grandTotal => widget.total + _tip;

  /// Cuánto del gran total ya cubren los tramos agregados (recibido − cambio).
  double get _committedApplied =>
      _committed.fold(0.0, (a, d) => a + d.amountTendered - d.changeGiven);

  /// Saldo pendiente que el tramo en edición debe cubrir.
  double get _remaining =>
      (_grandTotal - _committedApplied).clamp(0.0, double.infinity);

  double get _receivedAmount =>
      double.tryParse(_receivedController.text.replaceAll(',', '.')) ?? 0;

  bool get _isCash => _method == 'efectivo';

  /// Cambio del tramo actual: solo en efectivo y solo sobre lo que excede el
  /// saldo (el cambio se da únicamente sobre el tramo en efectivo, 4.2).
  double get _currentChange =>
      _isCash ? (_receivedAmount - _remaining).clamp(0.0, double.infinity) : 0;

  /// Cuánto del saldo cubre el tramo actual (sin contar el cambio).
  double get _currentApplied {
    final applied = _receivedAmount - _currentChange;
    return applied.clamp(0.0, _remaining);
  }

  /// El tramo actual es parcial: aporta algo pero no cierra el saldo.
  bool get _isPartial =>
      _receivedAmount > 0 && !_reachesCents(_currentApplied, _remaining);

  /// El tramo actual cierra el cobro (cubre el saldo pendiente).
  bool get _closesBalance =>
      _centsOf(_remaining) <= 0 || _reachesCents(_receivedAmount, _remaining);

  /// Redondea a centavos (evita arrastrar el ruido de punto flotante de un
  /// precio prorrateado — ej. un combo — hasta el número entero de centavos
  /// que de verdad importa para cobrar). `docs/division-cuenta.md`.
  int _centsOf(double amount) => (amount * 100).round();

  /// `true` si [received] alcanza para cubrir [remaining] A NIVEL DE CENTAVO
  /// — comparar los doubles crudos con una tolerancia de 0.0001 no basta: un
  /// precio prorrateado de combo puede quedar a medio centavo (ej. $35.585),
  /// y "Exacto" (que redondea a "35.59" en el campo) terminaba pareciendo
  /// insuficiente. `docs/division-cuenta.md`.
  bool _reachesCents(double received, double remaining) =>
      _centsOf(received) >= _centsOf(remaining);

  void _setReceived(double amount) {
    _receivedController.text = amount.toStringAsFixed(2);
    setState(() {});
  }

  void _setTipPreset(int percent) {
    setState(() {
      _tipPreset = percent;
      _tipController.text = (widget.total * percent / 100).toStringAsFixed(2);
    });
  }

  void _clearTip() {
    setState(() {
      _tipPreset = null;
      _tipController.clear();
    });
  }

  /// Agrega el tramo actual como pago parcial y deja el saldo restante listo
  /// para el siguiente método.
  void _addPartial() {
    if (!_isPartial) return;
    setState(() {
      _committed.add(PaymentDraft(
        method: _method,
        amountTendered: _currentApplied, // parcial: sin cambio
        changeGiven: 0,
        reference: _referenceController.text.isEmpty
            ? null
            : _referenceController.text,
      ));
      _receivedController.clear();
      _referenceController.clear();
      _method = 'efectivo';
      // Si venimos de "Dividir cuenta", precarga el monto de la siguiente
      // parte. docs/division-cuenta.md.
      final split = _evenSplit;
      if (split != null && _evenSplitCursor < split.length - 1) {
        _evenSplitCursor++;
        _receivedController.text = split[_evenSplitCursor].toStringAsFixed(2);
      }
    });
  }

  /// Pide el número de personas y precarga el monto de la primera parte en el
  /// campo de "Recibido" — el cajero sigue el flujo de pago mixto de siempre.
  /// `docs/division-cuenta.md`.
  Future<void> _startEvenSplit() async {
    final parts = await showDialog<int>(
      context: context,
      builder: (_) => const _SplitPartsDialog(),
    );
    if (parts == null || parts < 2) return;
    final shares = splitEvenly(_grandTotal, parts);
    setState(() {
      _evenSplit = shares;
      _evenSplitCursor = 0;
      _receivedController.text = shares.first.toStringAsFixed(2);
    });
  }

  void _removeCommitted(int index) {
    setState(() => _committed.removeAt(index));
  }

  /// Ensambla los pagos (parciales + el tramo que cierra) y adjunta la propina
  /// al tramo que cierra. docs/ventas-cobro-turnos.md §Pagos.
  List<PaymentDraft> _buildDrafts() {
    final drafts = <PaymentDraft>[..._committed];
    // Tramo que cierra el saldo. En tarjeta/transferencia no hay cambio, así que
    // lo entregado se limita al saldo; en efectivo se registra el cambio.
    final tendered = _isCash ? _receivedAmount : _remaining;
    if (_remaining > 0.0001 || drafts.isEmpty) {
      drafts.add(PaymentDraft(
        method: _method,
        amountTendered: tendered,
        changeGiven: _isCash ? _currentChange : 0,
        reference: _referenceController.text.isEmpty
            ? null
            : _referenceController.text,
      ));
    }
    if (_tip > 0 && drafts.isNotEmpty) {
      final last = drafts.last;
      drafts[drafts.length - 1] = PaymentDraft(
        method: last.method,
        amountTendered: last.amountTendered,
        changeGiven: last.changeGiven,
        tipAmount: _tip,
        reference: last.reference,
      );
    }
    return drafts;
  }

  Future<void> _confirm() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      await _doConfirm();
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cobrar: $e')),
        );
      }
    }
  }

  Future<void> _doConfirm() async {
    final db = ref.read(databaseProvider);
    final settings = ref.read(settingsProvider).valueOrNull ?? {};
    final employee = ref.read(sessionProvider);

    final drafts = _buildDrafts();

    // Cobra en una transacción atómica. docs/ventas-cobro-turnos.md.
    final order = await widget.onCheckout(payments: drafts);
    if (order == null) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear la orden.')),
        );
      }
      return;
    }

    // Flujo A: si el cliente pidió factura, captura sus datos fiscales y
    // congela la factura individual (o la marca "faltan datos" si se guarda
    // sin RFC, para completarla después). docs/facturacion.md §"Flujo A".
    if (_requiereFactura && mounted) {
      await showFacturaCapture(context, ref, order: order.order);
    }

    // Fetch payments for receipt (usa el último tramo como referencia).
    final payments = await db.paymentsDao.getPaymentsForOrder(order.order.id);
    final payment = payments.last;
    final anyCash = drafts.any((d) => d.method == 'efectivo');

    // Hardware best-effort, DESPUÉS del commit de la venta: la impresión y la
    // gaveta nunca deben romper ni bloquear el cobro. Todo detrás de flags.
    final printService = ref.read(printServiceProvider);
    if (employee != null) {
      // No await bloqueante sobre el resultado: la cola reintenta y avisa por
      // su cuenta si la impresora no responde.
      unawaited(printService.printSaleAndKitchen(
        order: order.order,
        items: order.items,
        payment: payment,
        settings: settings,
        employee: employee,
        includeKitchen: widget.printKitchenComanda,
      ));
    }
    // Apertura automática de la gaveta si algún tramo fue en efectivo.
    if (anyCash &&
        printService.drawerEnabled(settings) &&
        settings['gaveta_auto_efectivo'] != 'false') {
      unawaited(printService.openDrawer(settings));
      await ref.read(auditServiceProvider).log(
        employeeId: employee?.id,
        action: 'apertura_gaveta',
        entity: 'order',
        entityId: order.order.id,
        detail: {'auto': true, 'orderId': order.order.id},
      );
    }

    if (mounted) {
      Navigator.pop(context);
      await showDialog(
        context: context,
        builder: (_) => ReceiptDialog(
          orderWithItems: order,
          payment: payment,
          settings: settings,
          employee: employee!,
        ),
      );
      // Re-bloqueo opcional tras la venta (`lock_tras_venta`), después del
      // recibo para no interrumpir el cobro.
      if (settings['lock_tras_venta'] == 'true' && mounted) {
        ref.read(sessionProvider.notifier).state = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final tipsEnabled = settings['propinas_activas'] == 'true';
    final hasSplit = _committed.isNotEmpty;

    return Dialog(
      backgroundColor: LaTerciaColors.creamAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.personLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: LaTerciaColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(widget.personLabel!,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: LaTerciaColors.burntOrange)),
                    ),
                  ),
                // Dividir cuenta en partes iguales (docs/division-cuenta.md):
                // solo antes de empezar a agregar tramos, para no mezclar con
                // un pago mixto ya en curso, y no dentro de un cobro que ya es
                // "la cuenta de una persona" del split por artículo.
                if (_committed.isEmpty &&
                    _evenSplit == null &&
                    widget.personLabel == null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _processing ? null : _startEvenSplit,
                      icon: const Icon(Icons.groups_outlined, size: 16),
                      label: const Text('Dividir cuenta'),
                    ),
                  ),
                Text(hasSplit ? 'SALDO PENDIENTE' : 'TOTAL A PAGAR',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: LaTerciaColors.tan,
                    )),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(hasSplit ? _remaining : _grandTotal, symbol),
                  style: const TextStyle(
                    fontFamily: 'DM Serif Display',
                    fontSize: 34,
                    color: LaTerciaColors.burntOrange,
                  ),
                ),
                if (_evenSplit != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Dividido entre ${_evenSplit!.length} — '
                      'parte ${_evenSplitCursor + 1} de ${_evenSplit!.length}',
                      style: const TextStyle(
                          fontSize: 11.5, color: LaTerciaColors.tan),
                    ),
                  ),
                if (tipsEnabled && !hasSplit && _tip > 0)
                  Text(
                      'Venta ${formatCurrency(widget.total, symbol)} + '
                      'propina ${formatCurrency(_tip, symbol)}',
                      style: const TextStyle(
                          fontSize: 11.5, color: LaTerciaColors.tan)),
                if (_committed.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCommittedList(symbol),
                ],
                const SizedBox(height: 20),
                Row(
                  children: _methods
                      .map((m) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: m == _methods.last ? 0 : 8),
                              child: _MethodTile(
                                icon: m.$3,
                                label: m.$2,
                                selected: _method == m.$1,
                                onTap: () => setState(() => _method = m.$1),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                if (tipsEnabled && !hasSplit) ...[
                  const SizedBox(height: 18),
                  _buildTip(symbol),
                ],
                const SizedBox(height: 20),
                if (_isCash) _buildCash(symbol),
                if (_method == 'tarjeta')
                  _buildAmountAndReference(symbol, 'Últimos 4 dígitos, etc.'),
                if (_method == 'transferencia')
                  _buildAmountAndReference(symbol, 'Número de confirmación'),
                const SizedBox(height: 14),
                // Botón para agregar el tramo actual como pago parcial.
                if (_isPartial)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _addPartial,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                          'Agregar ${_methodLabel(_method).toLowerCase()} '
                          '${formatCurrency(_currentApplied, symbol)} y seguir'),
                    ),
                  ),
                const SizedBox(height: 8),
                // Flujo A: al confirmar, si está marcado, se piden los datos
                // fiscales y se congela la factura. docs/facturacion.md.
                _buildRequiereFactura(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            _processing ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed:
                            _closesBalance && !_processing ? _confirm : null,
                        child: _processing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(hasSplit
                                ? 'Cobrar resto y confirmar'
                                : 'Confirmar pago'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tile "Requiere factura" con el mismo lenguaje visual del modal (redondeado,
  /// borde burntOrange al activarse) e indicador circular — evita el checkbox
  /// cuadrado default de Material. docs/facturacion.md §"Flujo A".
  Widget _buildRequiereFactura() {
    final on = _requiereFactura;
    return Material(
      color: on ? LaTerciaColors.surfaceVariant : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap:
            _processing ? null : () => setState(() => _requiereFactura = !on),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: on ? LaTerciaColors.burntOrange : LaTerciaColors.border,
              width: on ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? LaTerciaColors.burntOrange : Colors.transparent,
                  border: Border.all(
                    color: on ? LaTerciaColors.burntOrange : LaTerciaColors.tan,
                    width: 1.6,
                  ),
                ),
                child: on
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Requiere factura (CFDI)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color:
                        on ? LaTerciaColors.burntOrange : LaTerciaColors.cocoa,
                  ),
                ),
              ),
              Icon(Icons.receipt_long_outlined,
                  size: 18,
                  color: on ? LaTerciaColors.burntOrange : LaTerciaColors.tan),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommittedList(String symbol) {
    return Column(
      children: [
        for (var i = 0; i < _committed.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: LaTerciaColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_methodLabel(_committed[i].method)} · '
                    '${formatCurrency(_committed[i].amountTendered, symbol)}',
                    style: const TextStyle(
                        fontSize: 13, color: LaTerciaColors.cocoa),
                  ),
                ),
                InkWell(
                  onTap: _processing ? null : () => _removeCommitted(i),
                  child: const Icon(Icons.close,
                      size: 16, color: LaTerciaColors.tan),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTip(String symbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('PROPINA',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: LaTerciaColors.tan)),
        const SizedBox(height: 6),
        Row(
          children: [
            _tipPresetBtn('Sin', _tipPreset == null && _tip == 0, _clearTip),
            const SizedBox(width: 6),
            _tipPresetBtn('10%', _tipPreset == 10, () => _setTipPreset(10)),
            const SizedBox(width: 6),
            _tipPresetBtn('15%', _tipPreset == 15, () => _setTipPreset(15)),
            const SizedBox(width: 6),
            _tipPresetBtn('20%', _tipPreset == 20, () => _setTipPreset(20)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _tipController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (_) => setState(() => _tipPreset = null),
          style: const TextStyle(fontSize: 15, color: LaTerciaColors.darkBrown),
          decoration: InputDecoration(
            isDense: true,
            prefixText: '$symbol ',
            labelText: 'Propina (monto libre)',
            hintText: '0.00',
          ),
        ),
      ],
    );
  }

  Widget _tipPresetBtn(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          backgroundColor:
              selected ? LaTerciaColors.surfaceVariant : Colors.transparent,
          side: BorderSide(
            color:
                selected ? LaTerciaColors.burntOrange : LaTerciaColors.border,
            width: selected ? 1.6 : 1,
          ),
          foregroundColor:
              selected ? LaTerciaColors.burntOrange : LaTerciaColors.cocoa,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12.5)),
      ),
    );
  }

  Widget _buildCash(String symbol) {
    final cashOk = _receivedAmount >= _remaining - 0.0001;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('RECIBIDO',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: LaTerciaColors.tan)),
        const SizedBox(height: 6),
        TextField(
          controller: _receivedController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            fontFamily: 'DM Serif Display',
            fontSize: 22,
            color: LaTerciaColors.darkBrown,
          ),
          decoration: InputDecoration(
            prefixText: '$symbol ',
            prefixStyle: const TextStyle(
              fontFamily: 'DM Serif Display',
              fontSize: 22,
              color: LaTerciaColors.darkBrown,
            ),
            hintText: '0.00',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _quickAmountBtn('$symbol 100', () => _setReceived(100)),
            const SizedBox(width: 8),
            _quickAmountBtn('$symbol 200', () => _setReceived(200)),
            const SizedBox(width: 8),
            _quickAmountBtn('$symbol 500', () => _setReceived(500)),
            const SizedBox(width: 8),
            _quickAmountBtn('Exacto', () => _setReceived(_remaining)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cashOk
                ? LaTerciaColors.successBg
                : LaTerciaColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cambio',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: LaTerciaColors.cocoa)),
              Text(
                formatCurrency(_currentChange, symbol),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cashOk ? LaTerciaColors.success : LaTerciaColors.tan,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickAmountBtn(String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: LaTerciaColors.border),
          foregroundColor: LaTerciaColors.cocoa,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12.5)),
      ),
    );
  }

  /// Campo de monto (para cubrir parcial o total) + referencia, para pagos con
  /// tarjeta/transferencia. El monto arranca en el saldo pendiente.
  Widget _buildAmountAndReference(String symbol, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _receivedController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixText: '$symbol ',
            labelText: 'Monto',
            hintText: _remaining.toStringAsFixed(2),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _setReceived(_remaining),
            child: Text('Cubrir saldo ${formatCurrency(_remaining, symbol)}'),
          ),
        ),
        TextField(
          controller: _referenceController,
          decoration: InputDecoration(
            labelText: 'Referencia (opcional)',
            hintText: hint,
          ),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LaTerciaColors.surfaceVariant : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected ? LaTerciaColors.burntOrange : LaTerciaColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color: selected
                      ? LaTerciaColors.burntOrange
                      : LaTerciaColors.tan),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? LaTerciaColors.burntOrange
                      : LaTerciaColors.cocoa,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pide el número de personas para dividir la cuenta en partes iguales.
/// `docs/division-cuenta.md`.
class _SplitPartsDialog extends StatefulWidget {
  const _SplitPartsDialog();

  @override
  State<_SplitPartsDialog> createState() => _SplitPartsDialogState();
}

class _SplitPartsDialogState extends State<_SplitPartsDialog> {
  int _parts = 2;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dividir cuenta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('¿Entre cuántas personas?',
              style: TextStyle(color: LaTerciaColors.tan)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _parts > 2 ? () => setState(() => _parts--) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 64,
                child: Text('$_parts',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'DM Serif Display',
                        fontSize: 28,
                        color: LaTerciaColors.darkBrown)),
              ),
              IconButton.filledTonal(
                onPressed: _parts < 20 ? () => setState(() => _parts++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _parts),
          child: const Text('Dividir'),
        ),
      ],
    );
  }
}
