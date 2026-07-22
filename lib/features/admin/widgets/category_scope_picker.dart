import 'package:flutter/material.dart';

/// Selector múltiple de categorías, compartido por Modificadores y
/// Descuentos (ambos usan el mismo criterio de alcance: CSV case-insensitive
/// de nombres de categoría; vacío = aplica a todas). `docs/promociones.md`.
Future<Set<String>?> showCategoryScopePicker(
  BuildContext context, {
  required List<String> categories,
  required Set<String> initialSelected,
}) {
  return showDialog<Set<String>>(
    context: context,
    builder: (_) => _CategoryScopePickerDialog(
      categories: categories,
      initialSelected: initialSelected,
    ),
  );
}

class _CategoryScopePickerDialog extends StatefulWidget {
  final List<String> categories;
  final Set<String> initialSelected;
  const _CategoryScopePickerDialog(
      {required this.categories, required this.initialSelected});

  @override
  State<_CategoryScopePickerDialog> createState() =>
      _CategoryScopePickerDialogState();
}

class _CategoryScopePickerDialogState
    extends State<_CategoryScopePickerDialog> {
  late Set<String> _selected = Set.from(widget.initialSelected);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alcance por categoría'),
      content: SizedBox(
        width: 360,
        child: widget.categories.isEmpty
            ? const Text('No hay categorías todavía.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.categories
                      .map((c) => CheckboxListTile(
                            title: Text(c),
                            value: _selected.contains(c),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(c);
                              } else {
                                _selected.remove(c);
                              }
                            }),
                          ))
                      .toList(),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _selected = {}),
          child: const Text('Todas (limpiar)'),
        ),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
