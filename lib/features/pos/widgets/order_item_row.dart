import 'package:flutter/material.dart';
import '../../../core/models/order_with_items.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class OrderItemRow extends StatefulWidget {
  final CartItem item;
  final String currencySymbol;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String?> onNoteChanged;

  const OrderItemRow({
    super.key,
    required this.item,
    required this.currencySymbol,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onNoteChanged,
  });

  @override
  State<OrderItemRow> createState() => _OrderItemRowState();
}

class _OrderItemRowState extends State<OrderItemRow> {
  bool _showNote = false;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.item.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LaTerciaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: LaTerciaColors.darkBrown,
                      ),
                    ),
                    for (final m in item.modifiers)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.includedModifierIds.contains(m.id)
                              ? '↳ ${m.name} (incluido)'
                              : '↳ ${m.name}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: LaTerciaColors.tan,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(item.lineTotal, widget.currencySymbol),
                    style: const TextStyle(
                      fontFamily: 'DM Serif Display',
                      fontSize: 16,
                      color: LaTerciaColors.darkBrown,
                    ),
                  ),
                  Text(
                    '${formatCurrency(item.unitPrice, widget.currencySymbol)} c/u',
                    style: const TextStyle(
                        fontSize: 10.5, color: LaTerciaColors.tan),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Stepper(
                quantity: item.quantity,
                onDecrement: item.quantity > 1
                    ? () => widget.onQuantityChanged(item.quantity - 1)
                    : null,
                onIncrement: () =>
                    widget.onQuantityChanged(item.quantity + 1),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showNote ? Icons.note : Icons.note_outlined,
                  size: 17,
                  color: _showNote
                      ? LaTerciaColors.burntOrange
                      : LaTerciaColors.tan,
                ),
                onPressed: () => setState(() => _showNote = !_showNote),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 17, color: LaTerciaColors.danger),
                onPressed: widget.onRemove,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
            ],
          ),
          if (_showNote)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextField(
                controller: _noteController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Nota del artículo...',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: widget.onNoteChanged,
              ),
            ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  const _Stepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LaTerciaColors.surfaceVariant,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove, onDecrement),
          SizedBox(
            width: 26,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: LaTerciaColors.darkBrown),
            ),
          ),
          _stepBtn(Icons.add, onIncrement),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon,
            size: 15,
            color:
                onTap == null ? LaTerciaColors.tanLight : LaTerciaColors.cocoa),
      ),
    );
  }
}
