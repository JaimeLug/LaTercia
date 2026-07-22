import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/discounts_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/pricing.dart' show isScheduledDiscount;
import '../widgets/admin_panel.dart';
import '../widgets/category_scope_picker.dart';

/// Nombres cortos de los días (índice = `DateTime.weekday`, 1=lun..7=dom).
const _dayLabels = ['', 'L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _dayFullLabels = [
  '',
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Resume la programación de [d] para la lista ("Lun-Vie 15:00-17:00"), o la
/// vigencia por fecha si no está programada. `docs/promociones.md`.
String discountScheduleLabel(Discount d) {
  if (!isScheduledDiscount(d)) {
    return d.validUntil != null
        ? 'Hasta ${formatDate(d.validUntil!)}'
        : 'Sin límite';
  }
  final parts = <String>[];
  final days = (d.daysOfWeek ?? '')
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .where((n) => n >= 1 && n <= 7)
      .toList()
    ..sort();
  if (days.isNotEmpty) {
    parts.add(days.map((n) => _dayLabels[n]).join(''));
  }
  if ((d.startTime ?? '').isNotEmpty && (d.endTime ?? '').isNotEmpty) {
    parts.add('${d.startTime}-${d.endTime}');
  }
  return parts.join(' ');
}

class DiscountsScreen extends ConsumerStatefulWidget {
  const DiscountsScreen({super.key});

  @override
  ConsumerState<DiscountsScreen> createState() => _DiscountsScreenState();
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
                    Expanded(flex: 3, child: Text('VIGENCIA')),
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
                          child: Text(switch (d.type) {
                            'percentage' => 'Porcentaje',
                            '2x1' => '2x1',
                            _ => 'Fijo',
                          }),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                              d.type == '2x1'
                                  ? '—'
                                  : d.type == 'percentage'
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
                          flex: 3,
                          child: Row(
                            children: [
                              if (isScheduledDiscount(d))
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.schedule,
                                      size: 14, color: LaTerciaColors.gold),
                                ),
                              Flexible(
                                child: Text(discountScheduleLabel(d),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        color: LaTerciaColors.tan)),
                              ),
                            ],
                          ),
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

  Future<void> _showForm(BuildContext context, Discount? discount) async {
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

class _DiscountFormDialogState extends ConsumerState<_DiscountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _minCtrl;
  String _type = 'percentage';
  DateTime? _validFrom;
  DateTime? _validUntil;
  // Promociones programadas (docs/promociones.md): días de la semana
  // (DateTime.weekday, 1=lun..7=dom), ventana de hora y alcance por categoría.
  Set<int> _days = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Set<String> _scopeCategories = {};

  @override
  void initState() {
    super.initState();
    final d = widget.discount;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _valueCtrl = TextEditingController(text: d != null ? '${d.value}' : '');
    _minCtrl =
        TextEditingController(text: d != null ? '${d.minOrderAmount}' : '0');
    _type = d?.type ?? 'percentage';
    _validFrom = d?.validFrom;
    _validUntil = d?.validUntil;
    _days = (d?.daysOfWeek ?? '')
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((n) => n >= 1 && n <= 7)
        .toSet();
    _startTime = _parseTime(d?.startTime);
    _endTime = _parseTime(d?.endTime);
    _scopeCategories = (d?.categoryScope ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScope() async {
    final categories =
        await ref.read(databaseProvider).categoriesDao.getAllCategories();
    if (!mounted) return;
    final result = await showCategoryScopePicker(
      context,
      categories: categories.map((c) => c.name).toList(),
      initialSelected: _scopeCategories,
    );
    if (result != null) setState(() => _scopeCategories = result);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
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
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                      value: 'percentage', child: Text('Porcentaje (%)')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fijo (\$)')),
                  DropdownMenuItem(
                      value: '2x1', child: Text('2x1 (cada 2, 1 gratis)')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              // 2x1 no tiene monto: el "valor" es la mecánica misma.
              // docs/promociones.md.
              if (_type != '2x1') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _valueCtrl,
                  decoration: InputDecoration(
                      labelText:
                          _type == 'percentage' ? 'Porcentaje *' : 'Monto *'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Requerido';
                    if (double.tryParse(v) == null) {
                      return 'Número inválido';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 8),
              TextFormField(
                controller: _minCtrl,
                decoration: const InputDecoration(labelText: 'Mínimo de orden'),
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
                          initialDate: _validUntil ?? DateTime.now(),
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
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Promoción programada (opcional)',
                    style: Theme.of(context).textTheme.labelMedium),
              ),
              const Text(
                'Si eliges días y/o hora, se auto-aplica sola en el POS '
                'cuando corresponde (ej. happy hour).',
                style: TextStyle(fontSize: 12, color: LaTerciaColors.tan),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var day = 1; day <= 7; day++)
                    FilterChip(
                      label: Text(_dayLabels[day]),
                      tooltip: _dayFullLabels[day],
                      selected: _days.contains(day),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _days.add(day);
                        } else {
                          _days.remove(day);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(isStart: true),
                      child: Text(_startTime != null
                          ? 'Desde: ${_formatTime(_startTime!)}'
                          : 'Hora inicio'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(isStart: false),
                      child: Text(_endTime != null
                          ? 'Hasta: ${_formatTime(_endTime!)}'
                          : 'Hora fin'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickScope,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Alcance por categoría',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: _scopeCategories.isEmpty
                      ? const Text('Todas las categorías',
                          style: TextStyle(color: LaTerciaColors.tan))
                      : Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _scopeCategories
                              .map((c) => Chip(
                                    label: Text(c,
                                        style: const TextStyle(fontSize: 12)),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ))
                              .toList(),
                        ),
                ),
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
      value: Value(_type == '2x1' ? 0 : double.parse(_valueCtrl.text)),
      minOrderAmount: Value(double.tryParse(_minCtrl.text) ?? 0),
      validFrom: Value(_validFrom),
      validUntil: Value(_validUntil),
      daysOfWeek:
          Value(_days.isEmpty ? null : (_days.toList()..sort()).join(',')),
      startTime: Value(_startTime != null ? _formatTime(_startTime!) : null),
      endTime: Value(_endTime != null ? _formatTime(_endTime!) : null),
      categoryScope:
          Value(_scopeCategories.isEmpty ? null : _scopeCategories.join(',')),
    );

    if (widget.discount == null) {
      await db.discountsDao.insertDiscount(companion);
    } else {
      await db.discountsDao.updateDiscount(companion);
    }
    if (mounted) Navigator.pop(context);
  }
}
