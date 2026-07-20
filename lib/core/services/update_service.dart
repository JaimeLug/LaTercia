import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../utils/app_version.dart';

/// Nombre del archivo de manifiesto dentro de un paquete de actualización.
const kUpdateManifestFileName = 'update_manifest.json';

/// Manifiesto de un paquete de actualización: versión + checksum sha256 de
/// cada archivo, para poder verificar integridad ANTES de aplicar nada.
class UpdateManifest {
  const UpdateManifest({required this.version, required this.fileChecksums});

  final String version;

  /// Ruta relativa dentro del paquete (con `/`, portable entre Windows y
  /// Linux) → sha256 en hex.
  final Map<String, String> fileChecksums;

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    if (rawFiles is! Map) {
      throw const FormatException('Manifiesto inválido: falta "files".');
    }
    return UpdateManifest(
      version: json['version'] as String? ?? '',
      fileChecksums: rawFiles.map((k, v) => MapEntry(k as String, v as String)),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'generatedAt': DateTime.now().toIso8601String(),
        'files': fileChecksums,
      };
}

/// Cómo se compara la versión de un paquete contra la instalada.
enum UpdateAvailability { newer, same, older }

/// Resultado de aplicar (o revertir) una actualización.
class UpdateApplyResult {
  const UpdateApplyResult({required this.success, this.error, this.backupPath});

  final bool success;
  final String? error;
  final String? backupPath;
}

/// Motor de actualizaciones (2026-07-20) — ver
/// `PLAN_ACTUALIZACION_GRANDE_2026-07.md` §7 para el diseño completo.
/// Empieza por actualización vía USB; OTA por red queda para cuando haya
/// varias sucursales.
///
/// Es manipulación de archivos pura, sin nada de Flutter/UI — por eso se
/// puede probar de punta a punta con directorios temporales, sin necesitar
/// una instalación real ni estar en Linux.
class UpdateService {
  UpdateService._();

