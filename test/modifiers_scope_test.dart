import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latercia/core/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> addModifier(String name, {String? scope}) {
    return db.modifiersDao.insertModifier(
      ModifiersCompanion.insert(
        name: name,
        categoryScope: Value(scope),
      ),
    );
  }

  test('un modificador sin alcance aplica a cualquier categoría (I3)',
      () async {
    await addModifier('Salsa libre'); // scope null

    final forAny = await db.modifiersDao.getModifiersForCategoryName('Postres');
    expect(forAny.any((m) => m.name == 'Salsa libre'), isTrue);

    final forNull = await db.modifiersDao.getModifiersForCategoryName(null);
    expect(forNull.any((m) => m.name == 'Salsa libre'), isTrue);
  });

  test('un modificador con alcance solo aplica a su categoría (I3)', () async {
    await addModifier('Topping especial', scope: 'Bebidas Calientes');

    final forCoffee =
        await db.modifiersDao.getModifiersForCategoryName('Bebidas Calientes');
    expect(forCoffee.any((m) => m.name == 'Topping especial'), isTrue);

    final forDessert =
        await db.modifiersDao.getModifiersForCategoryName('Postres');
    expect(forDessert.any((m) => m.name == 'Topping especial'), isFalse,
        reason: 'no debe aparecer "Topping especial" en un postre');
  });

  test('el alcance se compara sin distinguir mayúsculas (I3)', () async {
    await addModifier('Topping especial', scope: 'Bebidas Calientes');

    final forCoffee =
        await db.modifiersDao.getModifiersForCategoryName('bebidas calientes');
    expect(forCoffee.any((m) => m.name == 'Topping especial'), isTrue);
  });

  test('sin categoría, solo aplican los modificadores sin alcance (I3)',
      () async {
    await addModifier('Global'); // null scope
    await addModifier('Topping especial', scope: 'Bebidas Calientes');

    final forNull = await db.modifiersDao.getModifiersForCategoryName(null);
    expect(forNull.any((m) => m.name == 'Global'), isTrue);
    expect(forNull.any((m) => m.name == 'Topping especial'), isFalse);
  });

  // FASE 8 — un modificador puede aplicar a varias categorías (ej. un
  // topping que se usa tanto en Frappés como en Especialidades).
  test(
      'un alcance con varias categorías separadas por coma aplica a '
      'cualquiera de ellas', () async {
    await addModifier('Topping 1', scope: 'Frappés,Especialidades');

    final forFrappes =
        await db.modifiersDao.getModifiersForCategoryName('Frappés');
    expect(forFrappes.any((m) => m.name == 'Topping 1'), isTrue);

    final forEspecialidades =
        await db.modifiersDao.getModifiersForCategoryName('Especialidades');
    expect(forEspecialidades.any((m) => m.name == 'Topping 1'), isTrue);

    final forSnacks =
        await db.modifiersDao.getModifiersForCategoryName('Snacks Salados');
    expect(forSnacks.any((m) => m.name == 'Topping 1'), isFalse);
  });

  test('el alcance multi-categoría tolera espacios alrededor de cada nombre',
      () async {
    await addModifier('Aderezo', scope: ' Snacks Salados , Combos ');

    final forCombos =
        await db.modifiersDao.getModifiersForCategoryName('Combos');
    expect(forCombos.any((m) => m.name == 'Aderezo'), isTrue);
  });
}
