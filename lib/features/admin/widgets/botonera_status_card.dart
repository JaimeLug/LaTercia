import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/services/kds_button_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/network_info.dart' as network_info;

/// FASE 3.5 — Panel de prueba de la botonera en Configuración: IP(s) de esta
/// máquina, estado de conexión en vivo, una cuadrícula con los 6 botones
/// esperados (se iluminan al presionarlos) y un historial de los últimos
/// mensajes recibidos — para verificar de punta a punta sin tener que abrir
/// el KDS ni adivinar si un botón físico llega a la app.
///
/// Arranca el servidor por su cuenta (best-effort, con el puerto ya guardado
/// en Configuración) para que la prueba funcione aunque el KDS no esté
/// abierto en ninguna ventana todavía.
class BotoneraStatusCard extends ConsumerStatefulWidget {
  const BotoneraStatusCard({super.key});

  @override
  ConsumerState<BotoneraStatusCard> createState() =>
      _BotoneraStatusCardState();
}

class _LogEntry {
  final String raw;
  final KdsButton? boton;
  final DateTime at;
  _LogEntry(this.raw, this.boton, this.at);
}

class _BotoneraStatusCardState extends ConsumerState<BotoneraStatusCard> {
  List<String> _ips = [];
  bool _conectado = false;
  final Map<KdsButton, DateTime> _lastSeen = {};
  final List<_LogEntry> _log = [];
  StreamSubscription<String>? _rawSub;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _loadIpsAndEnsureServer();
    final service = ref.read(kdsButtonServiceProvider);
    _connSub = service.connectionChanged.listen((c) {
      if (mounted) setState(() => _conectado = c);
    });
    _rawSub = service.mensajeCrudo.listen((raw) {
      if (!mounted) return;
      final boton = parseKdsButton(raw);
      setState(() {
        if (boton != null) _lastSeen[boton] = DateTime.now();
        _log.insert(0, _LogEntry(raw, boton, DateTime.now()));
        if (_log.length > 30) _log.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _rawSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  /// Arranca el servidor (si no estaba corriendo) con el puerto ya guardado
  /// en Configuración, para poder probar la botonera sin depender de que el
  /// KDS esté abierto en otra ventana.
  Future<void> _loadIpsAndEnsureServer() async {
    final ips = await network_info.localIpAddresses();
    final service = ref.read(kdsButtonServiceProvider);
    if (!service.isRunning) {
      final settings = ref.read(settingsProvider).valueOrNull ?? {};
      final port = int.tryParse(settings['botonera_puerto'] ?? '') ?? 8080;
      await service.start(port: port);
    }
    if (mounted) {
      setState(() {
        _ips = ips;
        _conectado = service.conectado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(kdsButtonServiceProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LaTerciaColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LaTerciaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _conectado
                      ? LaTerciaColors.success
                      : LaTerciaColors.tanLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _conectado
                    ? 'ESP32 conectado'
                    : (service.isRunning
                        ? 'Esperando al ESP32…'
                        : 'No se pudo iniciar el servidor (¿puerto ocupado?)'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: LaTerciaColors.cocoa),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Actualizar',
                visualDensity: VisualDensity.compact,
                onPressed: _loadIpsAndEnsureServer,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('IP de esta computadora (grábala en el firmware):',
              style: TextStyle(fontSize: 12, color: LaTerciaColors.tan)),
          const SizedBox(height: 4),
          if (_ips.isEmpty)
            const Text('No se detectó ninguna red activa.',
                style: TextStyle(color: LaTerciaColors.tan))
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _ips
                  .map((ip) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: LaTerciaColors.creamAlt,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: LaTerciaColors.border),
                        ),
                        child: SelectableText(ip,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: LaTerciaColors.darkBrown)),
                      ))
                  .toList(),
            ),
          const Divider(height: 26),
          Row(
            children: [
              const Text('Probar botones',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: LaTerciaColors.cocoa)),
              const Spacer(),
              if (_log.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _log.clear();
                    _lastSeen.clear();
                  }),
                  child: const Text('Limpiar'),
                ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Presiona cada botón físico uno por uno y verifica que se '
            'ilumine el que corresponde.',
            style: TextStyle(fontSize: 12, color: LaTerciaColors.tan),
          ),
          const SizedBox(height: 10),
          _ButtonGrid(lastSeen: _lastSeen),
          const SizedBox(height: 14),
          const Text('Últimos mensajes recibidos:',
              style: TextStyle(fontSize: 12, color: LaTerciaColors.tan)),
          const SizedBox(height: 6),
          if (_log.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nada todavía — presiona un botón de la caja.',
                  style: TextStyle(color: LaTerciaColors.tan)),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: LaTerciaColors.creamAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LaTerciaColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _log.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: LaTerciaColors.border),
                itemBuilder: (ctx, i) {
                  final e = _log[i];
                  final ok = e.boton != null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    child: Row(
                      children: [
                        Icon(
                          ok
                              ? Icons.check_circle
                              : Icons.error_outline,
                          size: 15,
                          color: ok
                              ? LaTerciaColors.success
                              : LaTerciaColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ok ? kdsButtonLabel(e.boton!) : '"${e.raw}"',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    ok ? FontWeight.w700 : FontWeight.w500,
                                color: ok
                                    ? LaTerciaColors.darkBrown
                                    : LaTerciaColors.danger),
                          ),
                        ),
                        Text(formatTime(e.at),
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: LaTerciaColors.tan)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Cuadrícula 3×2 con los 6 botones esperados, en el mismo orden del
/// firmware. Cada celda se ilumina un momento al recibir su señal y muestra
/// hace cuánto fue la última vez.
class _ButtonGrid extends StatefulWidget {
  final Map<KdsButton, DateTime> lastSeen;
  const _ButtonGrid({required this.lastSeen});

  @override
  State<_ButtonGrid> createState() => _ButtonGridState();
}

class _ButtonGridState extends State<_ButtonGrid> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Refresca "hace Xs" y apaga el destello sin depender de nuevos eventos.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        for (final b in kdsButtonOrder) _buildCell(b),
      ],
    );
  }

  Widget _buildCell(KdsButton b) {
    final last = widget.lastSeen[b];
    final flashing =
        last != null && DateTime.now().difference(last) < const Duration(seconds: 2);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: flashing ? LaTerciaColors.success : LaTerciaColors.creamAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: flashing ? LaTerciaColors.success : LaTerciaColors.border,
          width: flashing ? 2 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            kdsButtonLabel(b),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: flashing ? Colors.white : LaTerciaColors.cocoa,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            last == null ? 'sin señal' : 'hace ${_ago(last)}',
            style: TextStyle(
              fontSize: 10.5,
              color: flashing
                  ? Colors.white.withValues(alpha: 0.9)
                  : LaTerciaColors.tan,
            ),
          ),
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 1) return 'un instante';
    if (s < 60) return '${s}s';
    final m = s ~/ 60;
    return '${m}min';
  }
}
