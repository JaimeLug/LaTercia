import 'package:drift/drift.dart';
import '../utils/pin_hasher.dart';
import 'database.dart';

class SeederService {
  final AppDatabase db;
  SeederService(this.db);

  Future<void> seedIfNeeded() async {
    final seeded = await db.settingsDao.getValue('seeded');
    if (seeded == 'true') return;

    await db.transaction(() async {
      await _seedSettings();
      await _seedCategories();
      await _seedProducts();
      await _seedTables();
      await _seedEmployees();
      await _seedModifiers();
      await _seedDiscounts();
    });
  }

  Future<void> _seedSettings() async {
    final defaults = {
      'business_name': 'La Tercia',
      'slogan': 'Frappés & Snacks',
      'logo_path': '',
      'primary_color': '#C1560F',
      'secondary_color': '#F1AA3F',
      'currency_symbol': r'$',
      'tax_rate': '0',
      // Modo de IVA por defecto (docs/precios-e-iva.md). 'true' = incluido.
      'tax_included': 'true',
      'receipt_footer': '¡Gracias por su visita!',
      'default_order_type': 'mesa',
      'low_stock_alert': '5',
      'kds_sound': 'true',
      'kds_warn_yellow': '5',
      'kds_warn_red': '10',
      'show_tax_receipt': 'false',
      'show_customer_field': 'true',
      'enable_tables': 'true',
      'receipt_show_discount': 'true',
      'receipt_show_employee': 'true',
      'currency_decimals': '2',
      'caja_requiere_turno': 'true',
      'auto_lock_min': '5',
      'lock_tras_venta': 'false',
      // FASE 3: impresión térmica y gaveta (todo default OFF; sin hardware).
      'impresion_activa': 'false',
      'gaveta_activa': 'false',
      'gaveta_auto_efectivo': 'true',
      // 'termica' (ESC/POS por red/usb, default) | 'grafica' (PDF a cualquier
      // impresora de Windows vía el paquete printing).
      'printer_mode': 'termica',
      'printer_transport':
          'red', // 'red' (socket 9100) | 'usb' (spooler Windows)
      'printer_address':
          '', // IP[:puerto] para red, nombre de impresora para usb
      'printer_width': '80', // '58' (32 cols) | '80' (48 cols)
      // FASE 4: ventas avanzadas (opcionales, default OFF).
      'propinas_activas': 'false',
      'split_activo': 'false',
      // FASE 5: backups automáticos (default ON, diario, retención 14 días).
      'backup_auto': 'true',
      'backup_retention_days': '14',
      // FASE 3.5: botonera física ESP32 (default OFF, sin hardware para probar
      // hasta que el usuario la active).
      'botonera_activa': 'false',
      'botonera_puerto': '8080',
      // FASE 6: modo kiosko (pantalla completa + bloquear cierre). Default OFF
      // para no atrapar al usuario en desarrollo; se activa en la estación.
      'modo_kiosko': 'false',
      // FASE 7: insumos y recetas (default OFF hasta que el usuario lo active
      // en Admin → Insumos).
      'insumos_activo': 'false',
      // Facturación: datos del emisor (vacíos hasta que se capturen en Config).
      // docs/facturacion.md.
      'rfc_emisor': '',
      'razon_social_emisor': '',
      'regimen_fiscal_emisor': '',
      'cp_lugar_expedicion': '',
      'seeded': 'true',
    };
    for (final entry in defaults.entries) {
      await db.settingsDao.setValue(entry.key, entry.value);
    }
  }

  Future<void> _seedCategories() async {
    final cats = [
      CategoriesCompanion.insert(
          name: 'Bebidas Calientes',
          color: '#E0912A',
          icon: '☕',
          sortOrder: const Value(1)),
      CategoriesCompanion.insert(
          name: 'Bebidas Frías',
          color: '#5F89A6',
          icon: '🧊',
          sortOrder: const Value(2)),
      CategoriesCompanion.insert(
          name: 'Alimentos',
          color: '#C1560F',
          icon: '🥐',
          sortOrder: const Value(3)),
      CategoriesCompanion.insert(
          name: 'Postres',
          color: '#D06771',
          icon: '🍰',
          sortOrder: const Value(4)),
      CategoriesCompanion.insert(
          name: 'Extras',
          color: '#7FA06A',
          icon: '✨',
          sortOrder: const Value(5)),
    ];
    for (final c in cats) {
      await db.categoriesDao.insertCategory(c);
    }
  }

