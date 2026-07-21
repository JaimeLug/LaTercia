// Parseo de modificadores de un item de pedido, compartido por las tarjetas y
// la vista All-day del KDS. `docs/kds.md` §Modificadores.

import 'dart:convert';

/// Un modificador ya parseado, listo para mostrar en el KDS.
class KdsModifier {
  const KdsModifier({required this.name, required this.included});

  final String name;
  final bool included;

  /// Texto a mostrar: "Extra shot" o "Leche de almendra (incluido)".
  String get label => included ? '$name (incluido)' : name;
}

/// Parsea [OrderItem.modifiersJson]; nunca lanza. `docs/kds.md` §Modificadores.
/// Devuelve lista MUTABLE (no `const []`): la vista All-day la ordena con
/// `..sort(...)` y un `const` lanzaría `Unsupported operation`.
List<KdsModifier> parseKdsModifiers(String? json) {
  if (json == null || json.isEmpty) return <KdsModifier>[];
  try {
    final list = jsonDecode(json) as List;
    return list
        .cast<Map<String, dynamic>>()
        .map((m) => KdsModifier(
              name: (m['name'] as String?) ?? '',
              included: m['included'] == true,
            ))
        .toList();
  } catch (_) {
    return <KdsModifier>[];
  }
}
