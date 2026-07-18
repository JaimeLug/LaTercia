import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_panel.dart';

/// FASE 7 — Contenido embebido de Proveedores dentro del hub de Inventario
/// (sin ventana/página propia — ver [InventoryScreen]).
class ProveedoresBody extends ConsumerStatefulWidget {
  const ProveedoresBody({super.key});

  @override
  ConsumerState<ProveedoresBody> createState() => ProveedoresBodyState();
}

class ProveedoresBodyState extends ConsumerState<ProveedoresBody> {
  /// Invocado por el FAB del hub de Inventario.
  void openAddDialog() => _showForm(context, null);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Supplier>>(
        future: ref.read(databaseProvider).suppliersDao.getAllSuppliers(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return adminLoading();
          final suppliers = snapshot.data!;
          if (suppliers.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.local_shipping_outlined,
              message: 'Sin proveedores todavía.\n'
                  'Toca "+" para dar de alta el primero.',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AdminPanel(
              child: Column(
                children: [
                  const AdminHeaderRow(cells: [
                    Expanded(flex: 3, child: Text('NOMBRE')),
                    Expanded(flex: 2, child: Text('CONTACTO')),
                    Expanded(flex: 2, child: Text('TELÉFONO')),
                    Expanded(flex: 2, child: Text('ESTADO')),
                    SizedBox(width: 88, child: Text('ACCIONES')),
                  ]),
                  ...suppliers.asMap().entries.map((entry) {
                    final s = entry.value;
                    final isLast = entry.key == suppliers.length - 1;
                    return AdminRow(
                      isLast: isLast,
                      cells: [
                        Expanded(
                          flex: 3,
                          child: Text(s.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: s.active
                                      ? LaTerciaColors.darkBrown
                                      : LaTerciaColors.tan)),
                        ),
                        Expanded(flex: 2, child: Text(s.contactName ?? '—')),
                        Expanded(flex: 2, child: Text(s.phone ?? '—')),
                        Expanded(
                          flex: 2,
                          child: StatusPill(s.active ? 'Activo' : 'Inactivo',
                              tone: s.active
                                  ? StatusTone.ok
                                  : StatusTone.neutral),
                        ),
                        SizedBox(
                          width: 88,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: LaTerciaColors.tan),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _showForm(context, s),
                              ),
                              IconButton(
                                icon: Icon(
                                    s.active
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: LaTerciaColors.danger),
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  await ref
                                      .read(databaseProvider)
                                      .suppliersDao
                                      .setActive(s.id, !s.active);
                                  setState(() {});
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
      );
  }

  Future<void> _showForm(BuildContext context, Supplier? supplier) async {
    await showDialog(
      context: context,
      builder: (_) => _SupplierFormDialog(supplier: supplier),
    );
    setState(() {});
  }
}

class _SupplierFormDialog extends ConsumerStatefulWidget {
  final Supplier? supplier;
  const _SupplierFormDialog({this.supplier});

  @override
  ConsumerState<_SupplierFormDialog> createState() =>
      _SupplierFormDialogState();
}

class _SupplierFormDialogState extends ConsumerState<_SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _contactCtrl = TextEditingController(text: s?.contactName ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _noteCtrl = TextEditingController(text: s?.note ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.supplier == null ? 'Nuevo proveedor' : 'Editar proveedor'),
      content: Form(
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
            TextFormField(
              controller: _contactCtrl,
              decoration:
                  const InputDecoration(labelText: 'Persona de contacto'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
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
    final companion = SuppliersCompanion(
      id: widget.supplier != null
          ? Value(widget.supplier!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      contactName: Value(
          _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim()),
      phone: Value(_phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim()),
      note: Value(_noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
    );

    if (widget.supplier == null) {
      await db.suppliersDao.insertSupplier(companion);
    } else {
      await db.suppliersDao.updateSupplier(companion);
    }
    if (mounted) Navigator.pop(context);
  }
}