  Future<void> _seedProducts() async {
    // IDs de categoría (se insertaron en orden 1-5).
    final cats = await db.categoriesDao.getAllCategories();
    final catMap = {for (final c in cats) c.name: c.id};

    final products = [
      // Bebidas Calientes
      _p('Café Americano', 35, catMap['Bebidas Calientes']!),
      _p('Café Latte', 50, catMap['Bebidas Calientes']!),
      _p('Cappuccino', 48, catMap['Bebidas Calientes']!),
      _p('Chocolate Caliente', 45, catMap['Bebidas Calientes']!),
      _p('Té de la Tarde', 30, catMap['Bebidas Calientes']!),
      // Bebidas Frías
      _p('Frappé de Café', 60, catMap['Bebidas Frías']!),
      _p('Smoothie de Fresa', 58, catMap['Bebidas Frías']!),
      _p('Limonada Natural', 35, catMap['Bebidas Frías']!),
      _p('Agua Fresca', 25, catMap['Bebidas Frías']!),
      // Alimentos
      _p('Croissant', 40, catMap['Alimentos']!),
      _p('Sándwich Club', 75, catMap['Alimentos']!),
      _p('Avena con Frutas', 55, catMap['Alimentos']!),
      // Postres
      _p('Pastel de Chocolate', 65, catMap['Postres']!),
      _p('Cheesecake', 70, catMap['Postres']!),
      // Extras
      _p('Galleta de Avena', 20, catMap['Extras']!),
    ];
    for (final p in products) {
      await db.productsDao.insertProduct(p);
    }
  }

  ProductsCompanion _p(String name, double price, int categoryId) {
    return ProductsCompanion.insert(
      name: name,
      price: price,
      categoryId: categoryId,
    );
  }

  Future<void> _seedTables() async {
    final tables = [
      TablesLayoutCompanion.insert(name: 'Mesa 1', capacity: const Value(4)),
      TablesLayoutCompanion.insert(name: 'Mesa 2', capacity: const Value(4)),
      TablesLayoutCompanion.insert(name: 'Mesa 3', capacity: const Value(6)),
      TablesLayoutCompanion.insert(name: 'Mesa 4', capacity: const Value(2)),
      TablesLayoutCompanion.insert(name: 'Mesa 5', capacity: const Value(4)),
      TablesLayoutCompanion.insert(name: 'Barra', capacity: const Value(8)),
    ];
    for (final t in tables) {
      await db.tablesDao.insertTable(t);
    }
  }

  Future<void> _seedEmployees() async {
    await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
          name: 'Administrador', pin: hashPin('0000'), role: 'admin'),
    );
    await db.employeesDao.insertEmployee(
      EmployeesCompanion.insert(
          name: 'Cajero', pin: hashPin('1234'), role: 'cashier'),
    );
  }

  Future<void> _seedModifiers() async {
    final mods = [
      ModifiersCompanion.insert(name: 'Sin azúcar', priceDelta: const Value(0)),
      ModifiersCompanion.insert(
          name: 'Leche de almendra', priceDelta: const Value(12)),
      ModifiersCompanion.insert(
          name: 'Extra shot', priceDelta: const Value(10)),
    ];
    for (final m in mods) {
      await db.modifiersDao.insertModifier(m);
    }
  }

  Future<void> _seedDiscounts() async {
    await db.discountsDao.insertDiscount(
      DiscountsCompanion.insert(
        name: 'Descuento empleado',
        type: 'percentage',
        value: 15,
        active: const Value(true),
      ),
    );
  }

  /// Aplica los defaults de marca del rediseño a instalaciones viejas, solo
  /// donde el valor siga en el default anterior (respeta lo que el usuario
  /// haya personalizado).
  Future<void> syncBrandDefaults() async {
    Future<void> bump(String key, String oldDefault, String newValue) async {
      final current = await db.settingsDao.getValue(key);
      if (current == null || current == oldDefault) {
        await db.settingsDao.setValue(key, newValue);
      }
    }

    await bump('business_name', 'LaTercia', 'La Tercia');
    await bump('slogan', '', 'Frappés & Snacks');
    await bump('primary_color', '#6F4E37', '#C1560F');
    await bump('secondary_color', '#D4A574', '#F1AA3F');

    // Refresca los colores de categoría que sigan en su default viejo.
    const catColors = {
      'Bebidas Calientes': ('#8B4513', '#E0912A'),
      'Bebidas Frías': ('#4A90D9', '#5F89A6'),
      'Alimentos': ('#E67E22', '#C1560F'),
      'Postres': ('#E91E8C', '#D06771'),
      'Extras': ('#27AE60', '#7FA06A'),
    };
    final cats = await db.categoriesDao.getAllCategories();
    for (final c in cats) {
      final map = catColors[c.name];
      if (map != null && c.color.toUpperCase() == map.$1) {
        await db.categoriesDao.updateCategory(
          c.copyWith(color: map.$2).toCompanion(true),
        );
      }
    }
  }
}
