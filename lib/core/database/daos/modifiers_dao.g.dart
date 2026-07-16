// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modifiers_dao.dart';

// ignore_for_file: type=lint
mixin _$ModifiersDaoMixin on DatabaseAccessor<AppDatabase> {
  $ModifiersTable get modifiers => attachedDatabase.modifiers;
  ModifiersDaoManager get managers => ModifiersDaoManager(this);
}

class ModifiersDaoManager {
  final _$ModifiersDaoMixin _db;
  ModifiersDaoManager(this._db);
  $$ModifiersTableTableManager get modifiers =>
      $$ModifiersTableTableManager(_db.attachedDatabase, _db.modifiers);
}
