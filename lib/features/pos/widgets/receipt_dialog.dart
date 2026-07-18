import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/database/database.dart';
import '../../../core/models/order_with_items.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pricing.dart';

/// Recibo grande en pantalla al terminar un cobro — inspirado en el formato
/// de ticket "papelería pro" (jerarquía tipográfica clara, divisores
/// punteados, total destacado) pero con la identidad visual de La Tercia.
class ReceiptDialog extends StatelessWidget {
  final OrderWithItems orderWithItems;
  final Payment payment;
  final Map<String, String> settings;
  final Employee employee;

  const ReceiptDialog({
    super.key,
    required this.orderWithItems,
    required this.payment,
    required this.settings,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = settings['currency_symbol'] ?? r'$';
    final businessName = settings['business_name'] ?? 'La Tercia';
    final slogan = settings['slogan'] ?? '';
    final footer = settings['receipt_footer'] ?? '¡Gracias por su visita!';
    final showEmployee = settings['receipt_show_employee'] != 'false';
    final showDiscount = settings['receipt_show_discount'] != 'false';
    final logoPath = settings['logo_path'];
    final o = orderWithItems.order;

    final ivaIncluido = o.taxAmount > 0 &&
        taxIsIncludedInTotal(
          subtotal: o.subtotal,
          discount: o.discountAmount,
          tax: o.taxAmount,
          total: o.total,
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: LaTerciaColors.creamAlt,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 30, 28, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Encabezado ───────────────────────────────────
                      if (logoPath != null &&
                          logoPath.isNotEmpty &&
                          File(logoPath).existsSync())
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(logoPath),
                                height: 56, width: 56, fit: BoxFit.cover),
                          ),
                        ),
                      if (logoPath != null &&
                          logoPath.isNotEmpty &&
                          File(logoPath).existsSync())
                        const SizedBox(height: 10),
                      Text(
                        businessName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'DM Serif Display',
                          fontSize: 28,
                          color: LaTerciaColors.darkBrown,
                        ),
                      ),
                      if (slogan.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          slogan,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: LaTerciaColors.tan,
                              letterSpacing: 0.3),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _MetaRow(
                        left: ('FOLIO', o.orderNumber),
                        right: ('FECHA', formatDateTime(o.createdAt)),
                      ),
                      if (showEmployee) ...[
                        const SizedBox(height: 6),
                        _MetaRow(
                          left: ('ATENDIÓ', employee.name),
                          right: ('TIPO', _typeLabel(o.type)),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const _DashedDivider(),
                      const SizedBox(height: 14),

                      // ─── Artículos ────────────────────────────────────
                      ...orderWithItems.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ItemRow(item: item, symbol: symbol),
                          )),

                      const _DashedDivider(),
                      const SizedBox(height: 14),

                      // ─── Totales ──────────────────────────────────────
                      _totalsRow('Subtotal',
                          formatCurrency(o.subtotal, symbol)),
                      if (showDiscount && o.discountAmount > 0)
                        _totalsRow(
                            'Descuento',
                            '-${formatCurrency(o.discountAmount, symbol)}',
                            color: LaTerciaColors.success),
                      if (o.taxAmount > 0)
                        _totalsRow(
                            ivaIncluido ? 'IVA incluido' : 'IVA',
                            formatCurrency(o.taxAmount, symbol)),
                      if (o.deliveryFee > 0)
                        _totalsRow(
                            o.deliveryZone != null
                                ? 'Envío (${o.deliveryZone})'
                                : 'Envío',
                            formatCurrency(o.deliveryFee, symbol)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: LaTerciaColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    color: LaTerciaColors.cocoa)),
                            Text(
                              formatCurrency(o.total, symbol),
                              style: const TextStyle(
                                fontFamily: 'DM Serif Display',
                                fontSize: 26,
                                color: LaTerciaColors.burntOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _totalsRow(
                        payment.method == 'efectivo'
                            ? 'Efectivo recibido'
                            : 'Método de pago',
                        payment.method == 'efectivo'
                            ? formatCurrency(payment.amountTendered, symbol)
                            : _methodLabel(payment.method),
                      ),
                      if (payment.changeGiven > 0)
                        _totalsRow('Cambio',
                            formatCurrency(payment.changeGiven, symbol)),
                      if (payment.tipAmount > 0)
                        _totalsRow('Propina',
                            formatCurrency(payment.tipAmount, symbol),
                            color: LaTerciaColors.goldDark),
                      const SizedBox(height: 18),
                      const _DashedDivider(),
                      const SizedBox(height: 16),
                      Text(
                        footer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: LaTerciaColors.tan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 26),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: LaTerciaColors.burntOrange),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar',
                        style: TextStyle(fontSize: 15.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalsRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13.5, color: LaTerciaColors.tan)),
          Text(value,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: color ?? LaTerciaColors.cocoa)),
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'mesa' => 'Mesa',
        'para_llevar' => 'Para llevar',
        'delivery' => 'Delivery',
        _ => type,
      };

  String _methodLabel(String method) => switch (method) {
        'efectivo' => 'Efectivo',
        'tarjeta' => 'Tarjeta',
        'transferencia' => 'Transferencia',
        _ => method,
      };
}

/// Cantidad + nombre + modificadores/nota + precio de línea, con la misma
/// jerarquía visual que usa el KDS para las tarjetas de cocina.
class _ItemRow extends StatelessWidget {
  final OrderItem item;
  final String symbol;
  const _ItemRow({required this.item, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final mods = _parseModifiers(item.modifiersJson);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: LaTerciaColors.burntOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text('${item.quantity}×',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: LaTerciaColors.burntOrange)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: LaTerciaColors.darkBrown)),
              for (final m in mods)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                      m.included ? '+ ${m.name} (incluido)' : '+ ${m.name}',
                      style: const TextStyle(
                          fontSize: 12, color: LaTerciaColors.tan)),
                ),
              if (item.itemNote != null && item.itemNote!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text('* ${item.itemNote!.trim()}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: LaTerciaColors.tan)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatCurrency(item.unitPrice * item.quantity, symbol),
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: LaTerciaColors.cocoa),
        ),
      ],
    );
  }
}

class _ParsedModifier {
  final String name;
  final bool included;
  const _ParsedModifier(this.name, {this.included = false});
}

List<_ParsedModifier> _parseModifiers(String? modifiersJson) {
  if (modifiersJson == null || modifiersJson.isEmpty) return const [];
  try {
    final decoded = jsonDecode(modifiersJson);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((m) => _ParsedModifier((m['name'] ?? '').toString(),
            included: m['included'] == true))
        .where((m) => m.name.isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
}

/// Par etiqueta/valor a la izquierda y a la derecha del encabezado — folio,
/// fecha, atendió, tipo de orden.
class _MetaRow extends StatelessWidget {
  final (String, String) left;
  final (String, String) right;
  const _MetaRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _metaCell(left.$1, left.$2)),
        Expanded(child: _metaCell(right.$1, right.$2, alignEnd: true)),
      ],
    );
  }

  Widget _metaCell(String label, String value, {bool alignEnd = false}) {
    final crossAxis =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: LaTerciaColors.tanLight)),
        const SizedBox(height: 2),
        Text(value,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: LaTerciaColors.cocoa)),
      ],
    );
  }
}

/// Línea punteada horizontal — evoca el corte de un ticket térmico real.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashedLinePainter(),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LaTerciaColors.border
      ..strokeWidth = 1.4;
    const dashWidth = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
