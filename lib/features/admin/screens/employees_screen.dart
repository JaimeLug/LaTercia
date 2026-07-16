import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/employees_provider.dart';
import '../../../core/utils/pin_hasher.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Empleados')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: employeesAsync.when(
        data: (employees) {
          final usingDefaultAdminPin = employees.any((e) =>
              e.role == 'admin' && e.active && isDefaultAdminPin(e.pin));
          return ListView(
            children: [
              if (usingDefaultAdminPin) _DefaultPinWarning(),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('PIN')),
                  DataColumn(label: Text('Rol')),
                  DataColumn(label: Text('Activo')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: employees.map((e) {
            return DataRow(cells: [
              DataCell(Text(e.name)),
              const DataCell(Text('••••')),
              DataCell(Text(e.role)),
              DataCell(Switch(
                value: e.active,
                onChanged: (v) async {
                  await ref
                      .read(databaseProvider)
                      .employeesDao
                      .toggleActive(e.id, v);
                },
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showForm(context, e),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete,
                        size: 18,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: () => _delete(context, e),
                  ),
                ],
              )),
            ]);
                }).toList(),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showForm(
      BuildContext context, Employee? employee) async {
    await showDialog(
      context: context,
      builder: (_) => _EmployeeFormDialog(employee: employee),
    );
  }

  Future<void> _delete(
      BuildContext context, Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar empleado'),
        content: Text('¿Eliminar "${employee.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(databaseProvider)
          .employeesDao
          .deleteEmployee(employee.id);
    }
  }
}

class _EmployeeFormDialog extends ConsumerStatefulWidget {
  final Employee? employee;
  const _EmployeeFormDialog({this.employee});

  @override
  ConsumerState<_EmployeeFormDialog> createState() =>
      _EmployeeFormDialogState();
}

class _EmployeeFormDialogState
    extends ConsumerState<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _pinCtrl;
  String _role = 'cashier';
  bool _showPin = false;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    // Never prefill the PIN: stored values are hashes, not the real PIN. On
    // edit, an empty field means "keep the current PIN".
    _pinCtrl = TextEditingController();
    _role = e?.role ?? 'cashier';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.employee == null ? 'Nuevo empleado' : 'Editar empleado'),
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
              controller: _pinCtrl,
              decoration: InputDecoration(
                labelText: widget.employee == null
                    ? 'PIN (4 dígitos) *'
                    : 'Nuevo PIN (vacío = sin cambio)',
                suffixIcon: IconButton(
                  icon: Icon(
                      _showPin ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _showPin = !_showPin),
                ),
              ),
              obscureText: !_showPin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              validator: (v) {
                final value = v ?? '';
                // On edit, an empty field keeps the current PIN.
                if (widget.employee != null && value.isEmpty) return null;
                if (value.length != 4) return 'PIN de 4 dígitos';
                if (int.tryParse(value) == null) return 'Solo números';
                return null;
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: const [
                DropdownMenuItem(
                    value: 'admin', child: Text('Administrador')),
                DropdownMenuItem(
                    value: 'gerente', child: Text('Gerente')),
                DropdownMenuItem(
                    value: 'cashier', child: Text('Cajero')),
                DropdownMenuItem(
                    value: 'kitchen', child: Text('Cocina')),
              ],
              onChanged: (v) => setState(() => _role = v!),
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

    // Store the PIN hashed. On edit with an empty field, leave the PIN as-is.
    final pinText = _pinCtrl.text;
    final pinValue = (widget.employee != null && pinText.isEmpty)
        ? const Value<String>.absent()
        : Value(hashPin(pinText));

    final companion = EmployeesCompanion(
      id: widget.employee != null
          ? Value(widget.employee!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      pin: pinValue,
      role: Value(_role),
    );

    if (widget.employee == null) {
      await db.employeesDao.insertEmployee(companion);
    } else {
      await db.employeesDao.updateEmployee(companion);
    }
    if (mounted) Navigator.pop(context);
  }
}

class _DefaultPinWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'El PIN de administrador sigue siendo el predeterminado (0000). '
              'Edita el empleado administrador y asígnale un PIN nuevo.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
