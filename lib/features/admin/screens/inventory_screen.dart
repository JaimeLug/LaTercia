import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_panel.dart';
import 'compras_screen.dart';
import 'insumos_screen.dart';
import 'proveedores_screen.dart';
import 'stock_simple_screen.dart';

typedef _InventoryCategory = ({
  String key,
  IconData icon,
  String title,
  String subtitle,
});

const _categories = <_InventoryCategory>[
  (
    key: 'stock',
    icon: Icons.inventory_2_outlined,
    title: 'Stock por producto',
    subtitle: 'Rastreo simple, sin recetas',
  ),
  (
    key: 'insumos',
    icon: Icons.eco_outlined,
    title: 'Insumos',
    subtitle: 'Materia prima y recetas',
  ),
  (
    key: 'proveedores',
    icon: Icons.local_shipping_outlined,
    title: 'Proveedores',
    subtitle: 'Catálogo de proveedores',
  ),
  (
    key: 'compras',
    icon: Icons.shopping_cart_outlined,
    title: 'Compras',
    subtitle: 'Reposición de insumos',
  ),
];

/// Landing de Inventario: una tarjeta por área (mismo patrón que
/// Configuración — navegación EMBEBIDA en la misma pantalla, sin abrir una
/// ventana/página nueva) que agrupa el rastreo simple por producto (de
/// siempre) junto con el sistema de insumos y recetas (FASE 7, activable) y
/// su ciclo de proveedores/compras.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String? _active;

  final _insumosKey = GlobalKey<InsumosBodyState>();
  final _proveedoresKey = GlobalKey<ProveedoresBodyState>();
  final _comprasKey = GlobalKey<ComprasBodyState>();

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final settings = ref.watch(settingsProvider).valueOrNull ?? {};

    return Scaffold(
      backgroundColor: LaTerciaColors.appBg,
      appBar: active == null
          ? adminAppBar('Inventario')
          : AppBar(
              backgroundColor: LaTerciaColors.cream,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: LaTerciaColors.darkBrown),
                onPressed: () => setState(() => _active = null),
              ),
              title: Text(
                _categories.firstWhere((c) => c.key == active).title,
                style: const TextStyle(
                    fontFamily: 'DM Serif Display',
                    fontSize: 22,
                    color: LaTerciaColors.darkBrown),
              ),
            ),
      floatingActionButton: _buildFab(active, settings),
      body: active == null ? _buildGrid() : _buildBody(active),
    );
  }

  Widget _buildGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: CategoryCardGrid(
        children: [
          for (final cat in _categories)
            CategoryCard(
              icon: cat.icon,
              title: cat.title,
              subtitle: cat.subtitle,
              onTap: () => setState(() => _active = cat.key),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(String active) {
    switch (active) {
      case 'stock':
        return const StockSimpleBody();
      case 'insumos':
        return InsumosBody(key: _insumosKey);
      case 'proveedores':
        return ProveedoresBody(key: _proveedoresKey);
      case 'compras':
        return ComprasBody(key: _comprasKey);
    }
    return const SizedBox.shrink();
  }

  Widget? _buildFab(String? active, Map<String, String> settings) {
    VoidCallback? onPressed;
    switch (active) {
      case 'insumos':
        if (settings['insumos_activo'] != 'true') return null;
        onPressed = () => _insumosKey.currentState?.openAddDialog();
      case 'proveedores':
        onPressed = () => _proveedoresKey.currentState?.openAddDialog();
      case 'compras':
        onPressed = () => _comprasKey.currentState?.openAddDialog();
      default:
        return null;
    }
    return FloatingActionButton(
      backgroundColor: LaTerciaColors.burntOrange,
      onPressed: onPressed,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
