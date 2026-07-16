// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tables_dao.dart';

// ignore_for_file: type=lint
mixin _$TablesDaoMixin on DatabaseAccessor<AppDatabase> {
  $TablesLayoutTable get tablesLayout => attachedDatabase.tablesLayout;
  TablesDaoManager get managers => TablesDaoManager(this);
}

class TablesDaoManager {
  final _$TablesDaoMixin _db;
  TablesDaoManager(this._db);
  $$TablesLayoutTableTableManager get tablesLayout =>
      $$TablesLayoutTableTableManager(_db.attachedDatabase, _db.tablesLayout);
}
