import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sq;

/// Migración v10 — facturación (CFDI 4.0). Ver docs/facturacion.md.
///
/// Se prueban las dos rutas: base nueva (onCreate) y actualización desde v9
/// (onUpgrade), esta última confirmando que NO se pierden datos existentes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('esquema nuevo (onCreate)', () {
    late AppDatabase db;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });
    tearDown(() => db.close());

    test('Products acepta las claves fiscales', () async {
      final catId = await db.categoriesDao.insertCategory(
        CategoriesCompanion.insert(name: 'Café', color: '#000', icon: 'c'),
      );
      final id = await db.productsDao.insertProduct(ProductsCompanion.insert(
        name: 'Café Americano',
        price: 35,
        categoryId: catId,
        claveProdServ: const Value('50201706'),
        claveUnidad: const Value('E48'),
        objetoImp: const Value('02'),
      ));
      final prod = await (db.select(db.products)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(prod.claveProdServ, '50201706');
      expect(prod.claveUnidad, 'E48');
      expect(prod.objetoImp, '02');
    });

    test('Customers acepta los datos fiscales', () async {
      final id = await db.customersDao.insertCustomer(CustomersCompanion.insert(
        name: 'ACME SA',
        rfc: const Value('AAA010101AAA'),
        razonSocial: const Value('ACME SA DE CV'),
        cpFiscal: const Value('97000'),
        regimenFiscal: const Value('601'),
        usoCfdiPreferido: const Value('G03'),
      ));
      final c = await (db.select(db.customers)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(c.rfc, 'AAA010101AAA');
      expect(c.regimenFiscal, '601');
      expect(c.usoCfdiPreferido, 'G03');
    });

    test('FiscalDocs + FiscalDocItems se insertan y leen', () async {
      final docId =
          await db.into(db.fiscalDocs).insert(FiscalDocsCompanion.insert(
                tipo: 'individual',
                receptorRfc: const Value('AAA010101AAA'),
                receptorUsoCfdi: const Value('G03'),
              ));
      await db.into(db.fiscalDocItems).insert(FiscalDocItemsCompanion.insert(
            fiscalDocId: docId,
            descripcion: 'Café Americano',
            cantidad: 2,
            valorUnitario: 30.17, // 35 con IVA incluido → base ≈ 30.17
            importe: 60.34,
            base: 60.34,
            tasaIva: const Value(0.16),
            importeIva: const Value(9.66),
          ));

      final doc = await (db.select(db.fiscalDocs)
            ..where((t) => t.id.equals(docId)))
          .getSingle();
      expect(doc.tipo, 'individual');
      expect(doc.estado, 'pendiente'); // default

      final items = await (db.select(db.fiscalDocItems)
            ..where((t) => t.fiscalDocId.equals(docId)))
          .get();
      expect(items, hasLength(1));
      expect(items.first.importeIva, closeTo(9.66, 0.001));
    });

    test('la FK de FiscalDocItems exige un FiscalDoc existente', () async {
      await expectLater(
        db.into(db.fiscalDocItems).insert(FiscalDocItemsCompanion.insert(
              fiscalDocId: 99999, // no existe
              descripcion: 'x',
              cantidad: 1,
              valorUnitario: 1,
              importe: 1,
              base: 1,
            )),
        throwsA(anything),
      );
    });
  });

  group('actualización v9 → v10 (onUpgrade)', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('latercia_v9');
      dbFile = File(p.join(tempDir.path, 'latercia.sqlite'));
      _buildV9Fixture(dbFile.path);
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('agrega columnas y tablas sin perder los datos existentes', () async {
      final db = AppDatabase.forTesting(NativeDatabase(dbFile));
      try {
        // El producto y el cliente sembrados en v9 siguen ahí.
        final prod = await db.productsDao.getAllProducts();
        expect(prod, hasLength(1));
        expect(prod.first.name, 'Producto Viejo');
        // Y ahora tienen las columnas fiscales (nulas por default).
        expect(prod.first.claveProdServ, isNull);

        final cli = await db.customersDao.getAllCustomers();
        expect(cli, hasLength(1));
        expect(cli.first.name, 'Cliente Viejo');
        expect(cli.first.rfc, isNull);

        // Las tablas nuevas quedaron utilizables.
        final docId = await db
            .into(db.fiscalDocs)
            .insert(FiscalDocsCompanion.insert(tipo: 'global'));
        expect(docId, greaterThan(0));
      } finally {
        await db.close();
      }
    });
  });
}

/// Crea a mano una base con el esquema de v9 (sin las columnas/tablas de
/// facturación) y `user_version = 9`, con una fila en products y otra en
/// customers, para probar que la migración a v10 corre y no las borra.
void _buildV9Fixture(String path) {
  final db = sq.sqlite3.open(path);
  db.execute('PRAGMA user_version = 9');
  // Solo las tablas que toca la migración v10 (+ la mínima orders para la FK
  // de fiscal_docs). El resto no es necesario para from<10.
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
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )''');
  db.execute('''
    CREATE TABLE customers (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      email TEXT,
      visits INTEGER NOT NULL DEFAULT 0,
      total_spent REAL NOT NULL DEFAULT 0,
      notes TEXT,
      created_at INTEGER NOT NULL
    )''');
  db.execute(
      'CREATE TABLE orders (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT)');
  // shifts existe desde antes de v9; la migración v11 le agrega deleted_at, así
  // que el fixture necesita la tabla (mínima) para poder correr el ALTER.
  db.execute(
      'CREATE TABLE shifts (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT)');
  // discounts idem — la migración v13 (promociones programadas) le agrega
  // columnas.
  db.execute(
      'CREATE TABLE discounts (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT)');

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  db.execute(
      "INSERT INTO products (name, price, category_id, created_at, updated_at) "
      "VALUES ('Producto Viejo', 35, 1, $now, $now)");
  db.execute(
      "INSERT INTO customers (name, created_at) VALUES ('Cliente Viejo', $now)");
  db.dispose();
}
