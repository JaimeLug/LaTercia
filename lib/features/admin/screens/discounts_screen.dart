import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/discounts_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/formatters.dart';

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
      appBar: AppBar(title: const Text('Descuentos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: discountsAsync.when(
        data: (discounts) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Tipo')),
              DataColumn(label: Text('Valor')),
              DataColumn(label: Text('Mínimo')),
              DataColumn(label: Text('Válido hasta')),
              DataColumn(label: Text('Activo')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: discounts.map((d) {
              return DataRow(cells: [
                DataCell(Text(d.name)),
                DataCell(Text(d.type == 'percentage'
                    ? 'Porcentaje'
                    : 'Fijo')),
                DataCell(Text(d.type == 'percentage'
                    ? '${d.value.toInt()}%'
                    : formatCurrency(d.value, symbol))),
                DataCell(Text(d.minOrderAmount > 0
                    ? formatCurrency(d.minOrderAmount, symbol)
                    : '-')),
                DataCell(Text(d.validUntil != null
                    ? formatDate(d.validUntil!)
                    : 'Sin límite')),
                DataCell(Switch(
                  value: d.active,
                  onChanged: (v) async {
                    await ref
                        .read(databaseProvider)
                        .discountsDao
                        .toggleActive(d.id, v);
                  },
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showForm(context, d),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .error),
                      onPressed: () async {
                        await ref
                            .read(databaseProvider)
                            .discountsDao
                            .deleteDiscount(d.id);
                      },
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
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
