import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/services/audit_service.dart';
import '../../core/theme/app_theme.dart';

class PinGate extends ConsumerStatefulWidget {
  final Widget child;
  final bool adminOnly;

  const PinGate({super.key, required this.child, this.adminOnly = true});

  @override
  ConsumerState<PinGate> createState() => _PinGateState();
}

class _PinGateState extends ConsumerState<PinGate>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _error;
  int _consecutiveFailedAttempts = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += key;
      _error = null;
    });
    if (_pin.length == 4) _validatePin();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _validatePin() async {
    final db = ref.read(databaseProvider);
    final employee = await db.employeesDao.findByPin(_pin);

    if (employee == null) {
      _consecutiveFailedAttempts++;
      if (_consecutiveFailedAttempts >= 3) {
        // Nunca loguear el PIN, solo que hubo N intentos fallidos (employeeId
        // null: un PIN fallido no identifica a nadie). docs/seguridad.md.
        await ref.read(auditServiceProvider).log(
          employeeId: null,
          action: 'login_pin_fallido',
          detail: {'consecutiveAttempts': _consecutiveFailedAttempts},
        );
        _consecutiveFailedAttempts = 0;
      }
      _shake('PIN incorrecto');
      return;
    }

    if (widget.adminOnly &&
        employee.role != 'admin' &&
        employee.role != 'gerente') {
      _shake('Acceso denegado');
      return;
    }

    _consecutiveFailedAttempts = 0;
    ref.read(sessionProvider.notifier).state = employee;
  }

  void _shake(String message) {
    setState(() {
      _pin = '';
      _error = message;
    });
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    if (session != null) {
      if (!widget.adminOnly ||
          session.role == 'admin' ||
          session.role == 'gerente') {
        return widget.child;
      }
    }

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo-color.png',
                width: 96,
                height: 96,
                cacheWidth: 240,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                widget.adminOnly ? 'Acceso Admin' : 'Identificación',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                widget.adminOnly
                    ? 'Ingresa el PIN de administrador'
                    : 'Ingresa tu PIN para continuar',
                style: const TextStyle(color: LaTerciaColors.tan),
              ),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeController.isAnimating
                          ? 12 * (0.5 - (_shakeAnimation.value / 12))
                          : 0,
                      0,
                    ),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.all(8),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? primary : Colors.transparent,
                        border: Border.all(
                          color: filled ? primary : LaTerciaColors.borderStrong,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(
                height: 24,
                child: _error != null
                    ? Text(_error!,
                        style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w500))
                    : null,
              ),
              const SizedBox(height: 12),
              _buildKeypad(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '⌫'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 84, height: 66);
              final isBack = key == '⌫';
              return Padding(
                padding: const EdgeInsets.all(6),
                child: SizedBox(
                  width: 84,
                  height: 66,
                  child: Material(
                    color: isBack ? const Color(0xFFF7D9D5) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => isBack ? _onBackspace() : _onKey(key),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isBack
                                ? const Color(0xFFE9B8B0)
                                : LaTerciaColors.border,
                          ),
                        ),
                        child: isBack
                            ? const Icon(Icons.backspace_outlined,
                                color: LaTerciaColors.danger, size: 22)
                            : Text(
                                key,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: LaTerciaColors.cocoa,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
