import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class ModifierDialog extends ConsumerStatefulWidget {
  final Product product;

  /// Modifiers already filtered to the ones that apply to this product
  /// (see ModifiersDao.getModifiersForCategoryName).
  final List<Modifier> modifiers;

  const ModifierDialog({
    super.key,
    required this.product,
    required this.modifiers,
  });

  @override
  ConsumerState<ModifierDialog> createState() => _ModifierDialogState();
}

class _ModifierDialogState extends ConsumerState<ModifierDialog> {
  final Set<int> _selected = {};
  late final List<Modifier> _modifiers = widget.modifiers;

  double get _extraTotal => _modifiers
      .where((m) => _selected.contains(m.id))
      .fold(0.0, (sum, m) => sum + m.priceDelta);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
    final symbol = settings['currency_symbol'] ?? r'$';

    return Dialog(
      backgroundColor: LaTerciaColors.creamAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MODIFICADORES',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: LaTerciaColors.burntOrange,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 16),
              if (_modifiers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No hay modificadores disponibles.',
                      style: TextStyle(color: LaTerciaColors.tan)),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _modifiers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final mod = _modifiers[i];
                      final active = _selected.contains(mod.id);
                      return _ModifierTile(
                        name: mod.name,
                        priceLabel: mod.priceDelta == 0
                            ? 'Sin costo'
                            : (mod.priceDelta > 0
                                ? '+${formatCurrency(mod.priceDelta, symbol)}'
                                : formatCurrency(mod.priceDelta, symbol)),
                        priceColor: mod.priceDelta == 0
                            ? LaTerciaColors.tan
                            : (mod.priceDelta > 0
                                ? LaTerciaColors.success
                                : LaTerciaColors.danger),
                        active: active,
                        onTap: () => setState(() {
                          if (active) {
                            _selected.remove(mod.id);
                          } else {
                            _selected.add(mod.id);
                          }
                        }),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final chosen = _modifiers
                          .where((m) => _selected.contains(m.id))
                          .toList();
                      Navigator.pop(context, chosen);
                    },
                    child: Text(
                      _extraTotal > 0
                          ? 'Agregar (+${formatCurrency(_extraTotal, symbol)})'
                          : 'Agregar',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModifierTile extends StatelessWidget {
  final String name;
  final String priceLabel;
  final Color priceColor;
  final bool active;
  final VoidCallback onTap;

  const _ModifierTile({
    required this.name,
    required this.priceLabel,
    required this.priceColor,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: active ? LaTerciaColors.burntOrange : Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: active
                        ? LaTerciaColors.burntOrange
                        : LaTerciaColors.borderStrong,
                    width: 1.6,
                  ),
                ),
                child: active
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: LaTerciaColors.darkBrown),
                ),
              ),
              Text(
                priceLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: priceColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
