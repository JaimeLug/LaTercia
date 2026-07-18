import 'package:drift/drift.dart' show Value;
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/category_icons.dart';
import '../../../core/utils/app_logger.dart';
import '../widgets/icon_picker.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        data: (cats) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cats.length,
          itemBuilder: (ctx, i) {
            final cat = cats[i];
            final color = _parseColor(cat.color);
            return Card(
              color: color.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color, width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          child: categoryIconWidget(cat.icon, size: 40),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () =>
                              _showForm(context, ref, cat),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .error),
                          onPressed: () => _delete(context, ref, cat),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.brown;
    }
  }

  Future<void> _showForm(
      BuildContext context, WidgetRef ref, Category? cat) async {
    await showDialog(
      context: context,
      builder: (_) => _CategoryFormDialog(category: cat),
    );
    ref.invalidate(categoriesProvider);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${cat.name}"?'),
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
          .categoriesDao
          .deleteCategory(cat.id);
      ref.invalidate(categoriesProvider);
    }
  }
}

class _CategoryFormDialog extends ConsumerStatefulWidget {
  final Category? category;
  const _CategoryFormDialog({this.category});

  @override
  ConsumerState<_CategoryFormDialog> createState() =>
      _CategoryFormDialogState();
}

class _CategoryFormDialogState
    extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _sortCtrl;
  late String _iconKey;
  Color _color = Colors.brown;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _iconKey = c?.icon ?? 'restaurant';
    _sortCtrl = TextEditingController(
        text: c != null ? '${c.sortOrder}' : '0');
    if (c != null) {
      try {
        _color = Color(
            int.parse(c.color.replaceFirst('#', '0xFF')));
      } catch (e, st) {
        appLogger.warn(
            'No se pudo parsear el color de la categoría "${c.name}": ${c.color}',
            e,
            st);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final chosen = await showCategoryIconPicker(context, _iconKey);
    if (chosen != null) setState(() => _iconKey = chosen);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null
          ? 'Nueva categoría'
          : 'Editar categoría'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Ícono:'),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: categoryIconWidget(_iconKey, size: 26),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _pickIcon,
                    child: const Text('Cambiar ícono'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sortCtrl,
                decoration: const InputDecoration(
                    labelText: 'Orden de visualización'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text('Color:'),
              const SizedBox(height: 8),
              ColorPicker(
                color: _color,
                onColorChanged: (c) => setState(() => _color = c),
                width: 36,
                height: 36,
                borderRadius: 22,
                heading: const Text('Color de categoría'),
                subheading: const Text('Selecciona un tono'),
                pickersEnabled: const {
                  ColorPickerType.wheel: true,
                  ColorPickerType.primary: false,
                  ColorPickerType.accent: false,
                },
              ),
            ],
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);
    final colorHex =
        '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

    final companion = CategoriesCompanion(
      id: widget.category != null
          ? Value(widget.category!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      color: Value(colorHex),
      icon: Value(_iconKey),
      sortOrder: Value(int.tryParse(_sortCtrl.text) ?? 0),
    );

    if (widget.category == null) {
      await db.categoriesDao.insertCategory(companion);
    } else {
      await db.categoriesDao.updateCategory(companion);
    }

    if (mounted) Navigator.pop(context);
  }
}
