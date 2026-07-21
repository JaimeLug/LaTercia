import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../utils/app_version.dart';

/// Nombre del archivo de manifiesto dentro de un paquete de actualización.
const kUpdateManifestFileName = 'update_manifest.json';

/// Manifiesto de un paquete: versión + sha256 de cada archivo, para verificar
/// integridad antes de aplicar. `docs/actualizaciones.md` §"El paquete".
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

/// Motor de actualización por USB (verificar, swap atómico, rollback). Dart
/// puro, sin Flutter. `docs/actualizaciones.md` §"Motor de actualización".
class UpdateService {
  UpdateService._();

  /// Calcula el sha256 de cada archivo de [packageDir]. Se corre una vez al
  /// preparar el paquete, no en la máquina que lo recibe.
  /// `docs/actualizaciones.md`.
  static Future<UpdateManifest> generateManifest({
    required Directory packageDir,
    required String version,
  }) async {
    final checksums = <String, String>{};
    await for (final entity
        in packageDir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: packageDir.path);
      // Separadores a '/' para que el manifiesto sea igual en Windows y Linux.
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

  /// Verifica los checksums de [packageDir]; devuelve las rutas que no
  /// coinciden o faltan (vacío = íntegro). Solo lectura.
  /// `docs/actualizaciones.md`.
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

  /// Aplica la actualización de [packageDir] sobre [installDir] con swap
  /// atómico y rollback automático. Si algo falla antes de respaldar, no toca
  /// nada. `docs/actualizaciones.md` §"Aplicar (swap atómico con rollback)".
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
    // El timestamp identifica el backup y ordena el rollback; se incrementa
    // hasta no chocar con uno existente. docs/actualizaciones.md.
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

    // Defensa en profundidad: reverifica el staging antes de tocar installDir.
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
      // (Sin appLogger a propósito: este servicio es Dart puro.)
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

  /// Revierte [installDir] al respaldo más reciente que exista junto a él.
  /// `docs/actualizaciones.md` §Revertir.
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
