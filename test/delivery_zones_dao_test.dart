import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('insertar, listar y desactivar zonas', () async {
    final id = await db.deliveryZonesDao.insertZone(
      DeliveryZonesCompanion.insert(name: 'Chicxulub', fee: const Value(15)),
    );

    var active = await db.deliveryZonesDao.getActiveZones();
    expect(active, hasLength(1));
    expect(active.first.name, 'Chicxulub');
    expect(active.first.fee, 15);

    await db.deliveryZonesDao.setActive(id, false);
    active = await db.deliveryZonesDao.getActiveZones();
    expect(active, isEmpty);

    final all = await db.deliveryZonesDao.getAllZones();
    expect(all, hasLength(1), reason: 'soft delete — la fila sigue existiendo');
  });

  test('updateZone actualiza nombre y cargo', () async {
    final id = await db.deliveryZonesDao.insertZone(
      DeliveryZonesCompanion.insert(name: 'Progreso 1', fee: const Value(20)),
    );
    await db.deliveryZonesDao.updateZone(
      DeliveryZonesCompanion(id: Value(id), fee: const Value(22)),
    );

    final zone =
        (await db.deliveryZonesDao.getAllZones()).firstWhere((z) => z.id == id);
    expect(zone.fee, 22);
    expect(zone.name, 'Progreso 1', reason: 'campo no tocado en el update');
  });
}
