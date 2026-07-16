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
}
