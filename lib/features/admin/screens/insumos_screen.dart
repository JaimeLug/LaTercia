import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_panel.dart';

/// FASE 7 — Contenido embebido de Insumos dentro del hub de Inventario
/// (mismo patrón que Configuración: sin ventana/página propia): activar/
/// desactivar + catálogo de insumos con su stock. Las recetas viven en el
/// propio formulario de cada producto (Admin → Productos), no aquí — una
/// receta es un detalle de UN producto, no una lista aparte.
class InsumosBody extends ConsumerStatefulWidget {
  const InsumosBody({super.key});

  @override
  ConsumerState<InsumosBody> createState() => InsumosBodyState();
}

class InsumosBodyState extends ConsumerState<InsumosBody> {
  Future<void> _setActivo(bool v) => ref
      .read(settingsProvider.notifier)
      .setSetting('insumos_activo', v.toString());

  /// Invocado por el FAB del hub de Inventario (ver [InventoryScreen]).
  void openAddDialog() => _showForm(context, null);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final activo = settings['insumos_activo'] == 'true';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AdminPanel(
          padding: const EdgeInsets.all(18),
          child: SwitchListTile(
            title: const Text('Activar sistema de insumos'),
            subtitle: const Text(
                'Inventario real de materia prima (café, leche, vasos...) '
                'con recetas por producto — al vender, se descuenta el '
                'insumo en vez del stock simple del producto.'),
            value: activo,
            onChanged: _setActivo,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 16),
        if (activo) _IngredientsList(onChanged: () => setState(() {})),
        if (!activo)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: AdminEmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'Activa el sistema arriba para gestionar insumos '
                  'y armar recetas por producto.',
            ),
          ),
      ],
    );
  }

  Future<void> _showForm(BuildContext context, Ingredient? ingredient) async {
    await showDialog(
      context: context,
      builder: (_) => _IngredientFormDialog(ingredient: ingredient),
    );
    setState(() {});
  }
}

class _IngredientsList extends ConsumerStatefulWidget {
  final VoidCallback onChanged;
  const _IngredientsList({required this.onChanged});

  @override
  ConsumerState<_IngredientsList> createState() => _IngredientsListState();
}