  /// Recorre [packageDir] y calcula el sha256 de cada archivo, para producir
  /// el manifiesto que viaja junto al bundle en el USB. Se corre UNA vez, al
  /// preparar el paquete (ver `tool/generate_update_manifest.dart`) — nunca
  /// en la máquina que recibe la actualización.
  static Future<UpdateManifest> generateManifest({
    required Directory packageDir,
    required String version,
  }) async {
    final checksums = <String, String>{};
    await for (final entity
        in packageDir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: packageDir.path);
      // Normaliza separadores: el manifiesto debe ser idéntico sin importar
      // si se generó en Windows (VM/dev) o en Linux (donde se aplica).
      final relPortable = p.split(rel).join('/');
      if (relPortable == kUpdateManifestFileName) continue;
      final bytes = await entity.readAsBytes();
      checksums[relPortable] = sha256.convert(bytes).toString();
    }
    return UpdateManifest(version: version, fileChecksums: checksums);
  }

  /// Escribe [manifest] como `update_manifest.json` dentro de [packageDir].
  static Future<File> writeManifest(
    Directory packageDir,
    UpdateManifest manifest,
  ) async {
    final file = File(p.join(packageDir.path, kUpdateManifestFileName));
    await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest.toJson()));
    return file;
  }

  /// Lee el manifiesto de [packageDir]. Lanza [FormatException] si no existe
  /// o está corrupto — un paquete sin manifiesto válido nunca se aplica.
  static Future<UpdateManifest> readManifest(Directory packageDir) async {
    final file = File(p.join(packageDir.path, kUpdateManifestFileName));
    if (!await file.exists()) {
      throw const FormatException(
          'El paquete no trae update_manifest.json — no se puede '
          'verificar su integridad.');
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Manifiesto corrupto (no es un objeto JSON).');
    }
    return UpdateManifest.fromJson(decoded);
  }

  /// Verifica que cada archivo listado en el manifiesto de [packageDir]
  /// coincida con su checksum (y que no falte ninguno). Devuelve la lista de
  /// rutas relativas que NO coinciden o faltan — vacía si el paquete está
  /// íntegro. Nunca toca nada fuera de [packageDir]; es solo lectura.
  static Future<List<String>> verifyPackage(Directory packageDir) async {
    final manifest = await readManifest(packageDir);
    final mismatches = <String>[];
    for (final entry in manifest.fileChecksums.entries) {
      final file = File(p.joinAll([packageDir.path, ...entry.key.split('/')]));
      if (!await file.exists()) {
        mismatches.add(entry.key);
        continue;
      }
      final actual = sha256.convert(await file.readAsBytes()).toString();
      if (actual != entry.value) {
        mismatches.add(entry.key);
      }
    }
    return mismatches;
  }

  /// Compara la versión de [packageDir] (según su manifiesto) contra
  /// [currentVersion] (por defecto, la instalada — [appVersion]).
  static Future<UpdateAvailability> compareToInstalled(
    Directory packageDir, {
    String currentVersion = appVersion,
  }) async {
    final manifest = await readManifest(packageDir);
    final cmp = compareVersions(manifest.version, currentVersion);
    if (cmp > 0) return UpdateAvailability.newer;
    if (cmp < 0) return UpdateAvailability.older;
    return UpdateAvailability.same;
  }

  /// Aplica la actualización de [packageDir] sobre [installDir]:
  ///
  /// 1. Verifica integridad (checksum de CADA archivo) — si algo no cuadra,
  ///    aborta sin tocar `installDir`.
  /// 2. Copia el paquete a una carpeta de staging en el MISMO volumen que
  ///    `installDir` (el paquete puede venir de un USB en otro volumen —
  ///    copiar ahí no es atómico, pero todavía no toca la instalación viva).
  /// 3. Verifica la copia otra vez (defensa en profundidad).
  /// 4. Respalda `installDir` (rename — atómico, mismo volumen) a
  ///    `<installDir>.backup-<timestamp>`.
  /// 5. Renombra el staging a `installDir` (rename — atómico).
  /// 6. Si el paso 5 falla, restaura el backup automáticamente — nunca deja
  ///    la PC sin una app funcional.
  ///
  /// Si algo falla ANTES del paso 4, `installDir` no se toca en absoluto.
  static Future<UpdateApplyResult> applyUpdate({
    required Directory packageDir,
    required Directory installDir,
  }) async {
    final List<String> mismatches;
    try {
      mismatches = await verifyPackage(packageDir);
    } catch (e) {
      return UpdateApplyResult(
          success: false, error: 'No se pudo verificar el paquete: $e');
    }
    if (mismatches.isNotEmpty) {
      return UpdateApplyResult(
        success: false,
        error: 'Paquete corrupto o incompleto: ${mismatches.length} '
            'archivo(s) no coinciden con el manifiesto '
            '(${mismatches.take(3).join(', ')}'
            '${mismatches.length > 3 ? ', ...' : ''}).',
      );
    }
    if (!await installDir.exists()) {
      return UpdateApplyResult(
          success: false,
          error: 'La instalación actual (${installDir.path}) no existe.');
    }

    final parent = installDir.parent;
    // El timestamp identifica el backup y decide el orden para [rollback];
    // se incrementa hasta que no choque con uno existente — dos
    // actualizaciones seguidas y rápidas podrían caer en el mismo
    // milisegundo si no se hiciera esto.
    var stamp = DateTime.now().millisecondsSinceEpoch;
    var backupDir = Directory('${installDir.path}.backup-$stamp');
    while (await backupDir.exists()) {
      stamp++;
      backupDir = Directory('${installDir.path}.backup-$stamp');
    }
    final stagingDir = Directory(p.join(parent.path, '.update-staging-$stamp'));

    try {
      await _copyDirectory(packageDir, stagingDir);
    } catch (e) {
      await _tryDelete(stagingDir);
      return UpdateApplyResult(
          success: false, error: 'No se pudo copiar el paquete: $e');
    }

    // Verificación extra tras la copia: confirma que la copia a
    // `stagingDir` también quedó íntegra antes de tocar `installDir`.
    final stagedMismatches = await verifyPackage(stagingDir);
    if (stagedMismatches.isNotEmpty) {
      await _tryDelete(stagingDir);
      return UpdateApplyResult(
        success: false,
        error: 'La copia del paquete quedó incompleta '
            '(${stagedMismatches.length} archivo(s)); no se tocó la '
            'instalación actual.',
      );
    }

    try {
      await installDir.rename(backupDir.path);
    } catch (e) {
      await _tryDelete(stagingDir);
      return UpdateApplyResult(
          success: false,
          error: 'No se pudo respaldar la instalación actual: $e');
    }

    try {
      await stagingDir.rename(installDir.path);
    } catch (e) {
      // Rollback automático: restaura el backup para no dejar la PC sin app.
      // (El detalle del error queda en UpdateApplyResult.error — sin
      // appLogger aquí a propósito: este servicio es Dart puro, sin nada de
      // Flutter, para poder correr también fuera de la app como script vía
      // `dart run tool/generate_update_manifest.dart`.)
      try {
        await backupDir.rename(installDir.path);
      } catch (_) {
        return UpdateApplyResult(
          success: false,
          error: 'Fallo crítico: no se pudo activar la actualización NI '
              'restaurar el respaldo. Backup en: ${backupDir.path}',
          backupPath: backupDir.path,
        );
      }
      await _tryDelete(stagingDir);
      return UpdateApplyResult(
        success: false,
        error: 'No se pudo activar la actualización ($e); se restauró la '
            'versión anterior automáticamente.',
      );
    }

    return UpdateApplyResult(success: true, backupPath: backupDir.path);
  }

  /// Revierte manualmente [installDir] al respaldo más reciente que exista
  /// junto a él (`<installDir>.backup-<timestamp>`). Para deshacer una
  /// actualización problemática después del hecho.
  static Future<UpdateApplyResult> rollback(Directory installDir) async {
    final parent = installDir.parent;
    if (!await parent.exists()) {
      return const UpdateApplyResult(
          success: false, error: 'No se encontró el directorio padre.');
    }
    final name = p.basename(installDir.path);
    final prefix = '$name.backup-';

    final candidates = <MapEntry<int, Directory>>[];
    await for (final entity in parent.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final base = p.basename(entity.path);
      if (!base.startsWith(prefix)) continue;
      final stamp = int.tryParse(base.substring(prefix.length));
      if (stamp != null) candidates.add(MapEntry(stamp, entity));
    }
    if (candidates.isEmpty) {
      return const UpdateApplyResult(
          success: false, error: 'No hay ningún respaldo disponible.');
    }
    candidates.sort((a, b) => b.key.compareTo(a.key));
    final latest = candidates.first.value;

    final asideStamp = DateTime.now().millisecondsSinceEpoch;
    final aside = Directory('${installDir.path}.rolled-back-$asideStamp');
    if (await installDir.exists()) {
      try {
        await installDir.rename(aside.path);
      } catch (e) {
        return UpdateApplyResult(
            success: false,
            error: 'No se pudo apartar la instalación actual: $e');
      }
    }
    try {
      await latest.rename(installDir.path);
    } catch (e) {
      if (await aside.exists()) {
        await aside.rename(installDir.path);
      }
      return UpdateApplyResult(
          success: false, error: 'No se pudo restaurar el respaldo: $e');
    }
    return UpdateApplyResult(success: true, backupPath: latest.path);
  }

  static Future<void> _copyDirectory(Directory src, Directory dest) async {
    await dest.create(recursive: true);
    await for (final entity in src.list(recursive: false, followLinks: false)) {
      final name = p.basename(entity.path);
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(p.join(dest.path, name)));
      } else if (entity is File) {
        await entity.copy(p.join(dest.path, name));
      }
    }
  }

  static Future<void> _tryDelete(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Best-effort: un directorio de staging huérfano no es crítico —
      // el técnico puede borrarlo a mano si sobra espacio.
    }
  }
}
