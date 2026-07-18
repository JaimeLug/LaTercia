import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/category_icons.dart';

/// Diálogo de selección de ícono para categorías — reemplaza el campo de
/// texto libre "Emoji/Icono" por una cuadrícula de Material Icons.
/// Devuelve la clave elegida (ver `categoryIconCatalog`), o null si se
/// canceló.
Future<String?> showCategoryIconPicker(
    BuildContext context, String? current) {
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: LaTerciaColors.creamAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Elegir ícono'),
      content: SizedBox(
        width: 400,
        child: GridView.count(
          crossAxisCount: 6,
          shrinkWrap: true,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: categoryIconCatalog.entries.map((entry) {
            final selected = entry.key == current;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.pop(context, entry.key),
              child: Container(
                decoration: BoxDecoration(
                  color: selected
                      ? LaTerciaColors.burntOrange.withValues(alpha: 0.15)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? LaTerciaColors.burntOrange
                        : LaTerciaColors.border,
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Icon(entry.value,
                    color: selected
                        ? LaTerciaColors.burntOrange
                        : LaTerciaColors.cocoa),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}
