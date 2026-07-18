// Lógica pura del cursor de "tarjeta seleccionada" del KDS (botonera física,
// 3.5) — separada de `KdsScreen` para poder testearla sin montar widgets.

/// La selección efectiva a usar/resaltar: la actual si sigue siendo una orden
/// activa, o si no (nunca se eligió, o la seleccionada ya no está activa) la
/// primera de la lista. Devuelve null solo si no hay ninguna orden activa.
///
/// Esto es lo que corrige el bug reportado ("el botón de prep/listo solo
/// sirve una vez"): antes, si la selección se perdía (por ejemplo tras
/// marcar "listo"), PREP/LISTO se convertían en no-op silencioso hasta la
/// siguiente pulsación de ANTERIOR/SIGUIENTE — con esto siempre hay una
/// tarjeta operable, aunque nunca se haya navegado.
int? effectiveSelection(List<int> activeIds, int? selected) {
  if (activeIds.isEmpty) return null;
  if (selected != null && activeIds.contains(selected)) return selected;
  return activeIds.first;
}

/// Próxima selección tras marcar `removedId` como "listo" (sale de la lista
/// activa): la que ocupaba la siguiente posición, para que la botonera pueda
/// encadenar LISTO, LISTO, LISTO sin tener que navegar entre cada una — el
/// flujo natural de un bump bar de cocina.
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
