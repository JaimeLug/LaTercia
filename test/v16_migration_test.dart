import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sq;

/// Migración v16 — alcance de Descuentos por producto (antes `categoryScope`)
/// y puntos por producto en Fidelización. Ver docs/promociones.md,
/// docs/fidelizacion.md.
///
/// Caso real que reprodujo este test: una base que YA había corrido las
/// migraciones v13/v15 con el diseño viejo (desplegadas antes del rediseño
/// de 2026-07-22) se queda con `discounts.category_scope` y sin
/// `products.loyalty_points_value`. v16 debe agregar las columnas nuevas SIN
/// tronar ni perder los datos existentes — antes de este test, el
/// `schemaVersion` se había quedado en 15 tras el rediseño, así que una base
/// ya en v15 nunca volvía a migrar y la app reventaba leyendo productos.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('actualización v15 → v16 (onUpgrade)', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('latercia_v15');
      dbFile = File(p.join(tempDir.path, 'latercia.sqlite'));
      _buildV15Fixture(dbFile.path);
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('agrega productScope y loyaltyPointsValue sin perder datos', () async {
      final db = AppDatabase.forTesting(NativeDatabase(dbFile));
      try {
        // El producto y el descuento sembrados en v15 siguen ahí.
        final products = await db.productsDao.getAllProducts();
        expect(products, hasLength(1));
        expect(products.first.name, 'Café Viejo');
        // Y ahora tiene la columna nueva (default 0, no NULL).
        expect(products.first.loyaltyPointsValue, 0);

        final discounts = await db.discountsDao.getAllDiscounts();
        expect(discounts, hasLength(1));
        expect(discounts.first.name, 'Promo Vieja');
        // El alcance viejo (categoría) no se migra al nuevo campo — queda
        // null (= "aplica a todos"), documentado en el comentario de v16.
        expect(discounts.first.productScope, isNull);
      } finally {
        await db.close();
      }
    });
  });

  group('v16 es idempotente (columna ya presente)', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('latercia_v15_race');
      dbFile = File(p.join(tempDir.path, 'latercia.sqlite'));
      _buildV15FixtureWithColumnsAlreadyAdded(dbFile.path);
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test(
        'no truena con "duplicate column" si product_scope/loyalty_points_value '
        'ya existen (dos instancias abriendo la base a la vez — sitio '
        '2026-07-22)', () async {
      final db = AppDatabase.forTesting(NativeDatabase(dbFile));
      try {
        final products = await db.productsDao.getAllProducts();
        expect(products, hasLength(1));
        expect(products.first.loyaltyPointsValue, 7); // dato ya existente
      } finally {
        await db.close();
      }
    });
  });
}

/// Crea a mano una base con el esquema de v15 (con `discounts.category_scope`
/// viejo, SIN `products.loyalty_points_value`) y `user_version = 15`, con una
/// fila en products y otra en discounts, para probar que la migración a v16
/// corre y no las borra.
void _buildV15Fixture(String path) {
  final db = sq.sqlite3.open(path);
  db.execute('PRAGMA user_version = 15');
  db.execute('''
    CREATE TABLE products (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      cost REAL NOT NULL DEFAULT 0,
      category_id INTEGER NOT NULL,
      sku TEXT,
      image_path TEXT,
      available INTEGER NOT NULL DEFAULT 1,
      track_inventory INTEGER NOT NULL DEFAULT 0,
      stock_quantity INTEGER NOT NULL DEFAULT 0,
      min_stock INTEGER NOT NULL DEFAULT 5,
      tax_rate REAL,
      tax_included INTEGER,
      uses_recipe INTEGER NOT NULL DEFAULT 0,
      clave_prod_serv TEXT,
      clave_unidad TEXT,
      objeto_imp TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )''');
  db.execute('''
    CREATE TABLE discounts (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      value REAL NOT NULL,
      min_order_amount REAL NOT NULL DEFAULT 0,
      active INTEGER NOT NULL DEFAULT 1,
      valid_from INTEGER,
      valid_until INTEGER,
      days_of_week TEXT,
      start_time TEXT,
      end_time TEXT,
      category_scope TEXT,
      created_at INTEGER NOT NULL
    )''');

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  db.execute(
      "INSERT INTO products (name, price, category_id, created_at, updated_at) "
      "VALUES ('Café Viejo', 35, 1, $now, $now)");
  db.execute(
      "INSERT INTO discounts (name, type, value, category_scope, created_at) "
      "VALUES ('Promo Vieja', 'percentage', 10, 'Bebidas', $now)");
  db.dispose();
}

/// Igual que [_buildV15Fixture], pero simulando el choque de dos instancias:
/// `product_scope`/`loyalty_points_value` YA fueron agregadas (por la otra
/// instancia que ganó la carrera) aunque `user_version` se haya quedado en
/// 15 (la que perdió la carrera nunca llegó a actualizarlo). v16 debe leer
/// esto con `PRAGMA table_info` y NO intentar agregarlas de nuevo.
void _buildV15FixtureWithColumnsAlreadyAdded(String path) {
  final db = sq.sqlite3.open(path);
  db.execute('PRAGMA user_version = 15');
  db.execute('''
    CREATE TABLE products (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      cost REAL NOT NULL DEFAULT 0,
      category_id INTEGER NOT NULL,
      sku TEXT,
      image_path TEXT,
      available INTEGER NOT NULL DEFAULT 1,
      track_inventory INTEGER NOT NULL DEFAULT 0,
      stock_quantity INTEGER NOT NULL DEFAULT 0,
      min_stock INTEGER NOT NULL DEFAULT 5,
      tax_rate REAL,
      tax_included INTEGER,
      uses_recipe INTEGER NOT NULL DEFAULT 0,
      clave_prod_serv TEXT,
      clave_unidad TEXT,
      objeto_imp TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      loyalty_points_value INTEGER NOT NULL DEFAULT 0
    )''');
  db.execute('''
    CREATE TABLE discounts (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      value REAL NOT NULL,
      min_order_amount REAL NOT NULL DEFAULT 0,
      active INTEGER NOT NULL DEFAULT 1,
      valid_from INTEGER,
      valid_until INTEGER,
      days_of_week TEXT,
      start_time TEXT,
      end_time TEXT,
      category_scope TEXT,
      product_scope TEXT,
      created_at INTEGER NOT NULL
    )''');

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  db.execute("INSERT INTO products (name, price, category_id, created_at, "
      "updated_at, loyalty_points_value) "
      "VALUES ('Café Viejo', 35, 1, $now, $now, 7)");
  db.execute("INSERT INTO discounts (name, type, value, category_scope, "
      "product_scope, created_at) "
      "VALUES ('Promo Vieja', 'percentage', 10, 'Bebidas', NULL, $now)");
  db.dispose();
}
