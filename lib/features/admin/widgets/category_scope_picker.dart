import 'package:flutter/material.dart';

/// Selector múltiple genérico (checkboxes de strings), compartido por
/// Modificadores (categorías) y Descuentos/Fidelización (productos) — todos
/// usan el mismo criterio de alcance: CSV case-insensitive de nombres; vacío
/// = aplica a todas/os. `docs/promociones.md`, `docs/fidelizacion.md`.
Future<Set<String>?> showCategoryScopePicker(
  BuildContext context, {
  required List<String> categories,
  required Set<String> initialSelected,
  String title = 'Alcance por categoría',
  String emptyLabel = 'No hay categorías todavía.',
}) {
  return showDialog<Set<String>>(
    context: context,
    builder: (_) => _CategoryScopePickerDialog(
      categories: categories,
      initialSelected: initialSelected,
      title: title,
      emptyLabel: emptyLabel,
    ),
  );
}

class _CategoryScopePickerDialog extends StatefulWidget {
  final List<String> categories;
  final Set<String> initialSelected;
  final String title;
  final String emptyLabel;
  const _CategoryScopePickerDialog({
    required this.categories,
    required this.initialSelected,
    required this.title,
    required this.emptyLabel,
  });

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
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: widget.categories.isEmpty
            ? Text(widget.emptyLabel)
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
