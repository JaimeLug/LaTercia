import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_panel.dart';
import '../widgets/botonera_status_card.dart';

/// FASE 3.5 — Pantalla dedicada a la botonera de cocina (ESP32 por WiFi), como
/// su propia sección del menú (no un apartado dentro de Configuración): activar,
/// puerto del servidor, IP de esta máquina y el panel de prueba en vivo.
class BotoneraScreen extends ConsumerStatefulWidget {
  const BotoneraScreen({super.key});

  @override
  ConsumerState<BotoneraScreen> createState() => _BotoneraScreenState();
}

class _BotoneraScreenState extends ConsumerState<BotoneraScreen> {
  late TextEditingController _puerto;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _puerto = TextEditingController();
  }

  @override
  void dispose() {
    _puerto.dispose();
    super.dispose();
  }

  void _loadOnce(Map<String, String> s) {
    if (_loaded) return;
    _loaded = true;
    _puerto.text = s['botonera_puerto'] ?? '8080';
  }

  Future<void> _setActiva(bool v) =>
      ref.read(settingsProvider.notifier).setSetting('botonera_activa', v.toString());

  Future<void> _guardarPuerto() async {
    final v = _puerto.text.trim().isEmpty ? '8080' : _puerto.text.trim();
    _puerto.text = v;
    await ref.read(settingsProvider.notifier).setSetting('botonera_puerto', v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puerto guardado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull ?? {};
    _loadOnce(settings);
    final activa = settings['botonera_activa'] == 'true';

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: adminAppBar('Botonera · Cocina'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        title: const Text('Activar botonera'),
                        subtitle: const Text(
                            'Botonera física ESP32 por WiFi para marcar/navegar '
                            'órdenes en el KDS sin tocar pantalla.'),
                        value: activa,
                        onChanged: _setActiva,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (activa) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _puerto,
                                decoration: const InputDecoration(
                                  labelText: 'Puerto del servidor',
                                  helperText:
                                      'Debe coincidir con el puerto grabado en '
                                      'el firmware del ESP32 (por defecto 8080).',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: FilledButton(
                                onPressed: _guardarPuerto,
                                child: const Text('Guardar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (activa) ...[
                  const SizedBox(height: 16),
                  const BotoneraStatusCard(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
