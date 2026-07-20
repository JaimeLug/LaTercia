import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/providers/settings_provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_version.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/network_info.dart';
import '../../../core/utils/power_service.dart';
import '../widgets/admin_panel.dart';

/// FASE 6 — Pantalla dedicada al equipo/quiosko (antes un par de secciones
/// sueltas dentro de Configuración): modo kiosko, información del sistema
/// (útil sobre todo en Linux sin escritorio a la vista) y las acciones de
/// energía. Todo lo relacionado con "esta computadora" en un solo lugar.
class KioskScreen extends ConsumerStatefulWidget {
  const KioskScreen({super.key});

  @override
  ConsumerState<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends ConsumerState<KioskScreen> {
  List<String> _ips = [];
  BackupInfo? _lastBackup;
  bool _loadedExtras = false;

  // 2026-07-20 — módulo de actualizaciones por USB (ver
  // PLAN_ACTUALIZACION_GRANDE_2026-07.md §7 y UpdateService). El técnico
  // elige la carpeta del paquete (bundle + update_manifest.json) copiada al
  // USB; esta pantalla valida integridad, compara versión y aplica.
  String? _packagePath;
  UpdateManifest? _packageManifest;
  UpdateAvailability? _availability;
  String? _pickError;
  bool _applying = false;
  UpdateApplyResult? _lastApplyResult;

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final ips = await localIpAddresses();
    final backup = await ref.read(backupServiceProvider).lastBackupInfo();
    if (mounted) {
      setState(() {
        _ips = ips;
        _lastBackup = backup;
        _loadedExtras = true;
      });
    }
  }

  Future<void> _setModoKiosko(bool v) => ref
      .read(settingsProvider.notifier)
      .setSetting('modo_kiosko', v.toString());

