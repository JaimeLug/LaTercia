// Genera update_manifest.json para un bundle compilado (Módulo de
// actualizaciones, 2026-07-20 — ver PLAN_ACTUALIZACION_GRANDE_2026-07.md §7).
//
// Uso, DESPUÉS de compilar el bundle nuevo:
//   flutter build linux --release
//   dart run tool/generate_update_manifest.dart \
//       build/linux/x64/release/bundle 1.1.0
//
// Deja `update_manifest.json` dentro de esa misma carpeta bundle/ — cópiala
// junto con el bundle al USB de despliegue. `UpdateService.applyUpdate` (en
// la app) usa ese manifiesto para verificar que el paquete llegó completo e
// intacto antes de aplicarlo sobre la instalación existente.
import 'dart:io';

import 'package:latercia/core/services/update_service.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
        'Uso: dart run tool/generate_update_manifest.dart <ruta_del_bundle> <version>');
    stderr.writeln(
        'Ejemplo: dart run tool/generate_update_manifest.dart build/linux/x64/release/bundle 1.1.0');
    exit(64); // EX_USAGE
  }

  final bundlePath = args[0];
  final version = args[1];
  final bundleDir = Directory(bundlePath);

  if (!await bundleDir.exists()) {
    stderr.writeln('No existe el directorio: $bundlePath');
    exit(66); // EX_NOINPUT
  }

  stdout.writeln('Calculando checksums de $bundlePath ...');
  final manifest = await UpdateService.generateManifest(
    packageDir: bundleDir,
    version: version,
  );
  final file = await UpdateService.writeManifest(bundleDir, manifest);

  stdout.writeln('Listo: ${file.path}');
  stdout.writeln('  Versión: ${manifest.version}');
  stdout.writeln('  Archivos: ${manifest.fileChecksums.length}');
}
