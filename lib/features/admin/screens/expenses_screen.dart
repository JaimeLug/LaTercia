import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
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
          // Add form
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
                  Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Descripción', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          decoration: InputDecoration(
                              labelText: 'Monto ($symbol)', isDense: true),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(formatDate(_date)),
                        onPressed: _pickDate,
                      ),
                      const SizedBox(width: 12),
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
          // Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
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
                      child: Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total del período:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                formatCurrency(total, symbol),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
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
    if (amount == null || _descCtrl.text.isEmpty) return;

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
