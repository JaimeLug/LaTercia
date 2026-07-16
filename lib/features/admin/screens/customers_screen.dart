import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/customers_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/formatters.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                var filtered = _search.isEmpty
                    ? customers
                    : customers
                        .where((c) =>
                            c.name.toLowerCase().contains(
                                _search.toLowerCase()) ||
                            (c.phone?.contains(_search) ?? false))
                        .toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Teléfono')),
                      DataColumn(label: Text('Visitas')),
                      DataColumn(label: Text('Total gastado')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: filtered.map((c) {
                      return DataRow(
                        onSelectChanged: (_) =>
                            _showDetail(context, c),
                        cells: [
                          DataCell(Text(c.name)),
                          DataCell(Text(c.phone ?? '-')),
                          DataCell(Text('${c.visits}')),
                          DataCell(Text(formatCurrency(
                              c.totalSpent, symbol))),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showForm(context, c),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showForm(
      BuildContext context, Customer? customer) async {
    await showDialog(
      context: context,
      builder: (_) => _CustomerFormDialog(customer: customer),
    );
  }

  Future<void> _showDetail(
      BuildContext context, Customer customer) async {
    final db = ref.read(databaseProvider);
    final orders =
        await db.ordersDao.getOrdersByDateRange(
      DateTime(2020),
      DateTime.now().add(const Duration(days: 1)),
    );
    final customerOrders =
        orders.where((o) => o.customerId == customer.id).toList();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(customer.name),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.phone != null)
                Text('📞 ${customer.phone}'),
              if (customer.email != null)
                Text('✉ ${customer.email}'),
              Text('Visitas: ${customer.visits}'),
              const Divider(),
              const Text('Órdenes recientes:'),
              SizedBox(
                height: 200,
                child: ListView(
                  children: customerOrders.map((o) {
                    return ListTile(
                      dense: true,
                      title: Text(o.orderNumber),
                      subtitle:
                          Text(formatDateTime(o.createdAt)),
                      trailing: Text(
                          formatCurrency(o.total, r'$')),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

class _CustomerFormDialog extends ConsumerStatefulWidget {
  final Customer? customer;
  const _CustomerFormDialog({this.customer});

  @override
  ConsumerState<_CustomerFormDialog> createState() =>
      _CustomerFormDialogState();
}

class _CustomerFormDialogState
    extends ConsumerState<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.customer == null ? 'Nuevo cliente' : 'Editar cliente'),
      content: Form(
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
            TextFormField(
              controller: _phoneCtrl,
              decoration:
                  const InputDecoration(labelText: 'Teléfono'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              decoration:
                  const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 2,
            ),
          ],
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
    final companion = CustomersCompanion(
      id: widget.customer != null
          ? Value(widget.customer!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      phone: Value(
          _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text),
      email: Value(
          _emailCtrl.text.isEmpty ? null : _emailCtrl.text),
      notes: Value(
          _notesCtrl.text.isEmpty ? null : _notesCtrl.text),
    );

    if (widget.customer == null) {
      await db.customersDao.insertCustomer(companion);
    } else {
      await db.customersDao.updateCustomer(companion);
    }
    if (mounted) Navigator.pop(context);
  }
}
