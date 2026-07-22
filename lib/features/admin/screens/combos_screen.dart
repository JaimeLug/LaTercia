import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/providers/combos_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/admin_panel.dart';

/// Productos → pestaña "Combos": paquetes de productos a precio especial. Se
/// EXPANDEN a sus productos reales al vender — ver `docs/combos.md`. Sin
/// AppBar propio: vive embebida dentro del `TabBarView` de `ProductsScreen`,
/// cuyo `TabBar` ya muestra el título.
class CombosScreen extends ConsumerStatefulWidget {
  const CombosScreen({super.key});

  @override
  ConsumerState<CombosScreen> createState() => _CombosScreenState();
}

class _CombosScreenState extends ConsumerState<CombosScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final combosAsync = ref.watch(combosProvider);

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: LaTerciaColors.burntOrange,
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: combosAsync.when(
        data: (combos) {
          if (combos.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.fastfood_outlined,
              message: 'Sin combos todavía.\n'
                  'Toca "+" para crear el primero (ej. "Desayuno: café + pan").',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AdminPanel(
              child: Column(
                children: [
                  const AdminHeaderRow(cells: [
                    Expanded(flex: 4, child: Text('NOMBRE')),
                    Expanded(flex: 2, child: Text('PRECIO')),
                    Expanded(flex: 1, child: Text('ACTIVO')),
                    SizedBox(width: 88, child: Text('ACCIONES')),
                  ]),
                  ...combos.asMap().entries.map((entry) {
                    final c = entry.value;
                    final isLast = entry.key == combos.length - 1;
                    return AdminRow(
                      isLast: isLast,
                      cells: [
                        Expanded(
                          flex: 4,
                          child: Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: LaTerciaColors.darkBrown)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(formatCurrency(c.price, symbol),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: LaTerciaColors.success)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Switch(
                            value: c.active,
                            activeColor: LaTerciaColors.burntOrange,
                            onChanged: (v) async {
                              await ref
                                  .read(databaseProvider)
                                  .combosDao
                                  .toggleActive(c.id, v);
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
                                onPressed: () => _showForm(context, c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: LaTerciaColors.danger),
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  await ref
                                      .read(databaseProvider)
                                      .combosDao
                                      .deleteCombo(c.id);
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
        loading: () => adminLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, Combo? combo) async {
    await showDialog(
      context: context,
      builder: (_) => _ComboFormDialog(combo: combo),
    );
  }
}

class _ComboFormDialog extends ConsumerStatefulWidget {
  final Combo? combo;
  const _ComboFormDialog({this.combo});

  @override
  ConsumerState<_ComboFormDialog> createState() => _ComboFormDialogState();
}

/// Un componente en edición dentro del formulario (antes de guardar).
class _ComponentDraft {
  Product product;
  int quantity;
  _ComponentDraft({required this.product, this.quantity = 1});
}

class _ComboFormDialogState extends ConsumerState<_ComboFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  List<Product> _allProducts = [];
  final List<_ComponentDraft> _components = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final c = widget.combo;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _priceCtrl = TextEditingController(text: c != null ? '${c.price}' : '');
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final products = await db.productsDao.getAllProducts();
    List<_ComponentDraft> drafts = [];
    if (widget.combo != null) {
      final comps = await db.combosDao.getComboComponents(widget.combo!.id);
      drafts = [
        for (final comp in comps)
          _ComponentDraft(product: comp.product, quantity: comp.quantity),
      ];
    }
    if (!mounted) return;
    setState(() {
      _allProducts = products;
      _components.addAll(drafts);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _addComponent() {
    if (_allProducts.isEmpty) return;
    setState(
        () => _components.add(_ComponentDraft(product: _allProducts.first)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.combo == null ? 'Nuevo combo' : 'Editar combo'),
      content: SizedBox(
        width: 440,
        child: _loading
            ? const SizedBox(
                height: 120, child: Center(child: CircularProgressIndicator()))
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre *'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Precio del combo *'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v!.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Componentes',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: LaTerciaColors.darkBrown)),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar'),
                          onPressed:
                              _allProducts.isEmpty ? null : _addComponent,
                        ),
                      ],
                    ),
                    if (_components.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Sin componentes. Agrega al menos uno.',
                          style: TextStyle(color: LaTerciaColors.tan),
                        ),
                      )
                    else
                      ...List.generate(_components.length, _componentRow),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: _loading ? null : _save, child: const Text('Guardar')),
      ],
    );
  }

  Widget _componentRow(int i) {
    final draft = _components[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: draft.product.id,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: [
                for (final p in _allProducts)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (id) {
                final chosen = _allProducts.firstWhere((p) => p.id == id);
                setState(() => draft.product = chosen);
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextFormField(
              initialValue: '${draft.quantity}',
              decoration:
                  const InputDecoration(isDense: true, labelText: 'Cant.'),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  draft.quantity = int.tryParse(v) ?? draft.quantity,
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.close, size: 18, color: LaTerciaColors.danger),
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _components.removeAt(i)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_components.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agrega al menos un componente.')));
      return;
    }
    final db = ref.read(databaseProvider);
    final companion = CombosCompanion(
      id: widget.combo != null ? Value(widget.combo!.id) : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      price: Value(double.parse(_priceCtrl.text)),
    );

    int comboId;
    if (widget.combo == null) {
      comboId = await db.combosDao.insertCombo(companion);
    } else {
      comboId = widget.combo!.id;
      await db.combosDao.updateCombo(companion);
    }

    await db.combosDao.replaceComboItems(
      comboId,
      [
        for (final d in _components)
          (productId: d.product.id, quantity: d.quantity)
      ],
    );

    if (mounted) Navigator.pop(context);
  }
}
