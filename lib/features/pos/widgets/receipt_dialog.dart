import 'package:flutter/material.dart';
import '../../../core/database/database.dart';
import '../../../core/models/order_with_items.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pricing.dart';

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
    final businessName = settings['business_name'] ?? 'LaTercia';
    final footer = settings['receipt_footer'] ?? '¡Gracias por su visita!';
    final o = orderWithItems.order;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                businessName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                formatDateTime(o.createdAt),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                o.orderNumber,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                'Atendido por: ${employee.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(height: 24),
              ...orderWithItems.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                              '${item.quantity}× ${item.productName}',
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Text(
                          formatCurrency(
                              item.unitPrice * item.quantity, symbol),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              if (o.discountAmount > 0)
                _row('Descuento',
                    '-${formatCurrency(o.discountAmount, symbol)}',
                    color: Colors.green),
              if (o.taxAmount > 0)
                _row(
                    taxIsIncludedInTotal(
                      subtotal: o.subtotal,
                      discount: o.discountAmount,
                      tax: o.taxAmount,
                      total: o.total,
                    )
                        ? 'IVA incluido'
                        : 'IVA',
                    formatCurrency(o.taxAmount, symbol)),
              _row(
                'TOTAL',
                formatCurrency(o.total, symbol),
                bold: true,
              ),
              const SizedBox(height: 8),
              _row(
                payment.method == 'efectivo'
                    ? 'Efectivo recibido'
                    : 'Método',
                payment.method == 'efectivo'
                    ? formatCurrency(payment.amountTendered, symbol)
                    : payment.method,
              ),
              if (payment.changeGiven > 0)
                _row('Cambio',
                    formatCurrency(payment.changeGiven, symbol)),
              const Divider(height: 24),
              Text(
                footer,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
      fontSize: bold ? 16 : 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