  Future<void> _confirmPower({required bool reboot}) async {
    final verb = reboot ? 'Reiniciar' : 'Apagar';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿$verb el equipo?'),
        content: Text(reboot
            ? 'La computadora se reiniciará ahora.'
            : 'La computadora se apagará ahora.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true), child: Text(verb)),
        ],
      ),
    );
    if (ok != true) return;
    final done = reboot
        ? await const PowerService().reboot()
        : await const PowerService().shutdown();
    if (!done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'No se pudo $verb el equipo (permisos del sistema). Revisa el log.')),
      );
    }
  }

  Future<void> _confirmRestartApp() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Reiniciar la aplicación?'),
        content: const Text(
            'Cierra y vuelve a abrir La Tercia (no afecta al sistema operativo). '
            'Los datos no se pierden.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reiniciar app')),
        ],
      ),
    );
    if (ok == true) await const PowerService().restartApp();
  }

  /// Carpeta donde vive el bundle instalado (contiene el binario que
  /// `Platform.resolvedExecutable` está corriendo ahora mismo) — el destino
  /// de `UpdateService.applyUpdate`. En sitio es `/opt/latercia`.
  Directory get _installDir =>
      Directory(p.dirname(Platform.resolvedExecutable));

  Future<void> _pickUpdatePackage() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecciona la carpeta del paquete de actualización',
    );
    if (path == null) return; // canceló el diálogo
    setState(() {
      _packagePath = path;
      _packageManifest = null;
      _availability = null;
      _pickError = null;
      _lastApplyResult = null;
    });
    try {
      final manifest = await UpdateService.readManifest(Directory(path));
      final availability =
          await UpdateService.compareToInstalled(Directory(path));
      if (mounted) {
        setState(() {
          _packageManifest = manifest;
          _availability = availability;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _pickError = e.toString());
    }
  }

  Future<void> _applyUpdate() async {
    final path = _packagePath;
    final manifest = _packageManifest;
    if (path == null || manifest == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Aplicar la actualización?'),
        content:
            Text('Se reemplazará la versión instalada ($appVersion) por la '
                '${manifest.version}. La app se respalda automáticamente antes '
                'de aplicar — si algo falla, vuelve sola a la versión actual. '
                'Cierra el turno y evita cobrar mientras se aplica.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aplicar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _applying = true;
      _lastApplyResult = null;
    });
    final result = await UpdateService.applyUpdate(
      packageDir: Directory(path),
      installDir: _installDir,
    );
    if (!mounted) return;
    setState(() {
      _applying = false;
      _lastApplyResult = result;
    });

    if (result.success) {
      final restart = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Actualización aplicada'),
          content: const Text(
              'Lista. Hay que reiniciar la app para usar la versión nueva.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Más tarde')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reiniciar ahora')),
          ],
        ),
      );
      if (restart == true) await const PowerService().restartApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final modoKiosko = settings['modo_kiosko'] == 'true';

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Quiosco'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminPanel(
                  padding: const EdgeInsets.all(18),
                  child: SwitchListTile(
                    title: const Text('Modo kiosko'),
                    subtitle: const Text(
                        'Pantalla completa y bloquea el cierre de la ventana. '
                        'Apágalo aquí para liberarla al instante.'),
                    value: modoKiosko,
                    onChanged: _setModoKiosko,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
                AdminPanel(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Información del equipo',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: LaTerciaColors.darkBrown)),
                      const SizedBox(height: 10),
                      _infoRow('Sistema',
                          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'),
                      _infoRow('Nombre del equipo', Platform.localHostname),
                      _infoRow(
                        'IP en la red',
                        _ips.isEmpty
                            ? (_loadedExtras
                                ? 'Sin red detectada'
                                : 'Cargando…')
                            : _ips.join('  ·  '),
                      ),
                      _infoRow(
                        'Último backup',
                        _lastBackup == null
                            ? (_loadedExtras ? 'Aún ninguno' : 'Cargando…')
                            : '${formatDateTime(_lastBackup!.modified)} · '
                                '${(_lastBackup!.sizeBytes / 1024).toStringAsFixed(0)} KB',
                      ),
                      _infoRow(
                          'Hora del sistema', formatDateTime(DateTime.now())),
                      _infoRow('Versión instalada', appVersion),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminPanel(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Actualizaciones',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: LaTerciaColors.darkBrown)),
                      const SizedBox(height: 4),
                      const Text(
                        'Selecciona la carpeta del paquete copiado al USB '
                        '(bundle + update_manifest.json).',
                        style: TextStyle(
                            fontSize: 12.5, color: LaTerciaColors.tan),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.usb),
                        label: const Text('Buscar paquete'),
                        onPressed: _applying ? null : _pickUpdatePackage,
                      ),
                      if (_packagePath != null) ...[
                        const SizedBox(height: 12),
                        _infoRow('Carpeta', _packagePath!),
                      ],
                      if (_pickError != null) ...[
                        const SizedBox(height: 10),
                        Text('No se pudo leer el paquete: $_pickError',
                            style: const TextStyle(
                                color: LaTerciaColors.danger, fontSize: 12.5)),
                      ],
                      if (_packageManifest != null &&
                          _availability != null) ...[
                        const SizedBox(height: 10),
                        _infoRow(
                            'Versión del paquete', _packageManifest!.version),
                        _infoRow('Archivos',
                            '${_packageManifest!.fileChecksums.length}'),
                        const SizedBox(height: 4),
                        Text(_availabilityLabel(_availability!),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _availability == UpdateAvailability.newer
                                  ? LaTerciaColors.timerOk
                                  : LaTerciaColors.tan,
                            )),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: _applying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.system_update_alt),
                          label: Text(_applying
                              ? 'Aplicando…'
                              : 'Aplicar actualización'),
                          onPressed: (_applying ||
                                  _availability != UpdateAvailability.newer)
                              ? null
                              : _applyUpdate,
                        ),
                      ],
                      if (_lastApplyResult != null &&
                          !_lastApplyResult!.success) ...[
                        const SizedBox(height: 10),
                        Text('No se pudo aplicar: ${_lastApplyResult!.error}',
                            style: const TextStyle(
                                color: LaTerciaColors.danger, fontSize: 12.5)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminPanel(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Acciones',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: LaTerciaColors.darkBrown)),
                      const SizedBox(height: 4),
                      const Text(
                        'Útil en modo kiosko, sin escritorio a la vista.',
                        style: TextStyle(
                            fontSize: 12.5, color: LaTerciaColors.tan),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reiniciar app'),
                            onPressed: _confirmRestartApp,
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Reiniciar equipo'),
                            onPressed: () => _confirmPower(reboot: true),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text('Apagar equipo'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: LaTerciaColors.danger),
                            onPressed: () => _confirmPower(reboot: false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _availabilityLabel(UpdateAvailability a) => switch (a) {
        UpdateAvailability.newer =>
          '✓ Más nueva que la instalada — se puede aplicar.',
        UpdateAvailability.same => 'Es la misma versión que ya está instalada.',
        UpdateAvailability.older =>
          'Es una versión ANTERIOR a la instalada — no se aplica.',
      };

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: LaTerciaColors.tan)),
          ),
          Expanded(
            child: SelectableText(value,
                style:
                    const TextStyle(fontSize: 13, color: LaTerciaColors.cocoa)),
          ),
        ],
      ),
    );
  }
}
