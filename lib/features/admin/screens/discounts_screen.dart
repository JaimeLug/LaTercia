import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/discounts_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/admin_panel.dart';

class DiscountsScreen extends ConsumerStatefulWidget {
  const DiscountsScreen({super.key});

  @override
  ConsumerState<DiscountsScreen> createState() =>
      _DiscountsScreenState();
}

class _DiscountsScreenState extends ConsumerState<DiscountsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final discountsAsync = ref.watch(discountsProvider);

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Descuentos'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: LaTerciaColors.burntOrange,
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: discountsAsync.when(
        data: (discounts) {
          if (discounts.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.local_offer_outlined,
              message: 'Sin descuentos todavía.',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AdminPanel(
              child: Column(
                children: [
                  const AdminHeaderRow(cells: [
                    Expanded(flex: 3, child: Text('NOMBRE')),
                    Expanded(flex: 2, child: Text('TIPO')),
                    Expanded(flex: 2, child: Text('VALOR')),
                    Expanded(flex: 2, child: Text('MÍNIMO')),
                    Expanded(flex: 2, child: Text('VÁLIDO HASTA')),
                    Expanded(flex: 1, child: Text('ACTIVO')),
                    SizedBox(width: 88, child: Text('ACCIONES')),
                  ]),
                  ...discounts.asMap().entries.map((entry) {
                    final d = entry.value;
                    final isLast = entry.key == discounts.length - 1;
                    return AdminRow(
                      isLast: isLast,
                      cells: [
                        Expanded(
                          flex: 3,
                          child: Text(d.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: LaTerciaColors.darkBrown)),
                        ),
                        Expanded(
                            flex: 2,
                            child: Text(
                                d.type == 'percentage' ? 'Porcentaje' : 'Fijo')),
                        Expanded(
                          flex: 2,
                          child: Text(
                              d.type == 'percentage'
                                  ? '${d.value.toInt()}%'
                                  : formatCurrency(d.value, symbol),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: LaTerciaColors.success)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(d.minOrderAmount > 0
                              ? formatCurrency(d.minOrderAmount, symbol)
                              : '—'),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                              d.validUntil != null
                                  ? formatDate(d.validUntil!)
                                  : 'Sin límite',
                              style: const TextStyle(
                                  fontSize: 12.5, color: LaTerciaColors.tan)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Switch(
                            value: d.active,
                            activeColor: LaTerciaColors.burntOrange,
                            onChanged: (v) async {
                              await ref
                                  .read(databaseProvider)
                                  .discountsDao
                                  .toggleActive(d.id, v);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 88,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: LaTerciaColors.tan),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _showForm(context, d),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: LaTerciaColors.danger),
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  await ref
                                      .read(databaseProvider)
                                      .discountsDao
                                      .deleteDiscount(d.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        },
        loading: () => adminLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showForm(
      BuildContext context, Discount? discount) async {
    await showDialog(
      context: context,
      builder: (_) => _DiscountFormDialog(discount: discount),
    );
  }
}

class _DiscountFormDialog extends ConsumerStatefulWidget {
  final Discount? discount;
  const _DiscountFormDialog({this.discount});

  @override
  ConsumerState<_DiscountFormDialog> createState() =>
      _DiscountFormDialogState();
}

class _DiscountFormDialogState
    extends ConsumerState<_DiscountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _minCtrl;
  String _type = 'percentage';
  DateTime? _validFrom;
  DateTime? _validUntil;

  @override
  void initState() {
    super.initState();
    final d = widget.discount;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _valueCtrl =
        TextEditingController(text: d != null ? '${d.value}' : '');
    _minCtrl = TextEditingController(
        text: d != null ? '${d.minOrderAmount}' : '0');
    _type = d?.type ?? 'percentage';
    _validFrom = d?.validFrom;
    _validUntil = d?.validUntil;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.discount == null ? 'Nuevo descuento' : 'Editar descuento'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nombre *'),
                validator: (v) =>
                    v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Porcentaje (%)')),
                  DropdownMenuItem(
                      value: 'fixed', child: Text('Fijo (\$)')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _valueCtrl,
                decoration: InputDecoration(
                    labelText: _type == 'percentage'
                        ? 'Porcentaje *'
                        : 'Monto *'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _minCtrl,
                decoration: const InputDecoration(
                    labelText: 'Mínimo de orden'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _validFrom ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) {
                          setState(() => _validFrom = d);
                        }
                      },
                      child: Text(_validFrom != null
                          ? 'Desde: ${formatDate(_validFrom!)}'
                          : 'Fecha inicio'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate:
                              _validUntil ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) {
                          setState(() => _validUntil = d);
                        }
                      },
                      child: Text(_validUntil != null
                          ? 'Hasta: ${formatDate(_validUntil!)}'
                          : 'Fecha fin'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);
    final companion = DiscountsCompanion(
      id: widget.discount != null
          ? Value(widget.discount!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      type: Value(_type),
      value: Value(double.parse(_valueCtrl.text)),
      minOrderAmount:
          Value(double.tryParse(_minCtrl.text) ?? 0),
      validFrom: Value(_validFrom),
      validUntil: Value(_validUntil),
    );

    if (widget.discount == null) {
      await db.discountsDao.insertDiscount(companion);
    } else {
      await db.discountsDao.updateDiscount(companion);
    }
    if (mounted) Navigator.pop(context);
  }
}
