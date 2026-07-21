import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/session_provider.dart';
import '../auth/session_guard.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/modifiers_screen.dart';
import 'screens/tables_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/discounts_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shifts_screen.dart';
import 'screens/botonera_screen.dart';
import 'screens/kiosk_screen.dart';
import 'screens/delivery_zones_screen.dart';
import 'screens/backups_screen.dart';
import 'screens/facturacion_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _selectedIndex = 0;
  bool _extended = true;

  static const _destinations = [
    NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('Dashboard')),
    NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: Text('Productos')),
    NavigationRailDestination(
        icon: Icon(Icons.category_outlined),
        selectedIcon: Icon(Icons.category),
        label: Text('Categorías')),
    NavigationRailDestination(
        icon: Icon(Icons.tune_outlined),
        selectedIcon: Icon(Icons.tune),
        label: Text('Modificadores')),
    NavigationRailDestination(
        icon: Icon(Icons.table_restaurant_outlined),
        selectedIcon: Icon(Icons.table_restaurant),
        label: Text('Mesas')),
    NavigationRailDestination(
        icon: Icon(Icons.badge_outlined),
        selectedIcon: Icon(Icons.badge),
        label: Text('Empleados')),
    NavigationRailDestination(
        icon: Icon(Icons.people_outlined),
        selectedIcon: Icon(Icons.people),
        label: Text('Clientes')),
    NavigationRailDestination(
        icon: Icon(Icons.local_offer_outlined),
        selectedIcon: Icon(Icons.local_offer),
        label: Text('Descuentos')),
    NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: Text('Órdenes')),
    NavigationRailDestination(
        icon: Icon(Icons.money_off_outlined),
        selectedIcon: Icon(Icons.money_off),
        label: Text('Gastos')),
    NavigationRailDestination(
        icon: Icon(Icons.warehouse_outlined),
        selectedIcon: Icon(Icons.warehouse),
        label: Text('Inventario')),
    NavigationRailDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: Text('Reportes')),
    NavigationRailDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: Text('Turnos')),
    NavigationRailDestination(
        icon: Icon(Icons.delivery_dining_outlined),
        selectedIcon: Icon(Icons.delivery_dining),
        label: Text('Envío')),
    NavigationRailDestination(
        icon: Icon(Icons.gamepad_outlined),
        selectedIcon: Icon(Icons.gamepad),
        label: Text('Botonera')),
    NavigationRailDestination(
        icon: Icon(Icons.dvr_outlined),
        selectedIcon: Icon(Icons.dvr),
        label: Text('Quiosco')),
    NavigationRailDestination(
        icon: Icon(Icons.request_quote_outlined),
        selectedIcon: Icon(Icons.request_quote),
        label: Text('Facturación')),
    NavigationRailDestination(
        icon: Icon(Icons.backup_outlined),
        selectedIcon: Icon(Icons.backup),
        label: Text('Backups')),
    NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Configuración')),
  ];

  final _screens = const [
    DashboardScreen(),
    ProductsScreen(),
    CategoriesScreen(),
    ModifiersScreen(),
    TablesScreen(),
    EmployeesScreen(),
    CustomersScreen(),
    DiscountsScreen(),
    OrdersScreen(),
    ExpensesScreen(),
    InventoryScreen(),
    ReportsScreen(),
    ShiftsScreen(),
    DeliveryZonesScreen(),
    BotoneraScreen(),
    KioskScreen(),
    FacturacionScreen(),
    BackupsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return SessionGuard(
      child: Scaffold(
        body: Row(
          children: [
            // El menú ya tiene 16 destinos y seguirá creciendo — sin scroll
            // propio, NavigationRail desborda en ventanas cortas (overflow
            // reportado). LayoutBuilder+ConstrainedBox(minHeight)+
            // IntrinsicHeight es el patrón estándar para dejar scrollable un
            // Column con un `Expanded` adentro (el trailing del logout,
            // anclado abajo): si todo cabe, se ve igual que antes; si no,
            // hace scroll en vez de desbordarse.
            LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      extended: _extended,
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (i) =>
                          setState(() => _selectedIndex = i),
                      destinations: _destinations,
                      leading: Column(
                        children: [
                          const SizedBox(height: 8),
                          IconButton(
                            icon: Icon(_extended
                                ? Icons.chevron_left
                                : Icons.chevron_right),
                            onPressed: () =>
                                setState(() => _extended = !_extended),
                          ),
                        ],
                      ),
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: IconButton(
                              icon: const Icon(Icons.logout),
                              tooltip: 'Cerrar sesión',
                              onPressed: () {
                                ref.read(sessionProvider.notifier).state = null;
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      ),
    );
  }
}