class _IngredientsListState extends ConsumerState<_IngredientsList> {
  late Future<List<Ingredient>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(databaseProvider).ingredientsDao.getAllIngredients();
  }

  void _refresh() {
    setState(_load);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ingredient>>(
      future: _future,
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return adminLoading();
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const AdminEmptyState(
            icon: Icons.inventory_2_outlined,
            message: 'Sin insumos todavía.\n'
                'Toca "+" para dar de alta el primero (ej. "Café molido").',
          );
        }
        return AdminPanel(
          child: Column(
            children: [
              const AdminHeaderRow(cells: [
                Expanded(flex: 3, child: Text('NOMBRE')),
                Expanded(flex: 1, child: Text('UNIDAD')),
                Expanded(flex: 2, child: Text('STOCK')),
                Expanded(flex: 2, child: Text('ESTADO')),
                SizedBox(width: 132, child: Text('ACCIONES')),
              ]),
              ...items.asMap().entries.map((entry) {
                final i = entry.value;
                final isLast = entry.key == items.length - 1;
                final low = i.stockQuantity <= i.minStock;
                return AdminRow(
                  isLast: isLast,
                  cells: [
                    Expanded(
                      flex: 3,
                      child: Text(i.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: i.active
                                  ? LaTerciaColors.darkBrown
                                  : LaTerciaColors.tan)),
                    ),
                    Expanded(flex: 1, child: Text(i.unit)),
                    Expanded(
                        flex: 2,
                        child: Text(
                            '${_fmt(i.stockQuantity)} (mín. ${_fmt(i.minStock)})')),
                    Expanded(
                      flex: 2,
                      child: !i.active
                          ? const StatusPill('Inactivo')
                          : StatusPill(
                              i.stockQuantity <= 0
                                  ? 'Agotado'
                                  : low
                                      ? 'Bajo'
                                      : 'OK',
                              tone: i.stockQuantity <= 0
                                  ? StatusTone.danger
                                  : low
                                      ? StatusTone.warn
                                      : StatusTone.ok,
                            ),
                    ),
                    SizedBox(
                      width: 132,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune,
                                size: 18, color: LaTerciaColors.tan),
                            tooltip: 'Ajustar stock',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _showAdjustDialog(context, i),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: LaTerciaColors.tan),
                            tooltip: 'Editar',
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (_) =>
                                    _IngredientFormDialog(ingredient: i),
                              );
                              _refresh();
                            },
                          ),
                          IconButton(
                            icon: Icon(
                                i.active
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: LaTerciaColors.danger),
                            tooltip: i.active ? 'Desactivar' : 'Reactivar',
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              await ref
                                  .read(databaseProvider)
                                  .ingredientsDao
                                  .setActive(i.id, !i.active);
                              _refresh();
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
        );
      },
    );
  }

  Future<void> _showAdjustDialog(
      BuildContext context, Ingredient ingredient) async {
    final qtyCtrl = TextEditingController(text: _fmt(ingredient.stockQuantity));
    final noteCtrl = TextEditingController();
    String reason = 'ajuste';
    const reasons = ['ajuste', 'compra', 'merma'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Ajustar stock — ${ingredient.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Stock actual: ${_fmt(ingredient.stockQuantity)} ${ingredient.unit}'),
              const SizedBox(height: 8),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Nueva cantidad'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: reason,
                decoration: const InputDecoration(labelText: 'Razón'),
                items: reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setDialogState(() => reason = v!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                final qty = double.tryParse(qtyCtrl.text);
                if (qty == null) return;
                await ref.read(databaseProvider).ingredientsDao.adjustStock(
                      ingredient.id,
                      qty,
                      reason,
                      noteCtrl.text.isEmpty ? null : noteCtrl.text,
                    );
                await ref.read(auditServiceProvider).log(
                  employeeId: ref.read(sessionProvider)?.id,
                  action: 'ajuste_insumo',
                  entity: 'ingredient',
                  entityId: ingredient.id,
                  detail: {
                    'previousStock': ingredient.stockQuantity,
                    'newStock': qty,
                    'reason': reason,
                  },
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _refresh();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

class _IngredientFormDialog extends ConsumerStatefulWidget {
  final Ingredient? ingredient;
  const _IngredientFormDialog({this.ingredient});

  @override
  ConsumerState<_IngredientFormDialog> createState() =>
      _IngredientFormDialogState();
}

class _IngredientFormDialogState extends ConsumerState<_IngredientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _initialStockCtrl;

  @override
  void initState() {
    super.initState();
    final i = widget.ingredient;
    _nameCtrl = TextEditingController(text: i?.name ?? '');
    _unitCtrl = TextEditingController(text: i?.unit ?? '');
    _minStockCtrl = TextEditingController(text: _fmt(i?.minStock ?? 0));
    _initialStockCtrl =
        TextEditingController(text: _fmt(i?.stockQuantity ?? 0));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _minStockCtrl.dispose();
    _initialStockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.ingredient == null;
    return AlertDialog(
      title: Text(isNew ? 'Nuevo insumo' : 'Editar insumo'),
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
              controller: _unitCtrl,
              decoration: const InputDecoration(
                  labelText: 'Unidad *', helperText: 'Ej. g, ml, kg, L, pza'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _minStockCtrl,
              decoration: const InputDecoration(labelText: 'Stock mínimo'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            if (isNew) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _initialStockCtrl,
                decoration: const InputDecoration(labelText: 'Stock inicial'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
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
    final companion = IngredientsCompanion(
      id: widget.ingredient != null
          ? Value(widget.ingredient!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      unit: Value(_unitCtrl.text.trim()),
      minStock: Value(double.tryParse(_minStockCtrl.text) ?? 0),
      stockQuantity: widget.ingredient == null
          ? Value(double.tryParse(_initialStockCtrl.text) ?? 0)
          : const Value.absent(),
    );

    if (widget.ingredient == null) {
      await db.ingredientsDao.insertIngredient(companion);
    } else {
      await db.ingredientsDao.updateIngredient(companion);
    }
    if (mounted) Navigator.pop(context);
  }
}
