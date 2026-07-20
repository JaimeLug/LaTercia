import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/services/update_service.dart';
import 'package:latercia/core/utils/app_version.dart';
import 'package:path/path.dart' as p;

/// Módulo de actualizaciones (2026-07-20) — motor de aplicar un paquete
/// (bundle + manifiesto) sobre la instalación existente, con verificación
/// de integridad, swap atómico y rollback. Todo se prueba con directorios
/// temporales reales (no hace falta una instalación de verdad ni Linux).
void main() {
  group('compareVersions', () {
    test('versiones iguales dan 0', () {
      expect(compareVersions('1.2.0', '1.2.0'), 0);
    });

    test('compara por componente, no lexicográficamente', () {
      // Como texto "1.10.0" < "1.9.0" (el '1' pierde contra el '9'), pero
      // como versión 1.10.0 es MAYOR — justo lo que hay que evitar.
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
    });

    test('componentes faltantes cuentan como 0', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.3', '1.2.0'), greaterThan(0));
    });

    test('ignora sufijos no numéricos', () {
      expect(compareVersions('1.2.0-beta', '1.2.0'), 0);
    });
  });

  group('UpdateService — manifiesto', () {
    late Directory tempBase;
    late Directory packageDir;

    setUp(() async {
      tempBase = await Directory.systemTemp.createTemp('latercia_update_test');
      packageDir = Directory(p.join(tempBase.path, 'package'));
      await Directory(p.join(packageDir.path, 'data')).create(recursive: true);
      await File(p.join(packageDir.path, 'latercia')).writeAsString('binario');
      await File(p.join(packageDir.path, 'data', 'a.txt'))
          .writeAsString('contenido A');
    });

    tearDown(() async {
      try {
        await tempBase.delete(recursive: true);
      } catch (_) {}
    });

    test(
        'generateManifest calcula un checksum por archivo, con rutas '
        'portables (/)', () async {
      final manifest = await UpdateService.generateManifest(
          packageDir: packageDir, version: '1.1.0');

      expect(manifest.version, '1.1.0');
      expect(
          manifest.fileChecksums.keys, containsAll(['latercia', 'data/a.txt']));
      // Mismo contenido → mismo checksum (determinista).
      final again = await UpdateService.generateManifest(
          packageDir: packageDir, version: '1.1.0');
      expect(manifest.fileChecksums, again.fileChecksums);
    });

    test('writeManifest + readManifest hacen round-trip fiel', () async {
      final manifest = await UpdateService.generateManifest(
          packageDir: packageDir, version: '2.0.0');
      await UpdateService.writeManifest(packageDir, manifest);

      final read = await UpdateService.readManifest(packageDir);
      expect(read.version, '2.0.0');
      expect(read.fileChecksums, manifest.fileChecksums);
    });

    test('readManifest lanza si no existe el archivo', () async {
      expect(() => UpdateService.readManifest(packageDir),
          throwsA(isA<FormatException>()));
    });

    test('verifyPackage: paquete íntegro no reporta mismatches', () async {
      final manifest = await UpdateService.generateManifest(
          packageDir: packageDir, version: '1.1.0');
      await UpdateService.writeManifest(packageDir, manifest);

      expect(await UpdateService.verifyPackage(packageDir), isEmpty);
    });

    test('verifyPackage detecta un archivo alterado tras el manifiesto',
        () async {
      final manifest = await UpdateService.generateManifest(
          packageDir: packageDir, version: '1.1.0');
      await UpdateService.writeManifest(packageDir, manifest);

      // Se corrompe el binario DESPUÉS de generar el manifiesto — el
      // escenario real que justifica todo este mecanismo.
      await File(p.join(packageDir.path, 'latercia'))
          .writeAsString('binario CORRUPTO');

      final mismatches = await UpdateService.verifyPackage(packageDir);
      expect(mismatches, contains('latercia'));
      expect(mismatches, isNot(contains('data/a.txt')));
    });

    test('verifyPackage detecta un archivo faltante', () async {
      final manifest = await UpdateService.generateManifest(
          packageDir: packageDir, version: '1.1.0');
      await UpdateService.writeManifest(packageDir, manifest);

      await File(p.join(packageDir.path, 'data', 'a.txt')).delete();

      expect(await UpdateService.verifyPackage(packageDir),
          contains('data/a.txt'));
    });

    test('compareToInstalled detecta newer/same/older', () async {
      final manifest = await UpdateService.generateManifest(
          packageDir: packageDir, version: '1.2.0');
      await UpdateService.writeManifest(packageDir, manifest);

      expect(
          await UpdateService.compareToInstalled(packageDir,
              currentVersion: '1.1.0'),
          UpdateAvailability.newer);
      expect(
          await UpdateService.compareToInstalled(packageDir,
              currentVersion: '1.2.0'),
          UpdateAvailability.same);
      expect(
          await UpdateService.compareToInstalled(packageDir,
              currentVersion: '1.3.0'),
          UpdateAvailability.older);
    });
  });

  group('UpdateService.applyUpdate', () {
    late Directory tempBase;
    late Directory installDir;
    late Directory packageDir;

    setUp(() async {
      tempBase =
          await Directory.systemTemp.createTemp('latercia_update_apply_test');
      installDir = Directory(p.join(tempBase.path, 'latercia'));
      await installDir.create(recursive: true);
      await File(p.join(installDir.path, 'latercia'))
          .writeAsString('binario VIEJO');

      packageDir = Directory(p.join(tempBase.path, 'usb_package'));
      await packageDir.create(recursive: true);
      await File(p.join(packageDir.path, 'latercia'))
          .writeAsString('binario NUEVO');
      final manifest = await UpdateService.generateManifest(
          packageDir: packageDir, version: '1.1.0');
      await UpdateService.writeManifest(packageDir, manifest);
    });

    tearDown(() async {
      try {
        await tempBase.delete(recursive: true);
      } catch (_) {}
    });

    test('caso feliz: instala lo nuevo y deja el viejo respaldado', () async {
      final result = await UpdateService.applyUpdate(
          packageDir: packageDir, installDir: installDir);

      expect(result.success, isTrue);
      expect(result.backupPath, isNotNull);

      final activo =
          await File(p.join(installDir.path, 'latercia')).readAsString();
      expect(activo, 'binario NUEVO');

      final backup = Directory(result.backupPath!);
      expect(await backup.exists(), isTrue);
      final respaldado =
          await File(p.join(backup.path, 'latercia')).readAsString();
      expect(respaldado, 'binario VIEJO');
    });

    test('paquete corrupto: aborta SIN tocar la instalación actual', () async {
      // Corrompe el paquete después de generar su manifiesto.
      await File(p.join(packageDir.path, 'latercia'))
          .writeAsString('binario CORRUPTO');

      final result = await UpdateService.applyUpdate(
          packageDir: packageDir, installDir: installDir);

      expect(result.success, isFalse);
      expect(result.error, contains('corrupto'));

      // installDir no se tocó en absoluto.
      final activo =
          await File(p.join(installDir.path, 'latercia')).readAsString();
      expect(activo, 'binario VIEJO');
      // Y no quedó ningún directorio de backup huérfano.
      expect(
          await tempBase
              .list()
              .where((e) => p.basename(e.path).contains('.backup-'))
              .isEmpty,
          isTrue);
    });

    test('installDir inexistente da un error claro (no crashea)', () async {
      final noExiste = Directory(p.join(tempBase.path, 'no-existe'));
      final result = await UpdateService.applyUpdate(
          packageDir: packageDir, installDir: noExiste);

      expect(result.success, isFalse);
      expect(result.error, contains('no existe'));
    });
  });

  group('UpdateService.rollback', () {
    late Directory tempBase;
    late Directory installDir;

    setUp(() async {
      tempBase =
          await Directory.systemTemp.createTemp('latercia_rollback_test');
      installDir = Directory(p.join(tempBase.path, 'latercia'));
      await installDir.create(recursive: true);
    });

    tearDown(() async {
      try {
        await tempBase.delete(recursive: true);
      } catch (_) {}
    });

    Future<Directory> makePackage(String tag, String version) async {
      final dir = Directory(p.join(tempBase.path, 'pkg_$tag'));
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'latercia')).writeAsString('binario $tag');
      final manifest = await UpdateService.generateManifest(
          packageDir: dir, version: version);
      await UpdateService.writeManifest(dir, manifest);
      return dir;
    }

    test('sin backups disponibles, da un error claro', () async {
      final result = await UpdateService.rollback(installDir);
      expect(result.success, isFalse);
      expect(result.error, contains('respaldo'));
    });

    test('restaura el backup más reciente, no el primero', () async {
      await File(p.join(installDir.path, 'latercia')).writeAsString('v1');

      // v1 → v2 (crea backup de v1) → v3 (crea backup de v2).
      final pkgV2 = await makePackage('v2', '2.0.0');
      final r1 = await UpdateService.applyUpdate(
          packageDir: pkgV2, installDir: installDir);
      expect(r1.success, isTrue);

      // Pausa mínima para garantizar timestamps distintos entre backups.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final pkgV3 = await makePackage('v3', '3.0.0');
      final r2 = await UpdateService.applyUpdate(
          packageDir: pkgV3, installDir: installDir);
      expect(r2.success, isTrue);

      // Ahora mismo installDir tiene v3, y hay 2 backups: uno con v1 y otro
      // con v2. El rollback debe traer v2 (el más reciente), no v1.
      final rollbackResult = await UpdateService.rollback(installDir);
      expect(rollbackResult.success, isTrue);

      final activo =
          await File(p.join(installDir.path, 'latercia')).readAsString();
      expect(activo, 'binario v2',
          reason: 'debe restaurar el backup más reciente (v2), no v1');
    });
  });
}
