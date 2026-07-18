import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/services/audit_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_panel.dart';

/// Rastreo simple de stock por producto (`Products.trackInventory`/
/// `stockQuantity`) — el camino de siempre para productos SIN receta. Los
/// productos con receta (FASE 7) se gestionan en Insumos, no aquí (son
/// mutuamente excluyentes por producto).
class StockSimpleBody extends ConsumerStatefulWidget {
  const StockSimpleBody({super.key});

  @override
  ConsumerState<StockSimpleBody> createState() => _StockSimpleBodyState();
}

class _StockSimpleBodyState extends ConsumerState<StockSimpleBody> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(databaseProvider).productsDao.getAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catMap = {for (final c in categories) c.id: c.name};

    return FutureBuilder<List<Product>>(
        future: _future,
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return adminLoading();
          final tracked =
              snapshot.data!.where((p) => p.trackInventory).toList();
          final lowStock =
              tracked.where((p) => p.stockQuantity <= p.minStock).toList();

          if (tracked.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'Ningún producto tiene "Rastrear inventario" activo.\n'
                  'Actívalo en Admin → Productos para verlo aquí.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (lowStock.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: LaTerciaColors.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: LaTerciaColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: LaTerciaColors.goldDark),
                        const SizedBox(width: 10),
                        Text(
                            '${lowStock.length} producto(s) con stock bajo o agotado',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: LaTerciaColors.darkBrown)),
                      ],
                    ),
                  ),
                ),
              AdminPanel(
                child: Column(
                  children: [
                    const AdminHeaderRow(cells: [
                      Expanded(flex: 3, child: Text('PRODUCTO')),
                      Expanded(flex: 2, child: Text('CATEGORÍA')),
                      Expanded(flex: 2, child: Text('STOCK')),
                      Expanded(flex: 2, child: Text('ESTADO')),
                      SizedBox(width: 88, child: Text('ACCIONES')),
                    ]),
                    ...tracked.asMap().entries.map((entry) {
                      final p = entry.value;
                      final isLast = entry.key == tracked.length - 1;
                      final tone = p.stockQuantity == 0
                          ? StatusTone.danger
                          : p.stockQuantity <= p.minStock
                              ? StatusTone.warn
                              : StatusTone.ok;
                      final label = p.stockQuantity == 0
                          ? 'Agotado'
                          : p.stockQuantity <= p.minStock
                              ? 'Bajo'
                              : 'OK';
                      return AdminRow(
                        isLast: isLast,
                        cells: [
                          Expanded(
                            flex: 3,
                            child: Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: LaTerciaColors.darkBrown)),
                          ),
                          Expanded(
                              flex: 2, child: Text(catMap[p.categoryId] ?? '—')),
                          Expanded(
                              flex: 2,
                              child: Text('${p.stockQuantity} (mín. ${p.minStock})')),
                          Expanded(flex: 2, child: StatusPill(label, tone: tone)),
                          SizedBox(
                            width: 88,
                            child: TextButton(
                              onPressed: () => _showAdjustDialog(context, p),
                              child: const Text('Ajustar'),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      );
  }

  Future<void> _showAdjustDialog(BuildContext context, Product product) async {
    final qtyCtrl = TextEditingController(text: '${product.stockQuantity}');
    final noteCtrl = TextEditingController();
    String reason = 'ajuste';
    const reasons = ['ajuste', 'compra', 'merma'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Ajustar stock — ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock actual: ${product.stockQuantity}'),
              const SizedBox(height: 8),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Nueva cantidad'),
                keyboardType: TextInputType.number,
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
                final qty = int.tryParse(qtyCtrl.text);
                if (qty == null) return;
                await ref.read(databaseProvider).inventoryDao.adjustStock(
                      product.id,
                      qty,
                      reason,
                      noteCtrl.text.isEmpty ? null : noteCtrl.text,
                    );
                await ref.read(auditServiceProvider).log(
                  employeeId: ref.read(sessionProvider)?.id,
                  action: 'ajuste_inventario',
                  entity: 'product',
                  entityId: product.id,
                  detail: {
                    'previousStock': product.stockQuantity,
                    'newStock': qty,
                    'reason': reason,
                  },
                );
                if (ctx.mounted) Navigator.pop(ctx);
                setState(_load);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
