import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';

/// Landing screen shown after login. Lets the employee pick a module.
class WelcomeScreen extends ConsumerStatefulWidget {
  final void Function(int tab) onOpen;
  const WelcomeScreen({super.key, required this.onOpen});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  (String, String) _greeting() {
    final h = _now.hour;
    if (h < 12) return ('Buenos días', '☀️');
    if (h < 19) return ('Buenas tardes', '🌤️');
    return ('Buenas noches', '🌙');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final name = settings['business_name'] ?? 'La Tercia';
    final slogan = settings['slogan'] ?? '';
    final employee = ref.watch(sessionProvider);
    final activeCount = ref.watch(ordersProvider).where((o) {
      final s = o.order.status;
      return s == 'pendiente' || s == 'en_preparacion';
    }).length;

    final (greet, emoji) = _greeting();
    final dateStr = toBeginningOfSentenceCase(
        DateFormat("EEEE, d 'de' MMMM", 'es_MX').format(_now));
    final timeStr = DateFormat('HH:mm').format(_now);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.1,
            colors: [Color(0xFFF6EDE0), Color(0xFFDFCEB0)],
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: Row(
                children: [
                  Image.asset('assets/images/logo-color.png',
                      width: 44, height: 44, cacheWidth: 108),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontFamily: 'DM Serif Display',
                              fontSize: 22,
                              color: LaTerciaColors.darkBrown,
                              height: 1.0)),
                      if (slogan.isNotEmpty)
                        Text(slogan.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                                color: LaTerciaColors.tan)),
                    ],
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(sessionProvider.notifier).state = null,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Greeting
            Text('$greet $emoji',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: LaTerciaColors.tan)),
            const SizedBox(height: 6),
            Text(
              'Bienvenido, ${employee?.name ?? ''}',
              style: const TextStyle(
                  fontFamily: 'DM Serif Display',
                  fontSize: 44,
                  color: LaTerciaColors.darkBrown),
            ),
            const SizedBox(height: 8),
            Text('$dateStr · $timeStr',
                style:
                    const TextStyle(fontSize: 15, color: LaTerciaColors.tan)),
            const SizedBox(height: 40),
            // Module cards
            Wrap(
              spacing: 22,
              runSpacing: 22,
              alignment: WrapAlignment.center,
              children: [
                _ModuleCard(
                  icon: Icons.point_of_sale,
                  iconBg: const Color(0xFFF6E4C8),
                  iconColor: LaTerciaColors.burntOrange,
                  title: 'Punto de Venta',
                  description: 'Toma órdenes y cobra\nrápido en el mostrador.',
                  action: 'Abrir POS',
                  actionColor: LaTerciaColors.burntOrange,
                  onTap: () => widget.onOpen(0),
                ),
                _ModuleCard(
                  icon: Icons.soup_kitchen,
                  iconBg: const Color(0xFFEADCF6),
                  iconColor: LaTerciaColors.delivery,
                  title: 'Cocina · KDS',
                  description: activeCount > 0
                      ? '$activeCount pedidos activos en\npreparación ahora.'
                      : 'Sin pedidos activos\nen este momento.',
                  action: 'Abrir Cocina',
                  actionColor: LaTerciaColors.delivery,
                  onTap: () => widget.onOpen(1),
                ),
                _ModuleCard(
                  icon: Icons.settings_suggest,
                  iconBg: const Color(0xFFDDEBD3),
                  iconColor: const Color(0xFF5A8A3C),
                  title: 'Administración',
                  description: 'Reportes, menú, empleados\ny configuración.',
                  action: 'Abrir Admin',
                  actionColor: const Color(0xFF5A8A3C),
                  onTap: () => widget.onOpen(2),
                ),
              ],
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String action;
  final Color actionColor;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.action,
    required this.actionColor,
    required this.onTap,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        width: 250,
        height: 270,
        decoration: BoxDecoration(
          color: LaTerciaColors.creamAlt,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: LaTerciaColors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF462D0A)
                  .withValues(alpha: _hover ? 0.14 : 0.05),
              blurRadius: _hover ? 26 : 14,
              offset: Offset(0, _hover ? 12 : 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.iconBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 28),
                  ),
                  const Spacer(),
                  Text(widget.title,
                      style: const TextStyle(
                          fontFamily: 'DM Serif Display',
                          fontSize: 25,
                          color: LaTerciaColors.darkBrown)),
                  const SizedBox(height: 8),
                  Text(widget.description,
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          color: LaTerciaColors.tan)),
                  const Spacer(),
                  Row(
                    children: [
                      Text(widget.action,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: widget.actionColor)),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward,
                          size: 16, color: widget.actionColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
