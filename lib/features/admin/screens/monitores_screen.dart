import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/services/display_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_panel.dart';

/// Configuración → Monitores: ver los monitores conectados (nombre real,
/// resolución, principal/secundario) y ponerles un nombre amigable que se
/// reutiliza en el selector de la Cocina. `docs/monitores.md`.
class MonitoresScreen extends ConsumerStatefulWidget {
  const MonitoresScreen({super.key});

  @override
  ConsumerState<MonitoresScreen> createState() => _MonitoresScreenState();
}

class _MonitoresScreenState extends ConsumerState<MonitoresScreen> {
  List<MonitorInfo>? _monitors;
  bool _saving = false;
  // Un controller por monitor (por id) para editar su nombre amigable.
  final Map<String, TextEditingController> _ctrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final monitors = await ref.read(displayServiceProvider).list();
    final settings = ref.read(settingsProvider).valueOrNull ?? {};
    final nombres =
        DisplayService.nombresGuardados(settings['monitor_nombres']);
    for (final m in monitors) {
      _ctrls.putIfAbsent(m.id, () => TextEditingController()).text =
          nombres[m.id] ?? '';
    }
    if (mounted) setState(() => _monitors = monitors);
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    final nombres = <String, String>{};
    _ctrls.forEach((id, c) {
      final v = c.text.trim();
      if (v.isNotEmpty) nombres[id] = v;
    });
    await ref
        .read(settingsProvider.notifier)
        .setSetting('monitor_nombres', DisplayService.encodeNombres(nombres));
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombres de monitores guardados.')),
      );
    }
  }

  /// Cambia la resolución con red de seguridad: aplica, pregunta "¿se ve bien?"
  /// con cuenta regresiva y, si no confirmas, revierte sola. Al confirmar, la
  /// guarda para re-aplicarla en el próximo arranque. `docs/monitores.md`.
  Future<void> _cambiarResolucion(MonitorInfo m, String modo) async {
    if (modo == m.currentMode) return;
    final svc = ref.read(displayServiceProvider);
    final anterior = m.currentMode;

    setState(() => _saving = true);
    final ok = await svc.setResolution(m.id, modo);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo cambiar la resolución en este equipo.')));
      return;
    }

    final confirmado = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _ConfirmResolucionDialog(),
        ) ??
        false;

    if (!confirmado) {
      await svc.setResolution(m.id, anterior); // revertir
    } else {
      final settings = ref.read(settingsProvider).valueOrNull ?? {};
      final saved = {
        ...DisplayService.resolucionesGuardadas(
            settings['monitor_resoluciones']),
        m.id: modo,
      };
      await ref.read(settingsProvider.notifier).setSetting(
          'monitor_resoluciones', DisplayService.encodeResoluciones(saved));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final monitors = _monitors;
    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Monitores', actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Actualizar'),
            style: TextButton.styleFrom(
                foregroundColor: LaTerciaColors.burntOrange),
            onPressed: _saving ? null : _load,
          ),
        ),
      ]),
      body: monitors == null
          ? adminLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pon un nombre a cada pantalla para reconocerla fácil. '
                      'Esos nombres aparecen al abrir la Cocina.',
                      style: TextStyle(fontSize: 13, color: LaTerciaColors.tan),
                    ),
                    const SizedBox(height: 16),
                    if (monitors.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.desktop_access_disabled_outlined,
                        message: 'No se detectaron monitores.',
                      )
                    else
                      for (final m in monitors) ...[
                        _monitorCard(m),
                        const SizedBox(height: 12),
                      ],
                    if (monitors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: LaTerciaColors.burntOrange),
                          onPressed: _saving ? null : _guardar,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Guardar nombres',
                                  style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _monitorCard(MonitorInfo m) {
    return AdminPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                    Text(m.systemName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: LaTerciaColors.darkBrown)),
                    Text('${m.resolution} · posición ${m.x}, ${m.y}',
                        style: const TextStyle(
                            fontSize: 12.5, color: LaTerciaColors.tan)),
                  ],
                ),
              ),
              StatusPill(m.isPrimary ? 'Principal · POS' : 'Secundario',
                  tone: m.isPrimary ? StatusTone.info : StatusTone.neutral),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrls[m.id],
            decoration: const InputDecoration(
              labelText: 'Nombre amigable',
              hintText: 'Ej. Cocina pared',
              isDense: true,
            ),
          ),
          if (m.modes.length > 1) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: m.modes.contains(m.currentMode) ? m.currentMode : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Resolución',
                isDense: true,
              ),
              items: [
                for (final mode in m.modes)
                  DropdownMenuItem(
                      value: mode, child: Text(mode.replaceAll('x', '×'))),
              ],
              onChanged: _saving
                  ? null
                  : (v) => v == null ? null : _cambiarResolucion(m, v),
            ),
          ],
          if (m.isPrimary) ...[
            const SizedBox(height: 8),
            const Text(
              'Es la pantalla del POS. La Cocina nunca se abre aquí para no '
              'taparlo.',
              style: TextStyle(fontSize: 12, color: LaTerciaColors.tan),
            ),
          ],
        ],
      ),
    );
  }
}

/// Confirmación con cuenta regresiva tras cambiar la resolución: si el usuario
/// no confirma (p.ej. la pantalla quedó ilegible), se revierte sola.
/// `docs/monitores.md`.
class _ConfirmResolucionDialog extends StatefulWidget {
  const _ConfirmResolucionDialog();

  @override
  State<_ConfirmResolucionDialog> createState() =>
      _ConfirmResolucionDialogState();
}

class _ConfirmResolucionDialogState extends State<_ConfirmResolucionDialog> {
  static const _total = 15;
  int _seconds = _total;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds <= 0) {
        t.cancel();
        Navigator.of(context).pop(false); // se acabó el tiempo → revertir
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Se ve bien?'),
      content: Text(
        'Si no confirmas, la resolución vuelve a la anterior en $_seconds s.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Revertir'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: LaTerciaColors.burntOrange),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sí, mantener'),
        ),
      ],
    );
  }
}
