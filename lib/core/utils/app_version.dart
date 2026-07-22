/// Versión instalada; fuente única de verdad. Subir a mano junto con `version:`
/// en `pubspec.yaml` en cada release. `docs/actualizaciones.md`.
const String appVersion = '1.3.1';

/// Compara versiones tipo "1.2.0" componente a componente (no como texto).
/// Devuelve <0/0/>0. `docs/actualizaciones.md` §"Comparar versiones".
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
