import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/services/display_service.dart';
import '../../core/theme/app_theme.dart';

/// Monitores donde SÍ se puede abrir el KDS: todos menos el principal (el del
/// POS). El KDS abre a pantalla completa y sin barra de título; en el monitor
/// del POS lo taparía sin forma de cerrarlo (bloqueo reportado en sitio).
/// `docs/monitores.md`, `docs/kds.md`.
List<MonitorInfo> kdsTargetMonitors(List<MonitorInfo> all) =>
    all.where((m) => !m.isPrimary).toList();

/// Muestra el selector "¿En qué pantalla?" para abrir la Cocina · KDS. Si se
/// elige un monitor, lanza el KDS como ventana aparte en esa pantalla; devuelve
/// `true` solo si el usuario elige "Esta ventana" (KDS embebido).
Future<bool> showKdsScreenPicker(BuildContext context, WidgetRef ref) async {
  final monitors = await ref.read(displayServiceProvider).list();
  final settings = ref.read(settingsProvider).valueOrNull ?? {};
  final nombres = DisplayService.nombresGuardados(settings['monitor_nombres']);
  if (!context.mounted) return false;

  final choice = await showDialog<_KdsChoice>(
    context: context,
    builder: (ctx) => _KdsPickerDialog(monitors: monitors, nombres: nombres),
  );

  if (choice == null) return false;
  if (choice.embed) return true;

  final m = choice.monitor!;
  Process.start(Platform.resolvedExecutable, [
    'kds',
    '--x=${m.x}',
    '--y=${m.y}',
    '--w=${m.width}',
    '--h=${m.height}',
  ]);
  return false;
}

class _KdsChoice {
  final bool embed;
  final MonitorInfo? monitor;
  const _KdsChoice.embed()
      : embed = true,
        monitor = null;
  const _KdsChoice.monitor(this.monitor) : embed = false;
}

class _KdsPickerDialog extends StatelessWidget {
  final List<MonitorInfo> monitors;
  final Map<String, String> nombres;
  const _KdsPickerDialog({required this.monitors, required this.nombres});

  /// Solo monitores secundarios (nunca el del POS). `docs/monitores.md`.
  List<MonitorInfo> get _targets => kdsTargetMonitors(monitors);

  String _label(MonitorInfo m) {
    final amigable = nombres[m.id];
    return (amigable != null && amigable.isNotEmpty) ? amigable : m.systemName;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ABRIR COCINA · KDS',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 2,
                  color: LaTerciaColors.burntOrange,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '¿En qué pantalla?',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 4),
              const Text(
                'Elige el monitor de cocina. La pantalla del POS no aparece '
                'aquí para no taparla por accidente.',
                style: TextStyle(color: LaTerciaColors.tan),
              ),
              const SizedBox(height: 20),
              for (final m in _targets)
                _OptionTile(
                  title: _label(m),
                  subtitle: 'Monitor secundario · ${m.systemName} · '
                      '${m.resolution}',
                  onTap: () => Navigator.pop(context, _KdsChoice.monitor(m)),
                ),
              if (_targets.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'No se detectó un segundo monitor. La cocina se abrirá en '
                    'esta misma ventana.',
                    style: TextStyle(color: LaTerciaColors.tan, fontSize: 13),
                  ),
                ),
              _OptionTile(
                title: 'Esta ventana',
                subtitle: 'Mostrar aquí mismo',
                onTap: () => Navigator.pop(context, const _KdsChoice.embed()),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LaTerciaColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: LaTerciaColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.desktop_windows_outlined,
                      color: LaTerciaColors.cocoa),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: LaTerciaColors.darkBrown)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: LaTerciaColors.tan)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: LaTerciaColors.successBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DISPONIBLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: LaTerciaColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
