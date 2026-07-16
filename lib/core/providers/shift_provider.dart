import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'database_provider.dart';

/// The single system-wide open shift (or null), watched anywhere the UI
/// needs to react to a shift opening/closing — the POS shift gate, the top
/// nav shift button, etc.
///
/// Call `ref.read(currentShiftProvider.notifier).refresh()` after any action
/// that opens, closes, or otherwise mutates the current shift so watchers
/// pick up the change.
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
