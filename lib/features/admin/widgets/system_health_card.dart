import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';

/// FASE 5.4 — Estado de salud del sistema para el Admin: impresora, botonera,
/// último backup y tamaño de logs. Todo derivado de settings + archivos, sin
/// tocar hardware (no hay ping que pueda colgar la UI).
typedef SystemHealth = ({
  bool printerEnabled,
  String printerDetail,
  bool botoneraEnabled,
  bool backupAuto,
  BackupInfo? lastBackup,
  int logsSizeBytes,
});

final systemHealthProvider =
    FutureProvider.autoDispose<SystemHealth>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = await db.settingsDao.getAllSettings();
  final lastBackup = await ref.watch(backupServiceProvider).lastBackupInfo();
  final logsSize = await appLogger.logsSizeBytes();

  final printerEnabled = settings['impresion_activa'] == 'true';
  final transport = settings['printer_transport'] == 'usb' ? 'USB' : 'red';
  final address = (settings['printer_address'] ?? '').trim();
  final printerDetail = !printerEnabled
      ? 'Desactivada'
      : address.isEmpty
          ? '$transport (sin dirección)'
          : '$transport · $address';

  return (
    printerEnabled: printerEnabled,
    printerDetail: printerDetail,
    botoneraEnabled: settings['botonera_activa'] == 'true',
    backupAuto: settings['backup_auto'] != 'false',
    lastBackup: lastBackup,
    logsSizeBytes: logsSize,
  );
});

String _humanSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class SystemHealthCard extends ConsumerWidget {
  const SystemHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(systemHealthProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Estado del sistema',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Actualizar',
                  onPressed: () => ref.invalidate(systemHealthProvider),
                ),
              ],
            ),
            const SizedBox(height: 8),
            health.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('No se pudo leer el estado: $e'),
              data: (h) {
                final backup = h.lastBackup;
                return Column(
                  children: [
                    _HealthRow(
                      icon: Icons.print_outlined,
                      label: 'Impresora',
                      value: h.printerDetail,
                      ok: h.printerEnabled,
                      neutral: !h.printerEnabled,
                    ),
                    _HealthRow(
                      icon: Icons.gamepad_outlined,
                      label: 'Botonera',
                      value: h.botoneraEnabled
                          ? 'Activada'
                          : 'No configurada',
                      ok: h.botoneraEnabled,
                      neutral: !h.botoneraEnabled,
                    ),
                    _HealthRow(
                      icon: Icons.backup_outlined,
                      label: 'Último backup',
                      value: backup == null
                          ? (h.backupAuto ? 'Aún ninguno' : 'Automático OFF')
                          : '${formatDateTime(backup.modified)} · '
                              '${_humanSize(backup.sizeBytes)}',
                      ok: backup != null,
                      neutral: backup == null,
                      warn: backup != null &&
                          DateTime.now().difference(backup.modified).inDays >= 2,
                    ),
                    _HealthRow(
                      icon: Icons.description_outlined,
                      label: 'Tamaño de logs',
                      value: _humanSize(h.logsSizeBytes),
                      ok: true,
                      neutral: true,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ok;
  final bool neutral;
  final bool warn;
  const _HealthRow({
    required this.icon,
    required this.label,
    required this.value,
    this.ok = false,
    this.neutral = false,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warn
        ? Colors.orange
        : neutral
            ? Colors.grey
            : (ok ? Colors.green : Colors.red);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.black87)),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
