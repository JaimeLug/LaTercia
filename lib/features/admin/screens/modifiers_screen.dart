import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/settings_provider.dart';

class ModifiersScreen extends ConsumerStatefulWidget {
  const ModifiersScreen({super.key});

  @override
  ConsumerState<ModifiersScreen> createState() => _ModifiersScreenState();
}

class _ModifiersScreenState extends ConsumerState<ModifiersScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';

    return Scaffold(
      appBar: AppBar(title: const Text('Modificadores')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Modifier>>(
        future: ref.read(databaseProvider).modifiersDao.getAllModifiers(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final mods = snapshot.data!;
          return DataTable(
            columns: const [
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Delta precio')),
              DataColumn(label: Text('Alcance')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: mods.map((m) {
              return DataRow(cells: [
                DataCell(Text(m.name)),
                DataCell(Text(m.priceDelta == 0
                    ? 'Sin costo'
                    : (m.priceDelta > 0
                        ? '+${formatCurrency(m.priceDelta, symbol)}'
                        : formatCurrency(m.priceDelta, symbol)))),
                DataCell(Text(m.categoryScope ?? 'Todas')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showForm(context, m),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete,
                          size: 18,
                          color: Theme.of(context).colorScheme.error),
                      onPressed: () async {
                        await ref
                            .read(databaseProvider)
                            .modifiersDao
                            .deleteModifier(m.id);
                        setState(() {});
                      },
                    ),
                  ],
                )),
              ]);
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _showForm(
      BuildContext context, Modifier? modifier) async {
    await showDialog(
      context: context,
      builder: (_) => _ModifierFormDialog(modifier: modifier),
    );
    setState(() {});
  }
}

class _ModifierFormDialog extends ConsumerStatefulWidget {
  final Modifier? modifier;
  const _ModifierFormDialog({this.modifier});

  @override
  ConsumerState<_ModifierFormDialog> createState() =>
      _ModifierFormDialogState();
}

class _ModifierFormDialogState
    extends ConsumerState<_ModifierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _deltaCtrl;
  late TextEditingController _scopeCtrl;

  @override
  void initState() {
    super.initState();
    final m = widget.modifier;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _deltaCtrl = TextEditingController(
        text: m != null ? '${m.priceDelta}' : '0');
    _scopeCtrl =
        TextEditingController(text: m?.categoryScope ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _deltaCtrl.dispose();
    _scopeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.modifier == null
          ? 'Nuevo modificador'
          : 'Editar modificador'),
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
              controller: _deltaCtrl,
              decoration: const InputDecoration(
                  labelText: 'Costo extra (0 = gratis)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _scopeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Alcance (vacío = todas)'),
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
    final companion = ModifiersCompanion(
      id: widget.modifier != null
          ? Value(widget.modifier!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      priceDelta:
          Value(double.tryParse(_deltaCtrl.text) ?? 0),
      categoryScope: Value(
          _scopeCtrl.text.isEmpty ? null : _scopeCtrl.text),
    );

    if (widget.modifier == null) {
      await db.modifiersDao.insertModifier(companion);
    } else {
      await db.modifiersDao.updateModifier(companion);
    }
    if (mounted) Navigator.pop(context);
  }
}
