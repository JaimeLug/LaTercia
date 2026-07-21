import 'dart:io';

import 'app_logger.dart';

/// Apagar/reiniciar el equipo o solo la app desde el modo kiosko. Best-effort
/// (nunca lanza). `docs/kiosko.md`.
class PowerService {
  const PowerService();

  Future<bool> shutdown() => _run(
        windows: ['shutdown', '/s', '/t', '0'],
        linuxPrimary: ['systemctl', 'poweroff'],
        linuxFallback: ['shutdown', '-h', 'now'],
      );

  Future<bool> reboot() => _run(
        windows: ['shutdown', '/r', '/t', '0'],
        linuxPrimary: ['systemctl', 'reboot'],
        linuxFallback: ['shutdown', '-r', 'now'],
      );

  /// Reinicia SOLO la app (no el equipo). `docs/kiosko.md`. Nunca retorna.
  Future<void> restartApp() async {
    try {
      await Process.start(
        Platform.resolvedExecutable,
        const <String>[],
        mode: ProcessStartMode.detached,
      );
    } catch (e, st) {
      appLogger.warn(
          'No se pudo relanzar la aplicación automáticamente.', e, st);
    }
    exit(0);
  }

  Future<bool> _run({
    required List<String> windows,
    required List<String> linuxPrimary,
    required List<String> linuxFallback,
  }) async {
    try {
      if (Platform.isWindows) {
        return _exec(windows);
      }
      if (Platform.isLinux) {
        if (await _exec(linuxPrimary)) return true;
        // Fallback si polkit no autorizó systemctl para este usuario.
        return _exec(linuxFallback);
      }
      appLogger.warn('Apagado/reinicio no soportado en esta plataforma.');
      return false;
    } catch (e, st) {
      appLogger.warn('No se pudo apagar/reiniciar el equipo.', e, st);
      return false;
    }
  }

  Future<bool> _exec(List<String> cmd) async {
    try {
      final result = await Process.run(cmd.first, cmd.sublist(1));
      if (result.exitCode == 0) return true;
      appLogger.warn(
          'Comando de energía "${cmd.join(' ')}" salió con ${result.exitCode}: ${result.stderr}');
      return false;
    } catch (e, st) {
      appLogger.warn('Falló el comando de energía "${cmd.join(' ')}".', e, st);
      return false;
    }
  }
}
