import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/formatters.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _search = '';
  int? _filterCategoryId;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<int?>(
                  value: _filterCategoryId,
                  hint: const Text('Categoría'),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('Todas')),
                    ...categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (v) =>
                      setState(() => _filterCategoryId = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: ref.read(databaseProvider).productsDao.getAllProducts(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                var products = snapshot.data!;
                if (_filterCategoryId != null) {
                  products = products
                      .where((p) => p.categoryId == _filterCategoryId)
                      .toList();
                }
                if (_search.isNotEmpty) {
                  products = products
                      .where((p) => p.name
                          .toLowerCase()
                          .contains(_search.toLowerCase()))
                      .toList();
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Precio')),
                      DataColumn(label: Text('Costo')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Disponible')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: products.map((p) {
                      final cat = categories
                          .where((c) => c.id == p.categoryId)
                          .firstOrNull;
                      return DataRow(cells: [
                        DataCell(Text(p.name)),
                        DataCell(Text(cat?.name ?? '-')),
                        DataCell(Text(
                            formatCurrency(p.price, symbol))),
                        DataCell(Text(
                            formatCurrency(p.cost, symbol))),
                        DataCell(Text(p.trackInventory
                            ? '${p.stockQuantity}'
                            : '-')),
                        DataCell(Switch(
                          value: p.available,
                          onChanged: (v) async {
                            await ref
                                .read(databaseProvider)
                                .productsDao
                                .toggleAvailability(p.id, v);
                            setState(() {});
                          },
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () =>
                                  _showProductForm(context, p),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  size: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error),
                              onPressed: () =>
                                  _confirmDelete(context, p),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProductForm(
      BuildContext context, Product? product) async {
    await showDialog(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
    setState(() {});
  }

  Future<void> _confirmDelete(
      BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${product.name}"?'),
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
          .productsDao
          .deleteProduct(product.id);
      setState(() {});
    }
  }
}

class _ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;
  const _ProductFormDialog({this.product});

  @override
  ConsumerState<_ProductFormDialog> createState() =>
      _ProductFormDialogState();
}

class _ProductFormDialogState
    extends ConsumerState<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _taxRateCtrl;

  int? _categoryId;
  bool _available = true;
  bool _trackInventory = false;
  String? _imagePath;
  // IVA por producto (4.5). null = heredar el default global de Configuración.
  bool? _taxIncluded;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? '${p.price}' : '');
    _costCtrl =
        TextEditingController(text: p != null ? '${p.cost}' : '0');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _stockCtrl = TextEditingController(
        text: p != null ? '${p.stockQuantity}' : '0');
    _minStockCtrl =
        TextEditingController(text: p != null ? '${p.minStock}' : '5');
    _taxRateCtrl =
        TextEditingController(text: p?.taxRate != null ? '${p!.taxRate}' : '');
    _categoryId = p?.categoryId;
    _available = p?.available ?? true;
    _trackInventory = p?.trackInventory ?? false;
    _taxIncluded = p?.taxIncluded;
    _imagePath = p?.imagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _skuCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? [];

    return AlertDialog(
      title: Text(
          widget.product == null ? 'Nuevo producto' : 'Editar producto'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                  controller: _descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Precio *'),
                        keyboardType:
                            TextInputType.number,
                        validator: (v) {
                          if (v!.isEmpty) return 'Requerido';
                          if (double.tryParse(v) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _costCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Costo'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration:
                      const InputDecoration(labelText: 'Categoría *'),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _categoryId = v),
                  validator: (v) =>
                      v == null ? 'Selecciona categoría' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _skuCtrl,
                  decoration: const InputDecoration(labelText: 'SKU'),
                ),
                const SizedBox(height: 8),
                // Image picker
                Row(
                  children: [
                    if (_imagePath != null &&
                        File(_imagePath!).existsSync())
                      Image.file(
                        File(_imagePath!),
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Imagen'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Disponible'),
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Rastrear inventario'),
                  value: _trackInventory,
                  onChanged: (v) =>
                      setState(() => _trackInventory = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_trackInventory) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Stock actual'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _minStockCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Stock mínimo'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('IVA (opcional — vacío usa el default global)',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _taxRateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tasa %',
                          hintText: 'global',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _taxIncluded == null
                            ? 'global'
                            : (_taxIncluded! ? 'incluido' : 'anadido'),
                        decoration:
                            const InputDecoration(labelText: 'Modo'),
                        items: const [
                          DropdownMenuItem(
                              value: 'global', child: Text('Usar global')),
                          DropdownMenuItem(
                              value: 'incluido', child: Text('IVA incluido')),
                          DropdownMenuItem(
                              value: 'anadido', child: Text('IVA añadido')),
                        ],
                        onChanged: (v) => setState(() {
                          _taxIncluded = v == 'global'
                              ? null
                              : (v == 'incluido');
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null || result.files.single.path == null) return;

    final appDir = await getApplicationSupportDirectory();
    final imgDir = Directory(p.join(appDir.path, 'images'));
    await imgDir.create(recursive: true);
    final ext =
        p.extension(result.files.single.name);
    final dest = p.join(imgDir.path,
        '${DateTime.now().millisecondsSinceEpoch}$ext');
    await File(result.files.single.path!).copy(dest);
    setState(() => _imagePath = dest);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);

    final companion = ProductsCompanion(
      id: widget.product != null
          ? Value(widget.product!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      description: Value(_descCtrl.text.isEmpty
          ? null
          : _descCtrl.text),
      price: Value(double.parse(_priceCtrl.text)),
      cost: Value(double.tryParse(_costCtrl.text) ?? 0),
      categoryId: Value(_categoryId!),
      sku: Value(_skuCtrl.text.isEmpty ? null : _skuCtrl.text),
      imagePath: Value(_imagePath),
      available: Value(_available),
      trackInventory: Value(_trackInventory),
      stockQuantity: Value(int.tryParse(_stockCtrl.text) ?? 0),
      minStock: Value(int.tryParse(_minStockCtrl.text) ?? 5),
      // IVA por producto: campo vacío / "Usar global" → null = hereda global.
      taxRate: Value(_taxRateCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_taxRateCtrl.text.replaceAll(',', '.'))),
      taxIncluded: Value(_taxIncluded),
      updatedAt: Value(DateTime.now()),
    );

    if (widget.product == null) {
      await db.productsDao.insertProduct(companion);
    } else {
      await db.productsDao.updateProduct(companion);
    }

    if (mounted) Navigator.pop(context);
  }
}
