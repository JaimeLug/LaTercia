import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'database_provider.dart';

/// El único turno abierto del sistema (o null). Llamar `refresh()` tras abrir/
/// cerrar/mutar el turno para que los watchers reaccionen.
/// `docs/ventas-cobro-turnos.md` §Turnos.
class CurrentShiftNotifier extends AsyncNotifier<Shift?> {
  @override
  Future<Shift?> build() async {
    final db = ref.watch(databaseProvider);
    return db.shiftsDao.getCurrentOpenShift();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final currentShiftProvider =
    AsyncNotifierProvider<CurrentShiftNotifier, Shift?>(
  CurrentShiftNotifier.new,
);
