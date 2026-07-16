import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/services/audit_service.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? [];
    final catMap = {for (final c in categories) c.id: c.name};

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      body: FutureBuilder<List<Product>>(
        future: ref
            .read(databaseProvider)
            .productsDao
            .getAllProducts(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;
          final tracked =
              all.where((p) => p.trackInventory).toList();
          final lowStock = tracked
              .where((p) => p.stockQuantity <= p.minStock)
              .toList();

          return Column(
            children: [
              if (lowStock.isNotEmpty)
                MaterialBanner(
                  backgroundColor: Colors.amber.shade50,
                  leading: const Icon(Icons.warning,
                      color: Colors.amber),
                  content: Text(
                    '${lowStock.length} producto(s) con stock bajo',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Producto')),
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Stock actual')),
                      DataColumn(label: Text('Stock mínimo')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: tracked.map((p) {
                      String status;
                      Color statusColor;
                      if (p.stockQuantity == 0) {
                        status = 'Agotado';
                        statusColor = Colors.red;
                      } else if (p.stockQuantity <= p.minStock) {
                        status = 'Bajo';
                        statusColor = Colors.amber;
                      } else {
                        status = 'OK';
                        statusColor = Colors.green;
                      }

                      return DataRow(cells: [
                        DataCell(Text(p.name)),
                        DataCell(Text(
                            catMap[p.categoryId] ?? '-')),
                        DataCell(Text('${p.stockQuantity}')),
                        DataCell(Text('${p.minStock}')),
                        DataCell(Chip(
                          label: Text(status,
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor:
                              statusColor.withValues(alpha: 0.2),
                          side: BorderSide(color: statusColor),
                        )),
                        DataCell(TextButton(
                          onPressed: () =>
                              _showAdjustDialog(context, p),
                          child: const Text('Ajustar'),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAdjustDialog(
      BuildContext context, Product product) async {
    final qtyCtrl = TextEditingController(
        text: '${product.stockQuantity}');
    final noteCtrl = TextEditingController();
    String reason = 'ajuste';

    final reasons = ['ajuste', 'compra', 'merma'];

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
                decoration: const InputDecoration(
                    labelText: 'Nueva cantidad'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: reason,
                decoration:
                    const InputDecoration(labelText: 'Razón'),
                items: reasons
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => reason = v!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nota (opcional)'),
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
                await ref
                    .read(databaseProvider)
                    .inventoryDao
                    .adjustStock(
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
                setState(() {});
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
