import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/employees_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/pin_hasher.dart';
import '../widgets/admin_panel.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

const _roleLabels = {
  'admin': 'Administrador',
  'gerente': 'Gerente',
  'cashier': 'Cajero',
  'kitchen': 'Cocina',
};

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Empleados'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: LaTerciaColors.burntOrange,
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: employeesAsync.when(
        data: (employees) {
          final usingDefaultAdminPin = employees.any(
              (e) => e.role == 'admin' && e.active && isDefaultAdminPin(e.pin));
          if (employees.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.badge_outlined,
              message: 'Sin empleados todavía.',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (usingDefaultAdminPin) ...[
                  const _DefaultPinWarning(),
                  const SizedBox(height: 16),
                ],
                AdminPanel(
                  child: Column(
                    children: [
                      const AdminHeaderRow(cells: [
                        Expanded(flex: 3, child: Text('NOMBRE')),
                        Expanded(flex: 2, child: Text('PIN')),
                        Expanded(flex: 2, child: Text('ROL')),
                        Expanded(flex: 2, child: Text('ACTIVO')),
                        SizedBox(width: 88, child: Text('ACCIONES')),
                      ]),
                      ...employees.asMap().entries.map((entry) {
                        final e = entry.value;
                        final isLast = entry.key == employees.length - 1;
                        return AdminRow(
                          isLast: isLast,
                          cells: [
                            Expanded(
                              flex: 3,
                              child: Text(e.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: LaTerciaColors.darkBrown)),
                            ),
                            const Expanded(
                                flex: 2,
                                child: Text('••••',
                                    style: TextStyle(
                                        color: LaTerciaColors.tan,
                                        letterSpacing: 2))),
                            Expanded(
                                flex: 2,
                                child: Text(_roleLabels[e.role] ?? e.role)),
                            Expanded(
                              flex: 2,
                              child: Switch(
                                value: e.active,
                                activeColor: LaTerciaColors.burntOrange,
                                onChanged: (v) async {
                                  await ref
                                      .read(databaseProvider)
                                      .employeesDao
                                      .toggleActive(e.id, v);
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
                                    onPressed: () => _showForm(context, e),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: LaTerciaColors.danger),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _delete(context, e),
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
              ],
            ),
          );
        },
        loading: () => adminLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, Employee? employee) async {
    await showDialog(
      context: context,
      builder: (_) => _EmployeeFormDialog(employee: employee),
    );
  }

  Future<void> _delete(BuildContext context, Employee employee) async {
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
      await ref.read(databaseProvider).employeesDao.deleteEmployee(employee.id);
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

class _EmployeeFormDialogState extends ConsumerState<_EmployeeFormDialog> {
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
    // Nunca precargar el PIN (lo guardado es un hash). Al editar, campo vacío =
    // mantener el PIN actual. docs/seguridad.md.
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
      title:
          Text(widget.employee == null ? 'Nuevo empleado' : 'Editar empleado'),
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
              controller: _pinCtrl,
              decoration: InputDecoration(
                labelText: widget.employee == null
                    ? 'PIN (4 dígitos) *'
                    : 'Nuevo PIN (vacío = sin cambio)',
                suffixIcon: IconButton(
                  icon:
                      Icon(_showPin ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPin = !_showPin),
                ),
              ),
              obscureText: !_showPin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              validator: (v) {
                final value = v ?? '';
                // Al editar, campo vacío mantiene el PIN actual.
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
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                DropdownMenuItem(value: 'gerente', child: Text('Gerente')),
                DropdownMenuItem(value: 'cashier', child: Text('Cajero')),
                DropdownMenuItem(value: 'kitchen', child: Text('Cocina')),
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

    // Al editar, campo vacío = mantener el PIN; solo fijamos PIN si trae valor
    // (o es empleado nuevo).
    final pinText = _pinCtrl.text;
    final settingPin = !(widget.employee != null && pinText.isEmpty);

    // Impedir dos empleados ACTIVOS con el mismo PIN (la auditoría por empleado
    // quedaría ambigua). Solo al fijar un PIN. docs/seguridad.md.
    if (settingPin &&
        await db.employeesDao
            .pinInUseByActive(pinText, excludeId: widget.employee?.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ese PIN ya lo usa otro empleado activo. Elige otro.'),
        ));
      }
      return;
    }

    // Guarda el PIN hasheado; al editar con campo vacío, lo deja igual.
    final pinValue =
        settingPin ? Value(hashPin(pinText)) : const Value<String>.absent();

    final companion = EmployeesCompanion(
      id: widget.employee != null
          ? Value(widget.employee!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      pin: pinValue,
      role: Value(_role),
    );

    try {
      if (widget.employee == null) {
        await db.employeesDao.insertEmployee(companion);
      } else {
        await db.employeesDao.updateEmployee(companion);
      }
    } catch (e) {
      // Red de seguridad: el UNIQUE(pin) de la base aún podría saltar (p.ej. si
      // el PIN lo tiene un empleado INACTIVO). Mensaje claro en vez de crash.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo guardar: ese PIN ya está en uso.'),
        ));
      }
      return;
    }
    if (mounted) Navigator.pop(context);
  }
}

class _DefaultPinWarning extends StatelessWidget {
  const _DefaultPinWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LaTerciaColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LaTerciaColors.danger.withValues(alpha: 0.4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: LaTerciaColors.danger, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'El PIN de administrador sigue siendo el predeterminado (0000). '
              'Edita el empleado administrador y asígnale un PIN nuevo.',
              style: TextStyle(
                  color: LaTerciaColors.darkBrown, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
