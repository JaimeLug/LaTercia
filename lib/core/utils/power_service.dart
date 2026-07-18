import 'dart:io';

import 'app_logger.dart';

/// FASE 6 — Apagar/reiniciar el equipo desde la app. Necesario en modo kiosko:
/// como no hay escritorio ni menú del sistema a la vista, el apagado/reinicio
/// se hace desde Configuración.
///
/// Estrategia por plataforma:
/// - Windows: `shutdown /s|/r /t 0` (spooler estándar del SO).
/// - Linux: `systemctl poweroff|reboot` (una sesión local activa suele estar
///   autorizada por polkit sin contraseña); si falla, intenta `shutdown`.
///
/// Best-effort: devuelve `true` si el comando arrancó con éxito; nunca lanza.
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

  /// Reinicia SOLO la app (no el equipo): relanza un proceso nuevo, detached
  /// para que sobreviva a este cerrando, y termina el actual. Útil tras
  /// cambios de configuración o si la app se ve rara, sin esperar un reinicio
  /// completo del sistema. Nunca retorna (el proceso actual termina).
  Future<void> restartApp() async {
    try {
      await Process.start(
        Platform.resolvedExecutable,
        const <String>[],
        mode: ProcessStartMode.detached,
      );
    } catch (e, st) {
      appLogger.warn('No se pudo relanzar la aplicación automáticamente.', e, st);
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
