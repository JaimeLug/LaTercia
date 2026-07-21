import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/services/backup_service.dart';
import 'package:path/path.dart' as p;

void main() {
  // Las pruebas de restauración parcial abren, a propósito, una segunda
  // AppDatabase sobre el archivo de respaldo (aislado, y se cierra antes de
  // reabrirlo de solo lectura). El aviso de "multiple databases" de drift no
  // aplica aquí y solo ensucia la salida.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tempBase;
  late AppDatabase db;
  late BackupService backup;

  setUp(() async {
    tempBase = await Directory.systemTemp.createTemp('latercia_backup_test');
    // Base de datos respaldada por archivo real (no en memoria), en la ruta
    // que BackupService espera de [dbDir]: <dbDirTemp>/latercia.sqlite —
    // misma convención que la BD real (getApplicationDocumentsDirectory,
    // sin subcarpeta), en un temp aparte del de backups/logs ([baseDir]).
    final dbDirTemp = Directory(p.join(tempBase.path, 'docs'));
    await dbDirTemp.create(recursive: true);
    db = AppDatabase.forTesting(
        NativeDatabase(File(p.join(dbDirTemp.path, 'latercia.sqlite'))));
    // Fuerza la creación del archivo ejecutando una consulta.
    await db.settingsDao.getAllSettings();
    backup = BackupService(
      db,
      baseDir: () async => tempBase,
      dbDir: () async => dbDirTemp,
    );
  });

  tearDown(() async {
    await db.close();
    try {
      await tempBase.delete(recursive: true);
    } catch (_) {}
  });

  test('backupNow crea una copia y sella last_backup_at', () async {
    final file = await backup.backupNow(reason: 'test');
    expect(file, isNotNull);
    expect(await file!.exists(), isTrue);
    expect(p.basename(file.path), startsWith('latercia-'));

    final stamp = await db.settingsDao.getValue('last_backup_at');
    expect(stamp, isNotNull);

    final info = await backup.lastBackupInfo();
    expect(info, isNotNull);
    expect(info!.sizeBytes, greaterThan(0));
  });

  test('autoBackupIfDue no hace nada si backup_auto está OFF', () async {
    await db.settingsDao.setValue('backup_auto', 'false');
    await backup.autoBackupIfDue();
    expect(await backup.lastBackupInfo(), isNull);
  });

  test('autoBackupIfDue respalda una vez y no repite el mismo día', () async {
    await db.settingsDao.setValue('backup_auto', 'true');
    await backup.autoBackupIfDue();
    final first = await backup.lastBackupInfo();
    expect(first, isNotNull);

    // Segunda llamada el mismo día: no debe crear otro (ya se hizo hoy).
    await backup.autoBackupIfDue();
    final dir = await backup.backupsDir();
    final count = await dir.list().where((e) => e.path.endsWith('.db')).length;
    expect(count, 1);
  });

  // FASE de auditoría 2026-07-17 — el backup ahora copia a .tmp y renombra
  // (rename atómico) en vez de copiar directo al nombre final.
  test('backupNow nunca deja el archivo final con sufijo .tmp', () async {
    final file = await backup.backupNow(reason: 'test');
    expect(file, isNotNull);
    expect(file!.path.endsWith('.tmp'), isFalse);
    expect(await File('${file.path}.tmp').exists(), isFalse,
        reason: 'no debe quedar un .tmp huérfano tras un backup exitoso');
  });

  test('un .tmp huérfano de un intento anterior interrumpido se limpia solo',
      () async {
    final dir = await backup.backupsDir();
    final orphan = File(p.join(dir.path, 'latercia-viejo.db.tmp'));
    await orphan.writeAsString('incompleto');

    await backup.backupNow(reason: 'test');

    expect(await orphan.exists(), isFalse,
        reason: 'el .tmp huérfano debe borrarse en el siguiente backup');
  });

  test('la retención borra respaldos más antiguos que N días', () async {
    await db.settingsDao.setValue('backup_retention_days', '7');
    final dir = await backup.backupsDir();
    // Un respaldo "viejo" de hace 30 días.
    final old = File(p.join(dir.path, 'latercia-viejo.db'));
    await old.writeAsString('x');
    await old
        .setLastModified(DateTime.now().subtract(const Duration(days: 30)));

    await backup.backupNow(reason: 'test'); // dispara la poda

    expect(await old.exists(), isFalse, reason: 'el viejo se poda');
  });

  group('listBackups', () {
    test('devuelve todos los .db, más reciente primero', () async {
      await backup.backupNow(reason: 'uno');
      // Timestamp del nombre de archivo tiene resolución de segundos — sin
      // esperar, dos backups seguidos podrían generar el mismo nombre y el
      // segundo pisaría al primero en vez de sumarse.
      await Future<void>.delayed(const Duration(seconds: 1));
      await backup.backupNow(reason: 'dos');

      final list = await backup.listBackups();
      expect(list.length, 2);
      expect(
          list.first.modified.isAfter(list.last.modified) ||
              list.first.modified.isAtSameMomentAs(list.last.modified),
          isTrue);
    });

    test('vacío si no hay respaldos', () async {
      expect(await backup.listBackups(), isEmpty);
    });
  });

  group('exportSql', () {
    test('incluye el CREATE TABLE y un INSERT por fila de las tablas pedidas',
        () async {
      await db.categoriesDao.insertCategory(CategoriesCompanion.insert(
        name: 'Bebidas',
        color: '#FF0000',
        icon: 'coffee',
      ));

      final sql = await backup.exportSql(tables: ['categories']);

      expect(sql, contains('CREATE TABLE "categories"'));
      expect(sql, contains("INSERT INTO categories"));
      expect(sql, contains("'Bebidas'"));
      // No se pidió `products`: no debe aparecer su CREATE TABLE.
      expect(sql, isNot(contains('CREATE TABLE "products"')));
    });

    test('sin tables: exporta el universo completo de exportableTables',
        () async {
      final sql = await backup.exportSql();
      for (final table in BackupService.exportableTables.keys) {
        expect(sql, contains('CREATE TABLE "$table"'),
            reason: '$table debería estar en el export completo');
      }
    });

    test('escapa comillas simples para no romper el SQL', () async {
      await db.categoriesDao.insertCategory(CategoriesCompanion.insert(
        name: "Café d'autor",
        color: '#FF0000',
        icon: 'coffee',
      ));

      final sql = await backup.exportSql(tables: ['categories']);

      expect(sql, contains("Café d''autor"));
    });
  });

  group('exportXlsxBytes', () {
    test('una hoja por tabla pedida, con encabezados y filas', () async {
      await db.categoriesDao.insertCategory(CategoriesCompanion.insert(
        name: 'Bebidas',
        color: '#FF0000',
        icon: 'coffee',
      ));

      final bytes =
          await backup.exportXlsxBytes(tables: ['categories', 'products']);
      final workbook = xlsx.Excel.decodeBytes(bytes);

      expect(workbook.sheets.keys, containsAll(['Categorías', 'Productos']));

      // La BD de prueba ya trae el catálogo default sembrado (Bebidas
      // Calientes, Alimentos...), así que la fila insertada aquí no es
      // necesariamente la primera — se busca por nombre exacto entre todas.
      final sheet = workbook.sheets['Categorías']!;
      final header = sheet.row(0).map((c) => c?.value.toString()).toList();
      expect(header, contains('name'));
      final nameCol = header.indexOf('name');
      final names = sheet.rows
          .skip(1)
          .map((row) => row[nameCol]?.value.toString())
          .toList();
      expect(names, contains('Bebidas'));
    });

    test('no deja la hoja vacía por defecto de Excel.createExcel()', () async {
      final bytes = await backup.exportXlsxBytes(tables: ['categories']);
      final workbook = xlsx.Excel.decodeBytes(bytes);

      expect(workbook.sheets.length, 1);
      expect(workbook.sheets.keys, isNot(contains('Sheet1')));
    });
  });

  group('restauración parcial por grupo', () {
    // createdAt fijo en TODAS las inserciones de clientes: la columna se
    // guarda como entero (unix), así que si no la fijo, la base actual y la
    // de respaldo tendrían timestamps distintos y toda fila saldría
    // "diferente" por ruido, en vez de por el campo que sí cambié a mano.
    final fixed = DateTime(2026, 1, 1);

    /// Construye un `.db` de respaldo aparte (segunda base drift en su propio
    /// archivo) con la lista de clientes dada, y devuelve su ruta. Los ids se
    /// asignan por orden de inserción (autoincrement) — el orden importa para
    /// que casen con los de la base actual.
    Future<String> makeBackupWithCustomers(
        List<({String name, String? phone})> rows) async {
      final path = p.join(tempBase.path, 'respaldo-clientes.db');
      final bdb = AppDatabase.forTesting(NativeDatabase(File(path)));
      for (final r in rows) {
        await bdb.customersDao.insertCustomer(CustomersCompanion.insert(
          name: r.name,
          phone: Value(r.phone),
          createdAt: Value(fixed),
        ));
      }
      await bdb.close(); // suelta el archivo para poder abrirlo de solo lectura
      return path;
    }

    Future<int> addCurrentCustomer(String name, {String? phone}) {
      return db.customersDao.insertCustomer(CustomersCompanion.insert(
        name: name,
        phone: Value(phone),
        createdAt: Value(fixed),
      ));
    }

    test('preview clasifica nueva / igual / diferente por id', () async {
      await addCurrentCustomer('Ana'); // id 1
      await addCurrentCustomer('Beto'); // id 2

      final path = await makeBackupWithCustomers([
        (name: 'Ana', phone: null), // id 1 — idéntico → igual
        (name: 'Beto Modificado', phone: null), // id 2 — cambió → diferente
        (name: 'Carlos', phone: null), // id 3 — current no lo tiene → nueva
      ]);

      final diffs =
          await backup.previewGroupRestore(backupPath: path, group: 'Clientes');
      final byId = {for (final d in diffs) d.id: d.status};

      expect(byId[1], RestoreRowStatus.igual);
      expect(byId[2], RestoreRowStatus.diferente);
      expect(byId[3], RestoreRowStatus.nueva);
    });

    test('merge: agrega las nuevas, mantiene las que ya existen', () async {
      await addCurrentCustomer('Ana'); // id 1
      await addCurrentCustomer('Beto'); // id 2

      final path = await makeBackupWithCustomers([
        (name: 'Ana', phone: null),
        (name: 'Beto Modificado', phone: null),
        (name: 'Carlos', phone: null),
      ]);

      // Sin decisiones → las "diferente" se mantienen como están.
      final result = await backup.applyGroupRestore(
        backupPath: path,
        group: 'Clientes',
        replace: false,
      );

      expect(result.added, 1); // Carlos
      expect(result.updated, 0);
      expect(result.kept, 2); // Ana (igual) + Beto (diferente, se mantuvo)

      final all = await db.customersDao.getAllCustomers();
      final names = all.map((c) => c.name).toSet();
      expect(names, containsAll(['Ana', 'Beto', 'Carlos']));
      expect(names, isNot(contains('Beto Modificado')));
    });

    test('merge: con la fila del respaldo resuelta, sobrescribe esa fila',
        () async {
      await addCurrentCustomer('Ana'); // id 1
      await addCurrentCustomer('Beto'); // id 2

      final path = await makeBackupWithCustomers([
        (name: 'Ana', phone: null),
        (name: 'Beto Modificado', phone: null),
        (name: 'Carlos', phone: null),
      ]);

      // La pantalla arma la fila resuelta a partir del preview; aquí se hace
      // igual: se toma tal cual la fila del respaldo para el id 2.
      final diffs =
          await backup.previewGroupRestore(backupPath: path, group: 'Clientes');
      final beto2 = diffs.firstWhere((d) => d.id == 2);

      final result = await backup.applyGroupRestore(
        backupPath: path,
        group: 'Clientes',
        replace: false,
        resolvedRows: {'customers:2': beto2.backupValues},
      );

      expect(result.added, 1); // Carlos
      expect(result.updated, 1); // Beto → Beto Modificado
      expect(result.kept, 1); // Ana

      final beto = (await db.customersDao.getAllCustomers())
          .firstWhere((c) => c.id == 2);
      expect(beto.name, 'Beto Modificado');
    });

    test('merge a nivel columna: mezcla campos de actual y de respaldo',
        () async {
      // Ana actual: nombre 'Ana', teléfono '111'. En el respaldo cambió todo
      // (nombre 'Ana Cambiada', teléfono '999'). Se quiere conservar el
      // nombre actual pero tomar el teléfono del respaldo.
      await addCurrentCustomer('Ana', phone: '111'); // id 1

      final path = await makeBackupWithCustomers([
        (name: 'Ana Cambiada', phone: '999'), // id 1
      ]);

      final diffs =
          await backup.previewGroupRestore(backupPath: path, group: 'Clientes');
      final ana = diffs.firstWhere((d) => d.id == 1);
      expect(ana.status, RestoreRowStatus.diferente);

      // Fila mezclada: parte de la actual, pero con el teléfono del respaldo.
      final merged = {...ana.currentValues, 'phone': ana.backupValues['phone']};

      final result = await backup.applyGroupRestore(
        backupPath: path,
        group: 'Clientes',
        replace: false,
        resolvedRows: {'customers:1': merged},
      );

      expect(result.updated, 1);
      final anaAfter = (await db.customersDao.getAllCustomers())
          .firstWhere((c) => c.id == 1);
      expect(anaAfter.name, 'Ana', reason: 'el nombre se mantuvo (actual)');
      expect(anaAfter.phone, '999', reason: 'el teléfono se tomó del respaldo');
    });

    test('reemplazar: deja exactamente las filas del respaldo', () async {
      await addCurrentCustomer('Ana'); // id 1
      await addCurrentCustomer('SoloActual'); // id 2 — no está en el respaldo

      final path = await makeBackupWithCustomers([
        (name: 'Ana', phone: null),
        (name: 'Nuevo Beto', phone: null),
      ]);

      final result = await backup.applyGroupRestore(
        backupPath: path,
        group: 'Clientes',
        replace: true,
      );

      expect(result.added, 2);
      final names =
          (await db.customersDao.getAllCustomers()).map((c) => c.name).toSet();
      expect(names, {'Ana', 'Nuevo Beto'});
      // 'SoloActual' se fue: reemplazar borra lo que no esté en el respaldo.
      expect(names, isNot(contains('SoloActual')));
    });

    test('reemplazar revierte COMPLETO si una fila sigue referenciada',
        () async {
      // Un empleado y un cliente con una venta que apunta a ese cliente:
      // borrar el cliente (lo que hace "reemplazar") viola la FK de orders y
      // debe abortar todo sin cambiar nada.
      final empId = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(name: 'Caja', pin: '1234', role: 'cashier'),
      );
      final cliId = await addCurrentCustomer('Ana'); // id 1
      await db.into(db.orders).insert(OrdersCompanion.insert(
            orderNumber: 'A-001',
            type: 'para_llevar',
            employeeId: empId,
            customerId: Value(cliId),
          ));

      final path = await makeBackupWithCustomers([
        (name: 'Otro', phone: null),
      ]);

      await expectLater(
        backup.applyGroupRestore(
            backupPath: path, group: 'Clientes', replace: true),
        throwsA(anything),
      );

      // La base quedó intacta: Ana sigue ahí, no entró 'Otro'.
      final names =
          (await db.customersDao.getAllCustomers()).map((c) => c.name).toSet();
      expect(names, {'Ana'});
    });

    test('grupo no restaurable (Operación) lanza ArgumentError', () async {
      final path = await makeBackupWithCustomers([(name: 'Ana', phone: null)]);
      expect(
        () => backup.previewGroupRestore(backupPath: path, group: 'Operación'),
        throwsArgumentError,
      );
    });
  });
}
