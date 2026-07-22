import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/settings_provider.dart';
import '../widgets/admin_panel.dart';
import '../widgets/category_scope_picker.dart';

/// Productos → pestaña "Modificadores". Sin AppBar propio: vive embebida
/// dentro del `TabBarView` de `ProductsScreen`, cuyo `TabBar` ya muestra el
/// título.
class ModifiersScreen extends ConsumerStatefulWidget {
  const ModifiersScreen({super.key});

  @override
  ConsumerState<ModifiersScreen> createState() => _ModifiersScreenState();
}

class _ModifiersScreenState extends ConsumerState<ModifiersScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  // Se cargan una vez y se filtran en memoria: así el buscador no reconsulta
  // ni parpadea con cada tecla.
  List<Modifier>? _mods;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final mods =
        await ref.read(databaseProvider).modifiersDao.getAllModifiers();
    if (mounted) setState(() => _mods = mods);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';
    final mods = _mods;

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: LaTerciaColors.burntOrange,
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: mods == null
          ? adminLoading()
          : mods.isEmpty
              ? const AdminEmptyState(
                  icon: Icons.tune,
                  message: 'Sin modificadores todavía.\n'
                      'Toca “+” para crear el primero (ej. “Sin azúcar”, '
                      '“Extra shot”).',
                )
              : _buildList(mods, symbol),
    );
  }

  Widget _buildList(List<Modifier> mods, String symbol) {
    final q = _search.trim().toLowerCase();
    final filtered = q.isEmpty
        ? mods
        : mods
            .where((m) =>
                m.name.toLowerCase().contains(q) ||
                (m.categoryScope ?? '').toLowerCase().contains(q))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: AdminSearchField(
            controller: _searchCtrl,
            hintText: 'Buscar modificador...',
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? AdminEmptyState(
                  icon: Icons.search_off,
                  message: 'Sin resultados para “$_search”.',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: AdminPanel(
                    child: Column(
                      children: [
                        const AdminHeaderRow(cells: [
                          Expanded(flex: 3, child: Text('NOMBRE')),
                          Expanded(flex: 2, child: Text('DELTA PRECIO')),
                          Expanded(flex: 2, child: Text('ALCANCE')),
                          SizedBox(width: 88, child: Text('ACCIONES')),
                        ]),
                        ...filtered.asMap().entries.map((entry) {
                          final m = entry.value;
                          final isLast = entry.key == filtered.length - 1;
                          return AdminRow(
                            isLast: isLast,
                            cells: [
                              Expanded(
                                flex: 3,
                                child: Text(m.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: LaTerciaColors.darkBrown)),
                              ),
                              Expanded(
                                flex: 2,
                                child: m.priceDelta == 0
                                    ? const Text('Sin costo',
                                        style: TextStyle(
                                            color: LaTerciaColors.tan))
                                    : Text(
                                        m.priceDelta > 0
                                            ? '+${formatCurrency(m.priceDelta, symbol)}'
                                            : formatCurrency(
                                                m.priceDelta, symbol),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: LaTerciaColors.success)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(m.categoryScope ?? 'Todas'),
                              ),
                              SizedBox(
                                width: 88,
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18, color: LaTerciaColors.tan),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _showForm(context, m),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18,
                                          color: LaTerciaColors.danger),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () async {
                                        await ref
                                            .read(databaseProvider)
                                            .modifiersDao
                                            .deleteModifier(m.id);
                                        await _load();
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
                ),
        ),
      ],
    );
  }

  Future<void> _showForm(BuildContext context, Modifier? modifier) async {
    await showDialog(
      context: context,
      builder: (_) => _ModifierFormDialog(modifier: modifier),
    );
    await _load();
  }
}

class _ModifierFormDialog extends ConsumerStatefulWidget {
  final Modifier? modifier;
  const _ModifierFormDialog({this.modifier});

  @override
  ConsumerState<_ModifierFormDialog> createState() =>
      _ModifierFormDialogState();
}

class _ModifierFormDialogState extends ConsumerState<_ModifierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _deltaCtrl;
  // FASE 8 — categorías elegidas del catálogo real (antes texto libre). Vacío
  // = aplica a todas.
  late Set<String> _scopeCategories;

  @override
  void initState() {
    super.initState();
    final m = widget.modifier;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _deltaCtrl =
        TextEditingController(text: m != null ? '${m.priceDelta}' : '0');
    _scopeCategories = (m?.categoryScope ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _deltaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickScope() async {
    final categories =
        await ref.read(databaseProvider).categoriesDao.getAllCategories();
    if (!mounted) return;
    final result = await showCategoryScopePicker(
      context,
      categories: categories.map((c) => c.name).toList(),
      initialSelected: _scopeCategories,
    );
    if (result != null) setState(() => _scopeCategories = result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.modifier == null ? 'Nuevo modificador' : 'Editar modificador'),
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
              controller: _deltaCtrl,
              decoration:
                  const InputDecoration(labelText: 'Costo extra (0 = gratis)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickScope,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Alcance',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: _scopeCategories.isEmpty
                    ? const Text('Todas las categorías',
                        style: TextStyle(color: LaTerciaColors.tan))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _scopeCategories
                            .map((c) => Chip(
                                  label: Text(c,
                                      style: const TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
              ),
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
    final companion = ModifiersCompanion(
      id: widget.modifier != null
          ? Value(widget.modifier!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      priceDelta: Value(double.tryParse(_deltaCtrl.text) ?? 0),
      categoryScope:
          Value(_scopeCategories.isEmpty ? null : _scopeCategories.join(',')),
    );

    if (widget.modifier == null) {
      await db.modifiersDao.insertModifier(companion);
    } else {
      await db.modifiersDao.updateModifier(companion);
    }
    if (mounted) Navigator.pop(context);
  }
}
