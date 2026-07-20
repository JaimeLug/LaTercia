// Parseo de modificadores de un item de pedido, compartido entre las
// tarjetas del KDS (order_card_kds.dart) y la vista All-day (kds_screen.dart)
// — 2026-07-20, para que "sin azúcar"/"extra shot" también se vean en
// All-day, no solo en las tarjetas.

import 'dart:convert';

/// Un modificador ya parseado, listo para mostrar en el KDS.
class KdsModifier {
  const KdsModifier({required this.name, required this.included});

  final String name;
  final bool included;

  /// Texto a mostrar: "Extra shot" o "Leche de almendra (incluido)".
  String get label => included ? '$name (incluido)' : name;
}

/// Parsea el JSON de modificadores de un item ([OrderItem.modifiersJson]).
/// Nunca lanza: devuelve lista vacía si [json] es nulo, vacío o inválido.
///
/// Siempre una lista MUTABLE (`<KdsModifier>[]`, no `const []`) — quien la
/// use puede necesitar ordenarla (`..sort(...)`, como en la vista All-day) y
/// un literal `const` lanza `Unsupported operation` al intentar mutarlo.
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
