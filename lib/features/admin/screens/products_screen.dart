import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import '../../../core/database/database.dart';
import '../../../core/database/daos/recipes_dao.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/sat_catalog_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../widgets/admin_panel.dart';
import '../widgets/sat_clave_picker.dart';

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
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Productos'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: LaTerciaColors.burntOrange,
        onPressed: () => _showProductForm(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                _CategoryFilter(
                  value: _filterCategoryId,
                  categories: categories,
                  onChanged: (v) => setState(() => _filterCategoryId = v),
                ),
              ],
            ),
          ),
          // Scroll VERTICAL explícito: sin esto, con suficientes productos y
          // la ventana achicada la lista se sale por abajo (overflow).
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: ref.read(databaseProvider).productsDao.getAllProducts(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) return adminLoading();
                var products = snapshot.data!;
                if (_filterCategoryId != null) {
                  products = products
                      .where((p) => p.categoryId == _filterCategoryId)
                      .toList();
                }
                if (_search.isNotEmpty) {
                  products = products
                      .where((p) =>
                          p.name.toLowerCase().contains(_search.toLowerCase()))
                      .toList();
                }
                if (products.isEmpty) {
                  return const AdminEmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: 'Sin productos con estos filtros.',
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: AdminPanel(
                    child: Column(
                      children: [
                        const AdminHeaderRow(cells: [
                          Expanded(flex: 3, child: Text('NOMBRE')),
                          Expanded(flex: 2, child: Text('CATEGORÍA')),
                          Expanded(flex: 2, child: Text('PRECIO')),
                          Expanded(flex: 2, child: Text('COSTO')),
                          Expanded(
                              flex: 1, child: Center(child: Text('STOCK'))),
                          Expanded(
                              flex: 2, child: Center(child: Text('RASTREAR'))),
                          Expanded(
                              flex: 2,
                              child: Center(child: Text('DISPONIBLE'))),
                          SizedBox(width: 88, child: Text('ACCIONES')),
                        ]),
                        ...products.asMap().entries.map((entry) {
                          final p = entry.value;
                          final isLast = entry.key == products.length - 1;
                          final cat = categories
                              .where((c) => c.id == p.categoryId)
                              .firstOrNull;
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
                              Expanded(flex: 2, child: Text(cat?.name ?? '—')),
                              Expanded(
                                flex: 2,
                                child: Text(formatCurrency(p.price, symbol),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                              Expanded(
                                  flex: 2,
                                  child: Text(formatCurrency(p.cost, symbol),
                                      style: const TextStyle(
                                          color: LaTerciaColors.tan))),
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Text(p.trackInventory
                                      ? '${p.stockQuantity}'
                                      : '—'),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: p.usesRecipe
                                      ? const Tooltip(
                                          message:
                                              'Usa receta (insumos) — el stock '
                                              'simple no aplica',
                                          child: Icon(Icons.eco_outlined,
                                              size: 18,
                                              color: LaTerciaColors.tan),
                                        )
                                      : Switch(
                                          value: p.trackInventory,
                                          activeColor:
                                              LaTerciaColors.burntOrange,
                                          onChanged: (v) async {
                                            await ref
                                                .read(databaseProvider)
                                                .productsDao
                                                .toggleTrackInventory(p.id, v);
                                            setState(() {});
                                          },
                                        ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Switch(
                                    value: p.available,
                                    activeColor: LaTerciaColors.burntOrange,
                                    onChanged: (v) async {
                                      await ref
                                          .read(databaseProvider)
                                          .productsDao
                                          .toggleAvailability(p.id, v);
                                      setState(() {});
                                    },
                                  ),
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
                                      onPressed: () =>
                                          _showProductForm(context, p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18,
                                          color: LaTerciaColors.danger),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          _confirmDelete(context, p),
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
          ),
        ],
      ),
    );
  }

  Future<void> _showProductForm(BuildContext context, Product? product) async {
    await showDialog(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
    setState(() {});
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
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
    if (confirmed != true) return;
    try {
      await ref.read(databaseProvider).productsDao.deleteProduct(product.id);
      setState(() {});
    } on SqliteException catch (_) {
      // FK constraint (foreign_keys=ON desde v6): el producto ya tiene
      // órdenes/receta apuntándole — no se puede borrar sin dejar huérfanos.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No se puede eliminar: el producto ya tiene ventas o una receta asociada.'),
          ),
        );
      }
    }
  }
}

class _ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product;
  const _ProductFormDialog({this.product});

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
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

  // FASE 7 — Receta (insumos), mutuamente excluyente con el stock simple.
  bool _usesRecipe = false;
  final List<_RecipeLine> _recipeLines = [];
  late Future<List<Ingredient>> _ingredientsFuture;

  // Facturación (CFDI 4.0): claves SAT del producto. docs/facturacion.md.
  String? _claveProdServ, _claveProdServDesc;
  String? _claveUnidad, _claveUnidadDesc;
  String? _objetoImp;
  List<SatEntry> _objetoImpOpciones = const [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p != null ? '${p.price}' : '');
    _costCtrl = TextEditingController(text: p != null ? '${p.cost}' : '0');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _stockCtrl =
        TextEditingController(text: p != null ? '${p.stockQuantity}' : '0');
    _minStockCtrl =
        TextEditingController(text: p != null ? '${p.minStock}' : '5');
    _taxRateCtrl =
        TextEditingController(text: p?.taxRate != null ? '${p!.taxRate}' : '');
    _categoryId = p?.categoryId;
    _available = p?.available ?? true;
    _trackInventory = p?.trackInventory ?? false;
    _taxIncluded = p?.taxIncluded;
    _imagePath = p?.imagePath;
    _usesRecipe = p?.usesRecipe ?? false;
    _claveProdServ = p?.claveProdServ;
    _claveUnidad = p?.claveUnidad;
    _objetoImp = p?.objetoImp;
    _loadFiscalCatalog();

    final db = ref.read(databaseProvider);
    _ingredientsFuture = db.ingredientsDao.getActiveIngredients();
    if (p != null) {
      db.recipesDao.getRecipeForProduct(p.id).then((lines) {
        if (!mounted) return;
        setState(() {
          _recipeLines.addAll(lines.map((l) => _RecipeLine(
                ingredientId: l.item.ingredientId,
                qtyCtrl: TextEditingController(text: '${l.item.quantity}'),
              )));
        });
      });
    }
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
    for (final l in _recipeLines) {
      l.qtyCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final insumosActivo =
        (ref.watch(settingsProvider).valueOrNull ?? {})['insumos_activo'] ==
            'true';

    return AlertDialog(
      title:
          Text(widget.product == null ? 'Nuevo producto' : 'Editar producto'),
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
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Precio *'),
                        keyboardType: TextInputType.number,
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
                        decoration: const InputDecoration(labelText: 'Costo'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría *'),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? 'Selecciona categoría' : null,
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
                    if (_imagePath != null && File(_imagePath!).existsSync())
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
                if (!_usesRecipe) ...[
                  SwitchListTile(
                    title: const Text('Rastrear inventario'),
                    value: _trackInventory,
                    onChanged: (v) => setState(() => _trackInventory = v),
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
                ],
                // FASE 7 — Receta (insumos): mutuamente excluyente con el
                // stock simple de arriba, solo visible si el sistema de
                // insumos está activo en Configuración → Insumos.
                if (insumosActivo) ...[
                  SwitchListTile(
                    title: const Text('Usa receta (consume insumos)'),
                    subtitle: const Text(
                        'Al vender, descuenta los insumos de la receta en '
                        'vez del stock simple de arriba.'),
                    value: _usesRecipe,
                    onChanged: (v) => setState(() {
                      _usesRecipe = v;
                      if (v) _trackInventory = false;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_usesRecipe) _buildRecipeEditor(),
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
                        decoration: const InputDecoration(labelText: 'Modo'),
                        items: const [
                          DropdownMenuItem(
                              value: 'global', child: Text('Usar global')),
                          DropdownMenuItem(
                              value: 'incluido', child: Text('IVA incluido')),
                          DropdownMenuItem(
                              value: 'anadido', child: Text('IVA añadido')),
                        ],
                        onChanged: (v) => setState(() {
                          _taxIncluded =
                              v == 'global' ? null : (v == 'incluido');
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFiscalSection(),
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

  Widget _buildRecipeEditor() {
    return FutureBuilder<List<Ingredient>>(
      future: _ingredientsFuture,
      builder: (ctx, snapshot) {
        final ingredients = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          );
        }
        if (ingredients.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
                'No hay insumos activos — da de alta uno en Admin → Insumos primero.',
                style: TextStyle(color: LaTerciaColors.tan)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _recipeLines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        value: _recipeLines[i].ingredientId,
                        decoration: const InputDecoration(labelText: 'Insumo'),
                        items: ingredients
                            .map((ing) => DropdownMenuItem(
                                value: ing.id, child: Text(ing.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _recipeLines[i].ingredientId = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _recipeLines[i].qtyCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Cantidad'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: LaTerciaColors.danger),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        _recipeLines[i].qtyCtrl.dispose();
                        _recipeLines.removeAt(i);
                      }),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _recipeLines
                    .add(_RecipeLine(qtyCtrl: TextEditingController()))),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar insumo'),
              ),
            ),
          ],
        );
      },
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
    final ext = p.extension(result.files.single.name);
    final dest =
        p.join(imgDir.path, '${DateTime.now().millisecondsSinceEpoch}$ext');
    await File(result.files.single.path!).copy(dest);
    setState(() => _imagePath = dest);
  }

  Future<void> _loadFiscalCatalog() async {
    final cat = ref.read(satCatalogServiceProvider);
    final objetos = await cat.objetosImp();
    final prodDesc = _claveProdServ == null
        ? null
        : await cat.descripcionDe('clave_prod_serv', _claveProdServ!);
    final unidadDesc = _claveUnidad == null
        ? null
        : await cat.descripcionDe('clave_unidad', _claveUnidad!);
    if (!mounted) return;
    setState(() {
      _objetoImpOpciones = objetos;
      _claveProdServDesc = prodDesc;
      _claveUnidadDesc = unidadDesc;
    });
  }

  /// Sección de claves SAT del producto. docs/facturacion.md §"Catálogos SAT".
  Widget _buildFiscalSection() {
    final cat = ref.read(satCatalogServiceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 8),
        const Text('Datos fiscales (SAT)',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: LaTerciaColors.darkBrown)),
        const Text(
          'Para facturación (CFDI 4.0). Opcional; solo si vas a facturar '
          'este producto.',
          style: TextStyle(fontSize: 12, color: LaTerciaColors.tan),
        ),
        const SizedBox(height: 8),
        _claveField(
          label: 'Clave producto/servicio',
          value: _claveProdServ,
          desc: _claveProdServDesc,
          onPick: () async {
            final e = await showSatClavePicker(
              context,
              titulo: 'Clave producto/servicio',
              search: cat.searchClaveProdServ,
              sugeridas: cat.sugeridasCafeteria,
            );
            if (e != null) {
              setState(() {
                _claveProdServ = e.id;
                _claveProdServDesc = e.texto;
              });
            }
          },
          onClear: () => setState(() {
            _claveProdServ = null;
            _claveProdServDesc = null;
          }),
        ),
        const SizedBox(height: 8),
        _claveField(
          label: 'Clave unidad',
          value: _claveUnidad,
          desc: _claveUnidadDesc,
          onPick: () async {
            final e = await showSatClavePicker(
              context,
              titulo: 'Clave unidad',
              search: cat.searchClaveUnidad,
            );
            if (e != null) {
              setState(() {
                _claveUnidad = e.id;
                _claveUnidadDesc = e.texto;
              });
            }
          },
          onClear: () => setState(() {
            _claveUnidad = null;
            _claveUnidadDesc = null;
          }),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: _objetoImp,
          decoration: const InputDecoration(labelText: 'Objeto de impuesto'),
          items: [
            const DropdownMenuItem(value: null, child: Text('—')),
            for (final o in _objetoImpOpciones)
              DropdownMenuItem(
                value: o.id,
                child: Text('${o.id} · ${o.texto}',
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _objetoImp = v),
        ),
      ],
    );
  }

  Widget _claveField({
    required String label,
    String? value,
    String? desc,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: Row(
        children: [
          Expanded(
            child: value == null
                ? const Text('Sin asignar',
                    style: TextStyle(color: LaTerciaColors.tan))
                : Text('$value${desc != null ? ' · $desc' : ''}',
                    overflow: TextOverflow.ellipsis),
          ),
          if (value != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
            ),
          IconButton(
            icon: const Icon(Icons.search, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onPick,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);

    final companion = ProductsCompanion(
      id: widget.product != null
          ? Value(widget.product!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      description: Value(_descCtrl.text.isEmpty ? null : _descCtrl.text),
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
      usesRecipe: Value(_usesRecipe),
      claveProdServ: Value(_claveProdServ),
      claveUnidad: Value(_claveUnidad),
      objetoImp: Value(_objetoImp),
      updatedAt: Value(DateTime.now()),
    );

    int productId;
    if (widget.product == null) {
      productId = await db.productsDao.insertProduct(companion);
    } else {
      productId = widget.product!.id;
      await db.productsDao.updateProduct(companion);
    }

    // Lista vacía si se desactivó la receta — limpia cualquier línea previa.
    final recipeDrafts = _usesRecipe
        ? _recipeLines
            .where((l) =>
                l.ingredientId != null &&
                (double.tryParse(l.qtyCtrl.text) ?? 0) > 0)
            .map((l) => RecipeLineDraft(
                ingredientId: l.ingredientId!,
                quantity: double.parse(l.qtyCtrl.text)))
            .toList()
        : <RecipeLineDraft>[];
    await db.recipesDao.setRecipe(productId, recipeDrafts);

    if (mounted) Navigator.pop(context);
  }
}

class _RecipeLine {
  int? ingredientId;
  final TextEditingController qtyCtrl;
  _RecipeLine({this.ingredientId, required this.qtyCtrl});
}

/// Filtro de categoría con el estilo de marca (reemplaza el `DropdownButton`
/// Material default).
class _CategoryFilter extends StatelessWidget {
  final int? value;
  final List<Category> categories;
  final ValueChanged<int?> onChanged;
  const _CategoryFilter({
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: LaTerciaColors.creamAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: LaTerciaColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          hint: const Text('Categoría'),
          icon: const Icon(Icons.expand_more,
              size: 18, color: LaTerciaColors.tan),
          style: const TextStyle(
              color: LaTerciaColors.cocoa,
              fontSize: 13.5,
              fontWeight: FontWeight.w600),
          dropdownColor: LaTerciaColors.creamAlt,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
            ...categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
