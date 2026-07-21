import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/orders_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/shift_provider.dart';
import '../../core/services/audit_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/print_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../auth/supervisor_pin_dialog.dart';
import 'shift/shift_screen.dart';

/// Barra de navegación superior de POS / KDS / Admin.
class TopNavBar extends ConsumerWidget {
  final int currentTab; // 0 = POS, 1 = KDS (embedded), 2 = Admin
  final VoidCallback onLogo;
  final VoidCallback onPos;
  final VoidCallback onKds;
  final VoidCallback onAdmin;

  const TopNavBar({
    super.key,
    required this.currentTab,
    required this.onLogo,
    required this.onPos,
    required this.onKds,
    required this.onAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final name = settings['business_name'] ?? 'La Tercia';
    final employee = ref.watch(sessionProvider);

    final activeCount = ref.watch(ordersProvider).where((o) {
      final s = o.order.status;
      return s == 'pendiente' || s == 'en_preparacion';
    }).length;

    return Container(
      height: 64,
      color: LaTerciaColors.darkBrown,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          InkWell(
            onTap: onLogo,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _Brand(name: name),
            ),
          ),
          const SizedBox(width: 24),
          _NavItem(
            icon: Icons.point_of_sale,
            label: 'Punto de Venta',
            active: currentTab == 0,
            onTap: onPos,
          ),
          const SizedBox(width: 6),
          _NavItem(
            icon: Icons.soup_kitchen,
            label: 'Cocina · KDS',
            active: currentTab == 1,
            onTap: onKds,
            badge: activeCount,
          ),
          const SizedBox(width: 6),
          _NavItem(
            icon: Icons.settings_suggest,
            label: 'Administración',
            active: currentTab == 2,
            onTap: onAdmin,
          ),
          const Spacer(),
          if (settings['gaveta_activa'] == 'true') ...[
            _DrawerButton(),
            const SizedBox(width: 4),
          ],
          _ShiftButton(),
          const SizedBox(width: 12),
          if (employee != null) _UserChip(name: employee.name),
          const SizedBox(width: 18),
          const _Clock(),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final String name;
  const _Brand({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo-color.png',
            width: 40,
            height: 40,
            cacheWidth: 96,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'DM Serif Display',
                fontSize: 20,
                color: Colors.white,
                height: 1.05,
              ),
            ),
            const Text(
              'CHICXULUB PUERTO',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: LaTerciaColors.gold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? LaTerciaColors.darkBrown : const Color(0xFFE7DBC9);
    return Material(
      color: active ? LaTerciaColors.gold : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 19, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(
                    color: LaTerciaColors.danger,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Text(
                    '${badge!}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final String name;
  const _UserChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: LaTerciaColors.gold,
          child: Text(
            initial,
            style: const TextStyle(
              color: LaTerciaColors.darkBrown,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  Timer? _timer;
  String _time = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (mounted) setState(() => _time = formatTime(DateTime.now()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _time,
      style: const TextStyle(
        fontFamily: 'DM Serif Display',
        fontSize: 22,
        color: Colors.white,
      ),
    );
  }
}

/// Abre la gaveta sin venta (gated por `abrirGavetaSinVenta`, se audita). Solo
/// aparece si `gaveta_activa`. docs/permisos-y-auditoria.md, docs/impresion.md.
class _DrawerButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Abrir gaveta',
      icon: const Icon(Icons.point_of_sale_outlined, color: Colors.white),
      onPressed: () => _openDrawer(context, ref),
    );
  }

  Future<void> _openDrawer(BuildContext context, WidgetRef ref) async {
    final actor = ref.read(sessionProvider);
    if (actor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu PIN primero.')),
      );
      return;
    }

    // Si el actor ya tiene permiso (admin/gerente), `ensure` no audita, así que
    // registramos nosotros una fila; si es cajero, `ensure` ya auditó (no
    // duplicar). docs/permisos-y-auditoria.md.
    final hadPermission = ref
        .read(permissionServiceProvider)
        .hasPermission(actor, PermissionAction.abrirGavetaSinVenta);

    final allowed = await SupervisorPinDialog.ensure(
      context,
      ref,
      actor: actor,
      action: PermissionAction.abrirGavetaSinVenta,
      entity: 'drawer',
    );
    if (!allowed) return;

    final settings = ref.read(settingsProvider).valueOrNull ?? {};
    await ref.read(printServiceProvider).openDrawer(settings);

    if (hadPermission) {
      await ref.read(auditServiceProvider).log(
        employeeId: actor.id,
        action: PermissionAction.abrirGavetaSinVenta.key,
        entity: 'drawer',
        detail: {'manual': true},
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gaveta abierta.')),
      );
    }
  }
}

/// Abre [ShiftScreen] (turno de caja). El punto del badge indica si hay un
/// turno abierto.
class _ShiftButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftAsync = ref.watch(currentShiftProvider);
    final isOpen = shiftAsync.valueOrNull != null;

    return IconButton(
      tooltip: 'Turno de caja',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShiftScreen()),
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.point_of_sale, color: Colors.white),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isOpen ? LaTerciaColors.success : LaTerciaColors.tanLight,
                border: Border.all(color: LaTerciaColors.darkBrown, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
