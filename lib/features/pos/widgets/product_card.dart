import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final Category? category;
  final String currencySymbol;
  final bool hasModifiers;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ProductCard({
    super.key,
    required this.product,
    required this.category,
    required this.currencySymbol,
    required this.hasModifiers,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hover = false;

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return LaTerciaColors.catCaliente;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(widget.category?.color ?? '#E0912A');
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _buildHeader(color)),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency(
                                    product.price, widget.currencySymbol),
                                style: const TextStyle(
                                  fontFamily: 'DM Serif Display',
                                  fontSize: 19,
                                  color: LaTerciaColors.darkBrown,
                                ),
                              ),
                              if (widget.hasModifiers)
                                const Text(
                                  'Con modificadores',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: LaTerciaColors.tan,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: LaTerciaColors.burntOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                        ),
                      ],
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

  Widget _buildHeader(Color color) {
    final product = widget.product;
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      final file = File(product.imagePath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.18)!],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -6,
            top: -6,
            child: Text(
              widget.category?.icon ?? '🍽',
              style: const TextStyle(
                fontSize: 56,
                color: Colors.white24,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'DM Serif Display',
                  fontSize: 17,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
