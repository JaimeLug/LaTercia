// Lógica pura del cursor de la botonera del KDS. `docs/kds.md`.

/// Selección efectiva a resaltar/operar (la actual si sigue activa, si no la
/// primera; null si no hay órdenes). `docs/kds.md` §"Cursor de tarjeta
/// seleccionada".
int? effectiveSelection(List<int> activeIds, int? selected) {
  if (activeIds.isEmpty) return null;
  if (selected != null && activeIds.contains(selected)) return selected;
  return activeIds.first;
}

/// Próxima selección tras marcar `removedId` como "listo". `docs/kds.md`
/// §"Encadenar listo, listo, listo".
int? nextAfterReady(List<int> idsBeforeRemoval, int removedId) {
  final idx = idsBeforeRemoval.indexOf(removedId);
  if (idx == -1) return null;
  final remaining = [...idsBeforeRemoval]..removeAt(idx);
  if (remaining.isEmpty) return null;
  // La que estaba después de la removida pasa a esa misma posición; si era
  // la última, se envuelve a la primera.
  final nextIdx = idx >= remaining.length ? 0 : idx;
  return remaining[nextIdx];
}
