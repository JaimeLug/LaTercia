import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/admin_panel.dart';

/// FASE 8 — Zonas de envío: cargo fijo por zona para órdenes `delivery`
/// (Chicxulub, Progreso 1, Progreso 2...). Configuración → Envío — se embebe
/// dentro del layout de `SettingsScreen` (cambio de estado, no
/// `Navigator.push`) para que el sidebar y el header sigan visibles;
/// [onBack] regresa a la cuadrícula de Configuración.
class DeliveryZonesScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const DeliveryZonesScreen({super.key, required this.onBack});

  @override
  ConsumerState<DeliveryZonesScreen> createState() =>
      _DeliveryZonesScreenState();
}

class _DeliveryZonesScreenState extends ConsumerState<DeliveryZonesScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar(
        'Envío',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LaTerciaColors.darkBrown),
          onPressed: widget.onBack,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: LaTerciaColors.burntOrange,
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<DeliveryZone>>(
        future: ref.read(databaseProvider).deliveryZonesDao.getAllZones(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return adminLoading();
          final zones = snapshot.data!;
          if (zones.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.delivery_dining_outlined,
              message: 'Sin zonas de envío todavía.\n'
                  'Toca "+" para dar de alta la primera (ej. "Chicxulub").',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AdminPanel(
              child: Column(
                children: [
                  const AdminHeaderRow(cells: [
                    Expanded(flex: 3, child: Text('ZONA')),
                    Expanded(flex: 2, child: Text('CARGO')),
                    Expanded(flex: 2, child: Text('ESTADO')),
                    SizedBox(width: 88, child: Text('ACCIONES')),
                  ]),
                  ...zones.asMap().entries.map((entry) {
                    final z = entry.value;
                    final isLast = entry.key == zones.length - 1;
                    return AdminRow(
                      isLast: isLast,
                      cells: [
                        Expanded(
                          flex: 3,
                          child: Text(z.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: z.active
                                      ? LaTerciaColors.darkBrown
                                      : LaTerciaColors.tan)),
                        ),
                        Expanded(
                            flex: 2,
                            child: Text(formatCurrency(z.fee, symbol))),
                        Expanded(
                          flex: 2,
                          child: StatusPill(z.active ? 'Activa' : 'Inactiva',
                              tone: z.active
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
                                onPressed: () => _showForm(context, z),
                              ),
                              IconButton(
                                icon: Icon(
                                    z.active
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: LaTerciaColors.danger),
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  await ref
                                      .read(databaseProvider)
                                      .deliveryZonesDao
                                      .setActive(z.id, !z.active);
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
      ),
    );
  }

  Future<void> _showForm(BuildContext context, DeliveryZone? zone) async {
    await showDialog(
      context: context,
      builder: (_) => _ZoneFormDialog(zone: zone),
    );
    setState(() {});
  }
}

class _ZoneFormDialog extends ConsumerStatefulWidget {
  final DeliveryZone? zone;
  const _ZoneFormDialog({this.zone});

  @override
  ConsumerState<_ZoneFormDialog> createState() => _ZoneFormDialogState();
}

class _ZoneFormDialogState extends ConsumerState<_ZoneFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _feeCtrl;

  @override
  void initState() {
    super.initState();
    final z = widget.zone;
    _nameCtrl = TextEditingController(text: z?.name ?? '');
    _feeCtrl = TextEditingController(text: z != null ? '${z.fee}' : '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.zone == null ? 'Nueva zona' : 'Editar zona'),
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
              controller: _feeCtrl,
              decoration: const InputDecoration(labelText: 'Cargo'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
    final companion = DeliveryZonesCompanion(
      id: widget.zone != null ? Value(widget.zone!.id) : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      fee: Value(double.tryParse(_feeCtrl.text) ?? 0),
    );

    if (widget.zone == null) {
      await db.deliveryZonesDao.insertZone(companion);
    } else {
      await db.deliveryZonesDao.updateZone(companion);
    }
    if (mounted) Navigator.pop(context);
  }
}
