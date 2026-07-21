import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../utils/app_logger.dart';

/// Un monitor detectado, con lo necesario para mostrarlo, cambiarle la
/// resolución y lanzar el KDS en él. `docs/monitores.md`.
class MonitorInfo {
  const MonitorInfo({
    required this.id,
    required this.systemName,
    required this.width,
    required this.height,
    required this.x,
    required this.y,
    required this.isPrimary,
    this.modes = const [],
  });

  /// Clave estable para guardar nombre/resolución (conector en Linux, id de
  /// screen_retriever en otros SO).
  final String id;

  /// Nombre del sistema a mostrar (ej. `DP-1`, `HDMI-1`).
  final String systemName;
  final int width, height, x, y;
  final bool isPrimary;

  /// Resoluciones disponibles (ej. `1920x1080`), en el orden que las lista
  /// `xrandr`. Vacío fuera de Linux (no se puede cambiar resolución ahí).
  final List<String> modes;

  /// Resolución actual como la usa `xrandr` (con `x` minúscula, para casar con
  /// [modes]).
  String get currentMode => '${width}x$height';

  /// Resolución para mostrar (con `×`).
  String get resolution => '$width×$height';
}

/// Decodifica un mapa `{id: valor}` de un setting JSON; tolera null/corrupto.
Map<String, String> _decodeMap(String? raw) {
  if (raw == null || raw.isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return {
        for (final e in decoded.entries) e.key.toString(): e.value.toString()
      };
    }
  } catch (_) {/* setting corrupto: se ignora */}
  return const {};
}

/// Parsea la salida de `xrandr --query`. Puro (sin BD ni SO): testeable.
/// Toma cada salida CONECTADA con geometría `<W>x<H>+<X>+<Y>` y sus modos
/// (las líneas indentadas de abajo). `docs/monitores.md`.
List<MonitorInfo> parseXrandr(String output) {
  // "DP-1 connected primary 1920x1080+0+0 (normal ...) 527mm x 296mm"
  final connRe =
      RegExp(r'^(\S+) connected (primary )?(\d+)x(\d+)\+(\d+)\+(\d+)');
  // "   1920x1080     60.00*+  59.94"
  final modeRe = RegExp(r'^\s+(\d+x\d+)\b');

  final result = <MonitorInfo>[];
  String? id;
  int w = 0, h = 0, x = 0, y = 0;
  bool primary = false;
  var modes = <String>[];

  void flush() {
    if (id != null) {
      result.add(MonitorInfo(
        id: id!,
        systemName: id!,
        width: w,
        height: h,
        x: x,
        y: y,
        isPrimary: primary,
        modes: modes,
      ));
    }
    id = null;
    primary = false;
    modes = <String>[];
  }

  for (final line in output.split('\n')) {
    final conn = connRe.firstMatch(line);
    if (conn != null) {
      flush();
      id = conn.group(1);
      primary = conn.group(2) != null;
      w = int.parse(conn.group(3)!);
      h = int.parse(conn.group(4)!);
      x = int.parse(conn.group(5)!);
      y = int.parse(conn.group(6)!);
      continue;
    }
    final indented = line.startsWith(' ') || line.startsWith('\t');
    if (!indented) {
      // Línea no indentada que no es "connected" (ej. "OUT disconnected",
      // "Screen 0: ...") → cierra el monitor actual.
      flush();
      continue;
    }
    if (id != null) {
      final mode = modeRe.firstMatch(line);
      if (mode != null && !modes.contains(mode.group(1))) {
        modes.add(mode.group(1)!);
      }
    }
  }
  flush();
  return result;
}

/// Lista los monitores conectados, cambia su resolución y administra sus
/// nombres amigables. `docs/monitores.md`.
class DisplayService {
  const DisplayService();

  /// Los monitores conectados. En Linux vía `xrandr` (nombres reales +
  /// resoluciones); en el resto vía `screen_retriever` (sin modos).
  Future<List<MonitorInfo>> list() async {
    if (Platform.isLinux) {
      try {
        final r = await Process.run('xrandr', ['--query']);
        if (r.exitCode == 0) {
          final parsed = parseXrandr(r.stdout as String);
          if (parsed.isNotEmpty) return parsed;
        }
      } catch (e, st) {
        appLogger.warn('xrandr no disponible; se usa screen_retriever.', e, st);
      }
    }
    return _fromScreenRetriever();
  }

  Future<List<MonitorInfo>> _fromScreenRetriever() async {
    final displays = await screenRetriever.getAllDisplays();
    return [
      for (final d in displays)
        MonitorInfo(
          id: d.id,
          systemName: (d.name != null && d.name!.isNotEmpty)
              ? d.name!
              : 'Pantalla ${d.id}',
          width: (d.visibleSize?.width ?? d.size.width).toInt(),
          height: (d.visibleSize?.height ?? d.size.height).toInt(),
          x: (d.visiblePosition?.dx ?? 0).toInt(),
          y: (d.visiblePosition?.dy ?? 0).toInt(),
          isPrimary: (d.visiblePosition?.dx ?? 0) == 0 &&
              (d.visiblePosition?.dy ?? 0) == 0,
        ),
    ];
  }

  /// Cambia la resolución de [connector] a [mode] (ej. `1920x1080`) vía
  /// `xrandr`. Solo Linux. Best-effort: devuelve si funcionó.
  /// `docs/monitores.md`.
  Future<bool> setResolution(String connector, String mode) async {
    if (!Platform.isLinux) return false;
    try {
      final r =
          await Process.run('xrandr', ['--output', connector, '--mode', mode]);
      if (r.exitCode == 0) return true;
      appLogger.warn('xrandr --mode falló ($connector $mode): ${r.stderr}');
      return false;
    } catch (e, st) {
      appLogger.warn(
          'No se pudo cambiar la resolución ($connector $mode).', e, st);
      return false;
    }
  }

  /// Re-aplica al arranque las resoluciones guardadas, SOLO si el modo sigue
  /// disponible (evita dejar una pantalla mal en un boot desatendido, donde no
  /// hay nadie para revertir). Best-effort. `docs/monitores.md`.
  Future<void> applySavedResolutions(Map<String, String> saved) async {
    if (!Platform.isLinux || saved.isEmpty) return;
    final live = await list();
    for (final m in live) {
      final wanted = saved[m.id];
      if (wanted == null || wanted == m.currentMode) continue;
      if (!m.modes.contains(wanted)) continue; // no disponible: no arriesgar
      await setResolution(m.id, wanted);
    }
  }

  /// Nombres amigables por id, del setting `monitor_nombres`.
  static Map<String, String> nombresGuardados(String? raw) => _decodeMap(raw);
  static String encodeNombres(Map<String, String> m) => jsonEncode(m);

  /// Resoluciones elegidas por id, del setting `monitor_resoluciones`.
  static Map<String, String> resolucionesGuardadas(String? raw) =>
      _decodeMap(raw);
  static String encodeResoluciones(Map<String, String> m) => jsonEncode(m);
}

final displayServiceProvider =
    Provider<DisplayService>((_) => const DisplayService());
