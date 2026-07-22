import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _categoryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _selectedCategory = 'Insumos';
  DateTimeRange _filter = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now().add(const Duration(days: 1)),
  );

  static const _categories = [
    'Insumos',
    'Renta',
    'Servicios',
    'Personal',
    'Otro',
  ];

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: Column(
        children: [
          // Formulario de alta
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registrar gasto',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  // `Wrap` en vez de `Row`: con la ventana angosta (o el
                  // sidebar extendido) los 5 controles no cabían en una sola
                  // línea y se salían por la derecha — aquí simplemente
                  // bajan a otra línea. Feedback de sitio 2026-07-22.
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                              labelText: 'Categoría', isDense: true),
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v!),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Descripción', isDense: true),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _amountCtrl,
                          decoration: InputDecoration(
                              labelText: 'Monto ($symbol)', isDense: true),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(formatDate(_date)),
                        onPressed: _pickDate,
                      ),
                      FilledButton(
                        onPressed: _addExpense,
                        child: const Text('Agregar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Filtro de fecha del historial de abajo — separado del formulario
          // de arriba con su propio espacio (antes se sentían pegados) y en
          // un `Wrap` por si la ventana queda angosta. Feedback de sitio
          // 2026-07-22.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                      '${formatDate(_filter.start)} — ${formatDate(_filter.end)}'),
                  onPressed: _pickFilterRange,
                ),
              ],
            ),
          ),
          // Table
          Expanded(
            child: FutureBuilder<List<Expense>>(
              future: ref
                  .read(databaseProvider)
                  .expensesDao
                  .getExpensesByDateRange(_filter.start, _filter.end),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final expenses = snapshot.data!;
                final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

                return Column(
                  children: [
                    Expanded(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Categoría')),
                          DataColumn(label: Text('Descripción')),
                          DataColumn(label: Text('Monto')),
                          DataColumn(label: Text('Fecha')),
                        ],
                        rows: expenses.map((e) {
                          return DataRow(cells: [
                            DataCell(Text(e.category)),
                            DataCell(Text(e.description)),
                            DataCell(Text(formatCurrency(e.amount, symbol))),
                            DataCell(Text(formatDate(e.date))),
                          ]);
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        // Antes usaba el color de Material default
                        // (colorScheme.primaryContainer) sin fijar el color
                        // del texto — con ciertos acentos personalizados el
                        // contraste era malo y "no se lograba ver". Colores
                        // fijos de marca, igual que el resto del Admin.
                        // Feedback de sitio 2026-07-22.
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LaTerciaColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: LaTerciaColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total del período:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: LaTerciaColors.darkBrown)),
                            Text(
                              formatCurrency(total, symbol),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: LaTerciaColors.burntOrange),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickFilterRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _filter,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _filter = picked);
  }

  Future<void> _addExpense() async {
    final amount = double.tryParse(_amountCtrl.text);
    // Antes fallaba en silencio (parecía que el botón "no hacía nada") —
    // feedback de sitio 2026-07-22.
    if (_descCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ingresa una descripción y un monto válido.')),
      );
      return;
    }

    await ref.read(databaseProvider).expensesDao.insertExpense(
          ExpensesCompanion.insert(
            category: _selectedCategory,
            description: _descCtrl.text,
            amount: amount,
            date: _date,
          ),
        );

    _descCtrl.clear();
    _amountCtrl.clear();
    setState(() {});
  }
}
