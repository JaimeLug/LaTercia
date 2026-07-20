/// Versión de la app instalada — fuente única de verdad para el módulo de
/// actualizaciones (2026-07-20). Debe subirse a mano junto con `version:` en
/// `pubspec.yaml` en cada release (no hay forma cero-dependencias de leer el
/// pubspec propio en runtime sin agregar `package_info_plus`).
const String appVersion = '1.0.0';

/// Compara dos versiones tipo "1.2.0" componente a componente (no
/// lexicográfico: "1.10.0" es MAYOR que "1.9.0", aunque "1.10.0" < "1.9.0"
/// como texto). Componentes faltantes cuentan como 0 ("1.2" == "1.2.0").
/// Ignora cualquier sufijo no numérico tras el primer carácter no dígito de
/// cada componente (p.ej. "1.2.0-beta" se compara como "1.2.0").
///
/// Devuelve <0 si [a] < [b], 0 si son iguales, >0 si [a] > [b].
int compareVersions(String a, String b) {
  final partsA = _parts(a);
  final partsB = _parts(b);
  final len = partsA.length > partsB.length ? partsA.length : partsB.length;
  for (var i = 0; i < len; i++) {
    final va = i < partsA.length ? partsA[i] : 0;
    final vb = i < partsB.length ? partsB[i] : 0;
    if (va != vb) return va - vb;
  }
  return 0;
}

List<int> _parts(String v) => v.split('.').map((p) {
      final digits = RegExp(r'^\d+').stringMatch(p.trim());
      return int.tryParse(digits ?? '') ?? 0;
    }).toList();
