import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import '../../core/theme/app_theme.dart';

/// Un display es "principal" si su origen está en (0,0). El POS se abre ahí
/// (centrado), así que abrir el KDS a pantalla completa en ese monitor taparía
/// el POS sin forma de cerrarlo. `docs/kds.md`.
bool kdsDisplayIsPrimary(Display d) =>
    (d.visiblePosition?.dx ?? 0) == 0 && (d.visiblePosition?.dy ?? 0) == 0;

/// Monitores donde SÍ se puede abrir el KDS: todos menos el principal (el del
/// POS). Evita el bloqueo reportado en sitio (la Cocina tapaba el POS).
List<Display> kdsTargetDisplays(List<Display> all) =>
    all.where((d) => !kdsDisplayIsPrimary(d)).toList();

/// Muestra el selector "¿En qué pantalla?" para abrir la Cocina · KDS. Si se
/// elige un monitor, lanza el KDS como ventana aparte en esa pantalla; devuelve
/// `true` solo si el usuario elige "Esta ventana" (KDS embebido).
Future<bool> showKdsScreenPicker(BuildContext context) async {
  final displays = await screenRetriever.getAllDisplays();
  if (!context.mounted) return false;

  final choice = await showDialog<_KdsChoice>(
    context: context,
    builder: (ctx) => _KdsPickerDialog(displays: displays),
  );

  if (choice == null) return false;
  if (choice.embed) return true;

  final d = choice.display!;
  final x = (d.visiblePosition?.dx ?? 0).toInt();
  final y = (d.visiblePosition?.dy ?? 0).toInt();
  final w = (d.visibleSize?.width ?? d.size.width).toInt();
  final h = (d.visibleSize?.height ?? d.size.height).toInt();
  Process.start(Platform.resolvedExecutable, [
    'kds',
    '--x=$x',
    '--y=$y',
    '--w=$w',
    '--h=$h',
  ]);
  return false;
}

class _KdsChoice {
  final bool embed;
  final Display? display;
  const _KdsChoice.embed()
      : embed = true,
        display = null;
  const _KdsChoice.monitor(this.display) : embed = false;
}

class _KdsPickerDialog extends StatelessWidget {
  final List<Display> displays;
  const _KdsPickerDialog({required this.displays});

  /// Monitores ofrecibles (secundarios) con su número original de pantalla,
  /// para etiquetarlos "Pantalla N" de forma estable.
  List<({int index, Display display})> get _targets => [
        for (var i = 0; i < displays.length; i++)
          if (!kdsDisplayIsPrimary(displays[i]))
            (index: i, display: displays[i]),
      ];

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
              for (final t in _targets)
                _OptionTile(
                  title: 'Pantalla ${t.index + 1}',
                  subtitle: 'Monitor secundario · '
                      '${(t.display.visibleSize?.width ?? t.display.size.width).toInt()}×${(t.display.visibleSize?.height ?? t.display.size.height).toInt()}',
                  onTap: () =>
                      Navigator.pop(context, _KdsChoice.monitor(t.display)),
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
