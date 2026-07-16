import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/tables_provider.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mesas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: tablesAsync.when(
        data: (tables) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: tables.length,
          itemBuilder: (ctx, i) {
            final t = tables[i];
            final colors = {
              'available': Colors.green,
              'occupied': Colors.red,
              'reserved': Colors.amber,
            };
            final color = colors[t.status] ?? Colors.grey;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('${t.capacity} personas',
                        style: const TextStyle(
                            color: Colors.grey)),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(t.status.toUpperCase()),
                      backgroundColor: color.withValues(alpha: 0.2),
                      side: BorderSide(color: color),
                    ),
                    TextButton(
                      onPressed: () =>
                          _showForm(context, ref, t),
                      child: const Text('Editar'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showForm(
      BuildContext context, WidgetRef ref, TablesLayoutData? table) async {
    await showDialog(
      context: context,
      builder: (_) => _TableFormDialog(table: table),
    );
  }
}

class _TableFormDialog extends ConsumerStatefulWidget {
  final TablesLayoutData? table;
  const _TableFormDialog({this.table});

  @override
  ConsumerState<_TableFormDialog> createState() =>
      _TableFormDialogState();
}

class _TableFormDialogState extends ConsumerState<_TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _notesCtrl;
  String _status = 'available';
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final t = widget.table;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _capacityCtrl =
        TextEditingController(text: t != null ? '${t.capacity}' : '4');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _status = t?.status ?? 'available';
    _active = t?.active ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.table == null ? 'Nueva mesa' : 'Editar mesa'),
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
              controller: _capacityCtrl,
              decoration:
                  const InputDecoration(labelText: 'Capacidad'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              decoration:
                  const InputDecoration(labelText: 'Estado'),
              items: const [
                DropdownMenuItem(
                    value: 'available',
                    child: Text('Disponible')),
                DropdownMenuItem(
                    value: 'occupied',
                    child: Text('Ocupada')),
                DropdownMenuItem(
                    value: 'reserved',
                    child: Text('Reservada')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notas'),
            ),
            SwitchListTile(
              title: const Text('Activa'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              contentPadding: EdgeInsets.zero,
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
    final companion = TablesLayoutCompanion(
      id: widget.table != null
          ? Value(widget.table!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      capacity: Value(int.tryParse(_capacityCtrl.text) ?? 4),
      status: Value(_status),
      notes: Value(
          _notesCtrl.text.isEmpty ? null : _notesCtrl.text),
      active: Value(_active),
    );

    if (widget.table == null) {
      await db.tablesDao.insertTable(companion);
    } else {
      await db.tablesDao.updateTable(companion);
    }
    if (mounted) Navigator.pop(context);
  }
}
