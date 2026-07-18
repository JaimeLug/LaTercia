import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/daos/purchases_dao.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/admin_panel.dart';

/// FASE 7 — Contenido embebido de Compras dentro del hub de Inventario (sin
/// ventana/página propia — ver [InventoryScreen]): historial de compras a
/// proveedor, cada una repone el stock de N insumos a la vez.
class ComprasBody extends ConsumerStatefulWidget {
  const ComprasBody({super.key});

  @override
  ConsumerState<ComprasBody> createState() => ComprasBodyState();
}

class ComprasBodyState extends ConsumerState<ComprasBody> {
  late Future<List<PurchaseWithSupplier>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(databaseProvider).purchasesDao.getAllPurchases();
  }

  /// Invocado por el FAB del hub de Inventario.
  Future<void> openAddDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const _PurchaseFormDialog(),
    );
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';

    return FutureBuilder<List<PurchaseWithSupplier>>(
        future: _future,
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return adminLoading();
          final purchases = snapshot.data!;
          if (purchases.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.shopping_cart_outlined,
              message: 'Sin compras registradas todavía.\n'
                  'Toca "+" para registrar la primera reposición de insumos.',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AdminPanel(
              child: Column(
                children: [
                  const AdminHeaderRow(cells: [
                    Expanded(flex: 2, child: Text('FECHA')),
                    Expanded(flex: 3, child: Text('PROVEEDOR')),
                    Expanded(flex: 2, child: Text('TOTAL')),
                  ]),
                  ...purchases.asMap().entries.map((entry) {
                    final p = entry.value.purchase;
                    final isLast = entry.key == purchases.length - 1;
                    return AdminRow(
                      isLast: isLast,
                      cells: [
                        Expanded(
                            flex: 2, child: Text(formatDate(p.createdAt))),
                        Expanded(
                            flex: 3,
                            child: Text(
                                entry.value.supplierName ?? 'Sin proveedor')),
                        Expanded(
                          flex: 2,
                          child: Text(formatCurrency(p.totalCost, symbol),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: LaTerciaColors.darkBrown)),
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
}

class _PurchaseLine {
  int? ingredientId;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
}

class _PurchaseFormDialog extends ConsumerStatefulWidget {
  const _PurchaseFormDialog();

  @override
  ConsumerState<_PurchaseFormDialog> createState() =>
      _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends ConsumerState<_PurchaseFormDialog> {
  int? _supplierId;
  final _noteCtrl = TextEditingController();
  final List<_PurchaseLine> _lines = [_PurchaseLine()];
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    for (final l in _lines) {
      l.qtyCtrl.dispose();
      l.costCtrl.dispose();
    }
    super.dispose();
  }

  double get _total {
    var sum = 0.0;
    for (final l in _lines) {
      final qty = double.tryParse(l.qtyCtrl.text) ?? 0;
      final cost = double.tryParse(l.costCtrl.text) ?? 0;
      sum += qty * cost;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';

    return AlertDialog(
      title: const Text('Nueva compra'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<Supplier>>(
                future:
                    ref.read(databaseProvider).suppliersDao.getActiveSuppliers(),
                builder: (ctx, snapshot) {
                  final suppliers = snapshot.data ?? [];
                  return DropdownButtonFormField<int?>(
                    value: _supplierId,
                    decoration:
                        const InputDecoration(labelText: 'Proveedor (opcional)'),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('Sin proveedor')),
                      ...suppliers.map((s) =>
                          DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => _supplierId = v),
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Ingredient>>(
                future: ref
                    .read(databaseProvider)
                    .ingredientsDao
                    .getActiveIngredients(),
                builder: (ctx, snapshot) {
                  final ingredients = snapshot.data ?? [];
                  if (ingredients.isEmpty) {
                    return const Text(
                        'No hay insumos activos — da de alta uno en Insumos primero.',
                        style: TextStyle(color: LaTerciaColors.tan));
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < _lines.length; i++)
                        _buildLineRow(i, ingredients),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => _lines.add(_PurchaseLine())),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar insumo'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Total: ${formatCurrency(_total, symbol)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: LaTerciaColors.darkBrown)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: LaTerciaColors.danger)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildLineRow(int index, List<Ingredient> ingredients) {
    final line = _lines[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              value: line.ingredientId,
              decoration: const InputDecoration(labelText: 'Insumo'),
              items: ingredients
                  .map((i) =>
                      DropdownMenuItem(value: i.id, child: Text(i.name)))
                  .toList(),
              onChanged: (v) => setState(() => line.ingredientId = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: line.qtyCtrl,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: line.costCtrl,
              decoration: const InputDecoration(labelText: 'Costo unit.'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_lines.length > 1)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: LaTerciaColors.danger),
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _lines.removeAt(index)),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final drafts = <PurchaseItemDraft>[];
    for (final l in _lines) {
      if (l.ingredientId == null) continue;
      final qty = double.tryParse(l.qtyCtrl.text);
      final cost = double.tryParse(l.costCtrl.text);
      if (qty == null || qty <= 0 || cost == null || cost < 0) continue;
      drafts.add(PurchaseItemDraft(
          ingredientId: l.ingredientId!, quantity: qty, unitCost: cost));
    }
    if (drafts.isEmpty) {
      setState(() => _error = 'Agrega al menos una línea con insumo y cantidad válidos.');
      return;
    }
    final employeeId = ref.read(sessionProvider)?.id;
    if (employeeId == null) {
      setState(() => _error = 'No hay sesión activa.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await ref.read(databaseProvider).purchasesDao.createPurchase(
          supplierId: _supplierId,
          employeeId: employeeId,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          items: drafts,
        );
    if (mounted) Navigator.pop(context);
  }
}
