import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';
import 'package:latercia/core/utils/pin_hasher.dart';

void main() {
  group('hashPin', () {
    test('es determinista', () {
      expect(hashPin('1234'), hashPin('1234'));
    });

    test('no expone el PIN en claro', () {
      final h = hashPin('1234');
      expect(h.contains('1234'), isFalse);
      expect(h.length, 64); // SHA-256 hex
    });

    test('PINs distintos producen hashes distintos', () {
      expect(hashPin('0000'), isNot(hashPin('1234')));
    });

    test('isDefaultAdminPin detecta el PIN sembrado', () {
      expect(isDefaultAdminPin(hashPin('0000')), isTrue);
      expect(isDefaultAdminPin(hashPin('1234')), isFalse);
    });
  });

  group('findByPin (C5, end-to-end)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('encuentra al admin sembrado con su PIN en claro', () async {
      final admin = await db.employeesDao.findByPin('0000');
      expect(admin, isNotNull);
      expect(admin!.role, 'admin');
      // Lo almacenado nunca es el PIN en claro.
      expect(admin.pin, isNot('0000'));
      expect(admin.pin, hashPin('0000'));
    });

    test('un PIN incorrecto no encuentra empleado', () async {
      expect(await db.employeesDao.findByPin('9999'), isNull);
    });

    test('un empleado nuevo con PIN hasheado se puede autenticar', () async {
      await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
            name: 'Mesero', pin: hashPin('4321'), role: 'cashier'),
      );
      final found = await db.employeesDao.findByPin('4321');
      expect(found, isNotNull);
      expect(found!.name, 'Mesero');
    });
  });

  // A2 (2026-07-18) — impedir dos empleados activos con el mismo PIN.
  group('pinInUseByActive (A2 — PINs únicos)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('detecta un PIN ya usado por un empleado activo', () async {
      await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
            name: 'Caja 1', pin: hashPin('1111'), role: 'cashier'),
      );
      expect(await db.employeesDao.pinInUseByActive('1111'), isTrue);
      expect(await db.employeesDao.pinInUseByActive('2222'), isFalse);
    });

    test('excludeId ignora al propio empleado (para poder editarlo)', () async {
      final id = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
            name: 'Caja 1', pin: hashPin('1111'), role: 'cashier'),
      );
      // Con exclusión de sí mismo, su propio PIN no cuenta como "en uso".
      expect(await db.employeesDao.pinInUseByActive('1111', excludeId: id),
          isFalse);
      // Sin exclusión, sí cuenta (otro empleado no podría tomarlo).
      expect(await db.employeesDao.pinInUseByActive('1111'), isTrue);
    });

    test('un empleado INACTIVO no reserva el PIN', () async {
      final id = await db.employeesDao.insertEmployee(
        EmployeesCompanion.insert(
            name: 'Ex empleado', pin: hashPin('1111'), role: 'cashier'),
      );
      await db.employeesDao.toggleActive(id, false);
      // Dado de baja: su PIN queda libre para reutilizarse.
      expect(await db.employeesDao.pinInUseByActive('1111'), isFalse);
    });
  });
}
