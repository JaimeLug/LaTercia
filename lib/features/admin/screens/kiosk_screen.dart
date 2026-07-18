import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/theme/app_theme.dart';
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
              onPressed: () => Navigator.pop(context, true),
              child: Text(verb)),
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
                            ? (_loadedExtras ? 'Sin red detectada' : 'Cargando…')
                            : _ips.join('  ·  '),
                      ),
                      _infoRow(
                        'Último backup',
                        _lastBackup == null
                            ? (_loadedExtras ? 'Aún ninguno' : 'Cargando…')
                            : '${formatDateTime(_lastBackup!.modified)} · '
                                '${(_lastBackup!.sizeBytes / 1024).toStringAsFixed(0)} KB',
                      ),
                      _infoRow('Hora del sistema', formatDateTime(DateTime.now())),
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
                style: const TextStyle(
                    fontSize: 13, color: LaTerciaColors.cocoa)),
          ),
        ],
      ),
    );
  }
}
