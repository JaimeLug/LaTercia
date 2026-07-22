// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String? value;
  const Setting({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  Setting copyWith(
          {String? key, Value<String?> value = const Value.absent()}) =>
      Setting(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String?>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, color, icon, sortOrder, active];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final String color;
  final String icon;
  final int sortOrder;
  final bool active;
  const Category(
      {required this.id,
      required this.name,
      required this.color,
      required this.icon,
      required this.sortOrder,
      required this.active});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    map['icon'] = Variable<String>(icon);
    map['sort_order'] = Variable<int>(sortOrder);
    map['active'] = Variable<bool>(active);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      icon: Value(icon),
      sortOrder: Value(sortOrder),
      active: Value(active),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      icon: serializer.fromJson<String>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'icon': serializer.toJson<String>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'active': serializer.toJson<bool>(active),
    };
  }

  Category copyWith(
          {int? id,
          String? name,
          String? color,
          String? icon,
          int? sortOrder,
          bool? active}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
        active: active ?? this.active,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, icon, sortOrder, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder &&
          other.active == this.active);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> color;
  final Value<String> icon;
  final Value<int> sortOrder;
  final Value<bool> active;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.active = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String color,
    required String icon,
    this.sortOrder = const Value.absent(),
    this.active = const Value.absent(),
  })  : name = Value(name),
        color = Value(color),
        icon = Value(icon);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (active != null) 'active': active,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? color,
      Value<String>? icon,
      Value<int>? sortOrder,
      Value<bool>? active}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
      'cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _availableMeta =
      const VerificationMeta('available');
  @override
  late final GeneratedColumn<bool> available = GeneratedColumn<bool>(
      'available', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("available" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _trackInventoryMeta =
      const VerificationMeta('trackInventory');
  @override
  late final GeneratedColumn<bool> trackInventory = GeneratedColumn<bool>(
      'track_inventory', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("track_inventory" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _stockQuantityMeta =
      const VerificationMeta('stockQuantity');
  @override
  late final GeneratedColumn<int> stockQuantity = GeneratedColumn<int>(
      'stock_quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minStockMeta =
      const VerificationMeta('minStock');
  @override
  late final GeneratedColumn<int> minStock = GeneratedColumn<int>(
      'min_stock', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _taxRateMeta =
      const VerificationMeta('taxRate');
  @override
  late final GeneratedColumn<double> taxRate = GeneratedColumn<double>(
      'tax_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _taxIncludedMeta =
      const VerificationMeta('taxIncluded');
  @override
  late final GeneratedColumn<bool> taxIncluded = GeneratedColumn<bool>(
      'tax_included', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("tax_included" IN (0, 1))'));
  static const VerificationMeta _usesRecipeMeta =
      const VerificationMeta('usesRecipe');
  @override
  late final GeneratedColumn<bool> usesRecipe = GeneratedColumn<bool>(
      'uses_recipe', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("uses_recipe" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _claveProdServMeta =
      const VerificationMeta('claveProdServ');
  @override
  late final GeneratedColumn<String> claveProdServ = GeneratedColumn<String>(
      'clave_prod_serv', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _claveUnidadMeta =
      const VerificationMeta('claveUnidad');
  @override
  late final GeneratedColumn<String> claveUnidad = GeneratedColumn<String>(
      'clave_unidad', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _objetoImpMeta =
      const VerificationMeta('objetoImp');
  @override
  late final GeneratedColumn<String> objetoImp = GeneratedColumn<String>(
      'objeto_imp', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        price,
        cost,
        categoryId,
        sku,
        imagePath,
        available,
        trackInventory,
        stockQuantity,
        minStock,
        taxRate,
        taxIncluded,
        usesRecipe,
        claveProdServ,
        claveUnidad,
        objetoImp,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
          _costMeta, cost.isAcceptableOrUnknown(data['cost']!, _costMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('available')) {
      context.handle(_availableMeta,
          available.isAcceptableOrUnknown(data['available']!, _availableMeta));
    }
    if (data.containsKey('track_inventory')) {
      context.handle(
          _trackInventoryMeta,
          trackInventory.isAcceptableOrUnknown(
              data['track_inventory']!, _trackInventoryMeta));
    }
    if (data.containsKey('stock_quantity')) {
      context.handle(
          _stockQuantityMeta,
          stockQuantity.isAcceptableOrUnknown(
              data['stock_quantity']!, _stockQuantityMeta));
    }
    if (data.containsKey('min_stock')) {
      context.handle(_minStockMeta,
          minStock.isAcceptableOrUnknown(data['min_stock']!, _minStockMeta));
    }
    if (data.containsKey('tax_rate')) {
      context.handle(_taxRateMeta,
          taxRate.isAcceptableOrUnknown(data['tax_rate']!, _taxRateMeta));
    }
    if (data.containsKey('tax_included')) {
      context.handle(
          _taxIncludedMeta,
          taxIncluded.isAcceptableOrUnknown(
              data['tax_included']!, _taxIncludedMeta));
    }
    if (data.containsKey('uses_recipe')) {
      context.handle(
          _usesRecipeMeta,
          usesRecipe.isAcceptableOrUnknown(
              data['uses_recipe']!, _usesRecipeMeta));
    }
    if (data.containsKey('clave_prod_serv')) {
      context.handle(
          _claveProdServMeta,
          claveProdServ.isAcceptableOrUnknown(
              data['clave_prod_serv']!, _claveProdServMeta));
    }
    if (data.containsKey('clave_unidad')) {
      context.handle(
          _claveUnidadMeta,
          claveUnidad.isAcceptableOrUnknown(
              data['clave_unidad']!, _claveUnidadMeta));
    }
    if (data.containsKey('objeto_imp')) {
      context.handle(_objetoImpMeta,
          objetoImp.isAcceptableOrUnknown(data['objeto_imp']!, _objetoImpMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      cost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      available: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}available'])!,
      trackInventory: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}track_inventory'])!,
      stockQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock_quantity'])!,
      minStock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_stock'])!,
      taxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_rate']),
      taxIncluded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}tax_included']),
      usesRecipe: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}uses_recipe'])!,
      claveProdServ: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}clave_prod_serv']),
      claveUnidad: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}clave_unidad']),
      objetoImp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}objeto_imp']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double cost;
  final int categoryId;
  final String? sku;
  final String? imagePath;
  final bool available;
  final bool trackInventory;
  final int stockQuantity;
  final int minStock;
  final double? taxRate;
  final bool? taxIncluded;
  final bool usesRecipe;
  final String? claveProdServ;
  final String? claveUnidad;
  final String? objetoImp;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Product(
      {required this.id,
      required this.name,
      this.description,
      required this.price,
      required this.cost,
      required this.categoryId,
      this.sku,
      this.imagePath,
      required this.available,
      required this.trackInventory,
      required this.stockQuantity,
      required this.minStock,
      this.taxRate,
      this.taxIncluded,
      required this.usesRecipe,
      this.claveProdServ,
      this.claveUnidad,
      this.objetoImp,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['price'] = Variable<double>(price);
    map['cost'] = Variable<double>(cost);
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['available'] = Variable<bool>(available);
    map['track_inventory'] = Variable<bool>(trackInventory);
    map['stock_quantity'] = Variable<int>(stockQuantity);
    map['min_stock'] = Variable<int>(minStock);
    if (!nullToAbsent || taxRate != null) {
      map['tax_rate'] = Variable<double>(taxRate);
    }
    if (!nullToAbsent || taxIncluded != null) {
      map['tax_included'] = Variable<bool>(taxIncluded);
    }
    map['uses_recipe'] = Variable<bool>(usesRecipe);
    if (!nullToAbsent || claveProdServ != null) {
      map['clave_prod_serv'] = Variable<String>(claveProdServ);
    }
    if (!nullToAbsent || claveUnidad != null) {
      map['clave_unidad'] = Variable<String>(claveUnidad);
    }
    if (!nullToAbsent || objetoImp != null) {
      map['objeto_imp'] = Variable<String>(objetoImp);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      price: Value(price),
      cost: Value(cost),
      categoryId: Value(categoryId),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      available: Value(available),
      trackInventory: Value(trackInventory),
      stockQuantity: Value(stockQuantity),
      minStock: Value(minStock),
      taxRate: taxRate == null && nullToAbsent
          ? const Value.absent()
          : Value(taxRate),
      taxIncluded: taxIncluded == null && nullToAbsent
          ? const Value.absent()
          : Value(taxIncluded),
      usesRecipe: Value(usesRecipe),
      claveProdServ: claveProdServ == null && nullToAbsent
          ? const Value.absent()
          : Value(claveProdServ),
      claveUnidad: claveUnidad == null && nullToAbsent
          ? const Value.absent()
          : Value(claveUnidad),
      objetoImp: objetoImp == null && nullToAbsent
          ? const Value.absent()
          : Value(objetoImp),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      price: serializer.fromJson<double>(json['price']),
      cost: serializer.fromJson<double>(json['cost']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      sku: serializer.fromJson<String?>(json['sku']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      available: serializer.fromJson<bool>(json['available']),
      trackInventory: serializer.fromJson<bool>(json['trackInventory']),
      stockQuantity: serializer.fromJson<int>(json['stockQuantity']),
      minStock: serializer.fromJson<int>(json['minStock']),
      taxRate: serializer.fromJson<double?>(json['taxRate']),
      taxIncluded: serializer.fromJson<bool?>(json['taxIncluded']),
      usesRecipe: serializer.fromJson<bool>(json['usesRecipe']),
      claveProdServ: serializer.fromJson<String?>(json['claveProdServ']),
      claveUnidad: serializer.fromJson<String?>(json['claveUnidad']),
      objetoImp: serializer.fromJson<String?>(json['objetoImp']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'price': serializer.toJson<double>(price),
      'cost': serializer.toJson<double>(cost),
      'categoryId': serializer.toJson<int>(categoryId),
      'sku': serializer.toJson<String?>(sku),
      'imagePath': serializer.toJson<String?>(imagePath),
      'available': serializer.toJson<bool>(available),
      'trackInventory': serializer.toJson<bool>(trackInventory),
      'stockQuantity': serializer.toJson<int>(stockQuantity),
      'minStock': serializer.toJson<int>(minStock),
      'taxRate': serializer.toJson<double?>(taxRate),
      'taxIncluded': serializer.toJson<bool?>(taxIncluded),
      'usesRecipe': serializer.toJson<bool>(usesRecipe),
      'claveProdServ': serializer.toJson<String?>(claveProdServ),
      'claveUnidad': serializer.toJson<String?>(claveUnidad),
      'objetoImp': serializer.toJson<String?>(objetoImp),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Product copyWith(
          {int? id,
          String? name,
          Value<String?> description = const Value.absent(),
          double? price,
          double? cost,
          int? categoryId,
          Value<String?> sku = const Value.absent(),
          Value<String?> imagePath = const Value.absent(),
          bool? available,
          bool? trackInventory,
          int? stockQuantity,
          int? minStock,
          Value<double?> taxRate = const Value.absent(),
          Value<bool?> taxIncluded = const Value.absent(),
          bool? usesRecipe,
          Value<String?> claveProdServ = const Value.absent(),
          Value<String?> claveUnidad = const Value.absent(),
          Value<String?> objetoImp = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        price: price ?? this.price,
        cost: cost ?? this.cost,
        categoryId: categoryId ?? this.categoryId,
        sku: sku.present ? sku.value : this.sku,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        available: available ?? this.available,
        trackInventory: trackInventory ?? this.trackInventory,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        minStock: minStock ?? this.minStock,
        taxRate: taxRate.present ? taxRate.value : this.taxRate,
        taxIncluded: taxIncluded.present ? taxIncluded.value : this.taxIncluded,
        usesRecipe: usesRecipe ?? this.usesRecipe,
        claveProdServ:
            claveProdServ.present ? claveProdServ.value : this.claveProdServ,
        claveUnidad: claveUnidad.present ? claveUnidad.value : this.claveUnidad,
        objetoImp: objetoImp.present ? objetoImp.value : this.objetoImp,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      price: data.price.present ? data.price.value : this.price,
      cost: data.cost.present ? data.cost.value : this.cost,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      sku: data.sku.present ? data.sku.value : this.sku,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      available: data.available.present ? data.available.value : this.available,
      trackInventory: data.trackInventory.present
          ? data.trackInventory.value
          : this.trackInventory,
      stockQuantity: data.stockQuantity.present
          ? data.stockQuantity.value
          : this.stockQuantity,
      minStock: data.minStock.present ? data.minStock.value : this.minStock,
      taxRate: data.taxRate.present ? data.taxRate.value : this.taxRate,
      taxIncluded:
          data.taxIncluded.present ? data.taxIncluded.value : this.taxIncluded,
      usesRecipe:
          data.usesRecipe.present ? data.usesRecipe.value : this.usesRecipe,
      claveProdServ: data.claveProdServ.present
          ? data.claveProdServ.value
          : this.claveProdServ,
      claveUnidad:
          data.claveUnidad.present ? data.claveUnidad.value : this.claveUnidad,
      objetoImp: data.objetoImp.present ? data.objetoImp.value : this.objetoImp,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('cost: $cost, ')
          ..write('categoryId: $categoryId, ')
          ..write('sku: $sku, ')
          ..write('imagePath: $imagePath, ')
          ..write('available: $available, ')
          ..write('trackInventory: $trackInventory, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minStock: $minStock, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxIncluded: $taxIncluded, ')
          ..write('usesRecipe: $usesRecipe, ')
          ..write('claveProdServ: $claveProdServ, ')
          ..write('claveUnidad: $claveUnidad, ')
          ..write('objetoImp: $objetoImp, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      price,
      cost,
      categoryId,
      sku,
      imagePath,
      available,
      trackInventory,
      stockQuantity,
      minStock,
      taxRate,
      taxIncluded,
      usesRecipe,
      claveProdServ,
      claveUnidad,
      objetoImp,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price &&
          other.cost == this.cost &&
          other.categoryId == this.categoryId &&
          other.sku == this.sku &&
          other.imagePath == this.imagePath &&
          other.available == this.available &&
          other.trackInventory == this.trackInventory &&
          other.stockQuantity == this.stockQuantity &&
          other.minStock == this.minStock &&
          other.taxRate == this.taxRate &&
          other.taxIncluded == this.taxIncluded &&
          other.usesRecipe == this.usesRecipe &&
          other.claveProdServ == this.claveProdServ &&
          other.claveUnidad == this.claveUnidad &&
          other.objetoImp == this.objetoImp &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> price;
  final Value<double> cost;
  final Value<int> categoryId;
  final Value<String?> sku;
  final Value<String?> imagePath;
  final Value<bool> available;
  final Value<bool> trackInventory;
  final Value<int> stockQuantity;
  final Value<int> minStock;
  final Value<double?> taxRate;
  final Value<bool?> taxIncluded;
  final Value<bool> usesRecipe;
  final Value<String?> claveProdServ;
  final Value<String?> claveUnidad;
  final Value<String?> objetoImp;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.cost = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.sku = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.available = const Value.absent(),
    this.trackInventory = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.minStock = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxIncluded = const Value.absent(),
    this.usesRecipe = const Value.absent(),
    this.claveProdServ = const Value.absent(),
    this.claveUnidad = const Value.absent(),
    this.objetoImp = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required double price,
    this.cost = const Value.absent(),
    required int categoryId,
    this.sku = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.available = const Value.absent(),
    this.trackInventory = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.minStock = const Value.absent(),
    this.taxRate = const Value.absent(),
    this.taxIncluded = const Value.absent(),
    this.usesRecipe = const Value.absent(),
    this.claveProdServ = const Value.absent(),
    this.claveUnidad = const Value.absent(),
    this.objetoImp = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        price = Value(price),
        categoryId = Value(categoryId);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? price,
    Expression<double>? cost,
    Expression<int>? categoryId,
    Expression<String>? sku,
    Expression<String>? imagePath,
    Expression<bool>? available,
    Expression<bool>? trackInventory,
    Expression<int>? stockQuantity,
    Expression<int>? minStock,
    Expression<double>? taxRate,
    Expression<bool>? taxIncluded,
    Expression<bool>? usesRecipe,
    Expression<String>? claveProdServ,
    Expression<String>? claveUnidad,
    Expression<String>? objetoImp,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (cost != null) 'cost': cost,
      if (categoryId != null) 'category_id': categoryId,
      if (sku != null) 'sku': sku,
      if (imagePath != null) 'image_path': imagePath,
      if (available != null) 'available': available,
      if (trackInventory != null) 'track_inventory': trackInventory,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      if (minStock != null) 'min_stock': minStock,
      if (taxRate != null) 'tax_rate': taxRate,
      if (taxIncluded != null) 'tax_included': taxIncluded,
      if (usesRecipe != null) 'uses_recipe': usesRecipe,
      if (claveProdServ != null) 'clave_prod_serv': claveProdServ,
      if (claveUnidad != null) 'clave_unidad': claveUnidad,
      if (objetoImp != null) 'objeto_imp': objetoImp,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<double>? price,
      Value<double>? cost,
      Value<int>? categoryId,
      Value<String?>? sku,
      Value<String?>? imagePath,
      Value<bool>? available,
      Value<bool>? trackInventory,
      Value<int>? stockQuantity,
      Value<int>? minStock,
      Value<double?>? taxRate,
      Value<bool?>? taxIncluded,
      Value<bool>? usesRecipe,
      Value<String?>? claveProdServ,
      Value<String?>? claveUnidad,
      Value<String?>? objetoImp,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      categoryId: categoryId ?? this.categoryId,
      sku: sku ?? this.sku,
      imagePath: imagePath ?? this.imagePath,
      available: available ?? this.available,
      trackInventory: trackInventory ?? this.trackInventory,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStock: minStock ?? this.minStock,
      taxRate: taxRate ?? this.taxRate,
      taxIncluded: taxIncluded ?? this.taxIncluded,
      usesRecipe: usesRecipe ?? this.usesRecipe,
      claveProdServ: claveProdServ ?? this.claveProdServ,
      claveUnidad: claveUnidad ?? this.claveUnidad,
      objetoImp: objetoImp ?? this.objetoImp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (available.present) {
      map['available'] = Variable<bool>(available.value);
    }
    if (trackInventory.present) {
      map['track_inventory'] = Variable<bool>(trackInventory.value);
    }
    if (stockQuantity.present) {
      map['stock_quantity'] = Variable<int>(stockQuantity.value);
    }
    if (minStock.present) {
      map['min_stock'] = Variable<int>(minStock.value);
    }
    if (taxRate.present) {
      map['tax_rate'] = Variable<double>(taxRate.value);
    }
    if (taxIncluded.present) {
      map['tax_included'] = Variable<bool>(taxIncluded.value);
    }
    if (usesRecipe.present) {
      map['uses_recipe'] = Variable<bool>(usesRecipe.value);
    }
    if (claveProdServ.present) {
      map['clave_prod_serv'] = Variable<String>(claveProdServ.value);
    }
    if (claveUnidad.present) {
      map['clave_unidad'] = Variable<String>(claveUnidad.value);
    }
    if (objetoImp.present) {
      map['objeto_imp'] = Variable<String>(objetoImp.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('cost: $cost, ')
          ..write('categoryId: $categoryId, ')
          ..write('sku: $sku, ')
          ..write('imagePath: $imagePath, ')
          ..write('available: $available, ')
          ..write('trackInventory: $trackInventory, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minStock: $minStock, ')
          ..write('taxRate: $taxRate, ')
          ..write('taxIncluded: $taxIncluded, ')
          ..write('usesRecipe: $usesRecipe, ')
          ..write('claveProdServ: $claveProdServ, ')
          ..write('claveUnidad: $claveUnidad, ')
          ..write('objetoImp: $objetoImp, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ModifiersTable extends Modifiers
    with TableInfo<$ModifiersTable, Modifier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModifiersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceDeltaMeta =
      const VerificationMeta('priceDelta');
  @override
  late final GeneratedColumn<double> priceDelta = GeneratedColumn<double>(
      'price_delta', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _categoryScopeMeta =
      const VerificationMeta('categoryScope');
  @override
  late final GeneratedColumn<String> categoryScope = GeneratedColumn<String>(
      'category_scope', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, priceDelta, categoryScope];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'modifiers';
  @override
  VerificationContext validateIntegrity(Insertable<Modifier> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price_delta')) {
      context.handle(
          _priceDeltaMeta,
          priceDelta.isAcceptableOrUnknown(
              data['price_delta']!, _priceDeltaMeta));
    }
    if (data.containsKey('category_scope')) {
      context.handle(
          _categoryScopeMeta,
          categoryScope.isAcceptableOrUnknown(
              data['category_scope']!, _categoryScopeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Modifier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Modifier(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      priceDelta: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_delta'])!,
      categoryScope: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_scope']),
    );
  }

  @override
  $ModifiersTable createAlias(String alias) {
    return $ModifiersTable(attachedDatabase, alias);
  }
}

class Modifier extends DataClass implements Insertable<Modifier> {
  final int id;
  final String name;
  final double priceDelta;
  final String? categoryScope;
  const Modifier(
      {required this.id,
      required this.name,
      required this.priceDelta,
      this.categoryScope});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['price_delta'] = Variable<double>(priceDelta);
    if (!nullToAbsent || categoryScope != null) {
      map['category_scope'] = Variable<String>(categoryScope);
    }
    return map;
  }

  ModifiersCompanion toCompanion(bool nullToAbsent) {
    return ModifiersCompanion(
      id: Value(id),
      name: Value(name),
      priceDelta: Value(priceDelta),
      categoryScope: categoryScope == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryScope),
    );
  }

  factory Modifier.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Modifier(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      priceDelta: serializer.fromJson<double>(json['priceDelta']),
      categoryScope: serializer.fromJson<String?>(json['categoryScope']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'priceDelta': serializer.toJson<double>(priceDelta),
      'categoryScope': serializer.toJson<String?>(categoryScope),
    };
  }

  Modifier copyWith(
          {int? id,
          String? name,
          double? priceDelta,
          Value<String?> categoryScope = const Value.absent()}) =>
      Modifier(
        id: id ?? this.id,
        name: name ?? this.name,
        priceDelta: priceDelta ?? this.priceDelta,
        categoryScope:
            categoryScope.present ? categoryScope.value : this.categoryScope,
      );
  Modifier copyWithCompanion(ModifiersCompanion data) {
    return Modifier(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      priceDelta:
          data.priceDelta.present ? data.priceDelta.value : this.priceDelta,
      categoryScope: data.categoryScope.present
          ? data.categoryScope.value
          : this.categoryScope,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Modifier(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('priceDelta: $priceDelta, ')
          ..write('categoryScope: $categoryScope')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, priceDelta, categoryScope);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Modifier &&
          other.id == this.id &&
          other.name == this.name &&
          other.priceDelta == this.priceDelta &&
          other.categoryScope == this.categoryScope);
}

class ModifiersCompanion extends UpdateCompanion<Modifier> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> priceDelta;
  final Value<String?> categoryScope;
  const ModifiersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.priceDelta = const Value.absent(),
    this.categoryScope = const Value.absent(),
  });
  ModifiersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.priceDelta = const Value.absent(),
    this.categoryScope = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Modifier> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? priceDelta,
    Expression<String>? categoryScope,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (priceDelta != null) 'price_delta': priceDelta,
      if (categoryScope != null) 'category_scope': categoryScope,
    });
  }

  ModifiersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? priceDelta,
      Value<String?>? categoryScope}) {
    return ModifiersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      priceDelta: priceDelta ?? this.priceDelta,
      categoryScope: categoryScope ?? this.categoryScope,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (priceDelta.present) {
      map['price_delta'] = Variable<double>(priceDelta.value);
    }
    if (categoryScope.present) {
      map['category_scope'] = Variable<String>(categoryScope.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModifiersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('priceDelta: $priceDelta, ')
          ..write('categoryScope: $categoryScope')
          ..write(')'))
        .toString();
  }
}

class $DiscountsTable extends Discounts
    with TableInfo<$DiscountsTable, Discount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiscountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _minOrderAmountMeta =
      const VerificationMeta('minOrderAmount');
  @override
  late final GeneratedColumn<double> minOrderAmount = GeneratedColumn<double>(
      'min_order_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _validFromMeta =
      const VerificationMeta('validFrom');
  @override
  late final GeneratedColumn<DateTime> validFrom = GeneratedColumn<DateTime>(
      'valid_from', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _validUntilMeta =
      const VerificationMeta('validUntil');
  @override
  late final GeneratedColumn<DateTime> validUntil = GeneratedColumn<DateTime>(
      'valid_until', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _daysOfWeekMeta =
      const VerificationMeta('daysOfWeek');
  @override
  late final GeneratedColumn<String> daysOfWeek = GeneratedColumn<String>(
      'days_of_week', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
      'start_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
      'end_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryScopeMeta =
      const VerificationMeta('categoryScope');
  @override
  late final GeneratedColumn<String> categoryScope = GeneratedColumn<String>(
      'category_scope', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        value,
        minOrderAmount,
        active,
        validFrom,
        validUntil,
        daysOfWeek,
        startTime,
        endTime,
        categoryScope,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'discounts';
  @override
  VerificationContext validateIntegrity(Insertable<Discount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('min_order_amount')) {
      context.handle(
          _minOrderAmountMeta,
          minOrderAmount.isAcceptableOrUnknown(
              data['min_order_amount']!, _minOrderAmountMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('valid_from')) {
      context.handle(_validFromMeta,
          validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta));
    }
    if (data.containsKey('valid_until')) {
      context.handle(
          _validUntilMeta,
          validUntil.isAcceptableOrUnknown(
              data['valid_until']!, _validUntilMeta));
    }
    if (data.containsKey('days_of_week')) {
      context.handle(
          _daysOfWeekMeta,
          daysOfWeek.isAcceptableOrUnknown(
              data['days_of_week']!, _daysOfWeekMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('category_scope')) {
      context.handle(
          _categoryScopeMeta,
          categoryScope.isAcceptableOrUnknown(
              data['category_scope']!, _categoryScopeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Discount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Discount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      minOrderAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}min_order_amount'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      validFrom: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}valid_from']),
      validUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}valid_until']),
      daysOfWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}days_of_week']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_time']),
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_time']),
      categoryScope: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_scope']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DiscountsTable createAlias(String alias) {
    return $DiscountsTable(attachedDatabase, alias);
  }
}

class Discount extends DataClass implements Insertable<Discount> {
  final int id;
  final String name;
  final String type;
  final double value;
  final double minOrderAmount;
  final bool active;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? daysOfWeek;
  final String? startTime;
  final String? endTime;
  final String? categoryScope;
  final DateTime createdAt;
  const Discount(
      {required this.id,
      required this.name,
      required this.type,
      required this.value,
      required this.minOrderAmount,
      required this.active,
      this.validFrom,
      this.validUntil,
      this.daysOfWeek,
      this.startTime,
      this.endTime,
      this.categoryScope,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['value'] = Variable<double>(value);
    map['min_order_amount'] = Variable<double>(minOrderAmount);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || validFrom != null) {
      map['valid_from'] = Variable<DateTime>(validFrom);
    }
    if (!nullToAbsent || validUntil != null) {
      map['valid_until'] = Variable<DateTime>(validUntil);
    }
    if (!nullToAbsent || daysOfWeek != null) {
      map['days_of_week'] = Variable<String>(daysOfWeek);
    }
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    if (!nullToAbsent || categoryScope != null) {
      map['category_scope'] = Variable<String>(categoryScope);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DiscountsCompanion toCompanion(bool nullToAbsent) {
    return DiscountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      value: Value(value),
      minOrderAmount: Value(minOrderAmount),
      active: Value(active),
      validFrom: validFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(validFrom),
      validUntil: validUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(validUntil),
      daysOfWeek: daysOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(daysOfWeek),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      categoryScope: categoryScope == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryScope),
      createdAt: Value(createdAt),
    );
  }

  factory Discount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Discount(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<double>(json['value']),
      minOrderAmount: serializer.fromJson<double>(json['minOrderAmount']),
      active: serializer.fromJson<bool>(json['active']),
      validFrom: serializer.fromJson<DateTime?>(json['validFrom']),
      validUntil: serializer.fromJson<DateTime?>(json['validUntil']),
      daysOfWeek: serializer.fromJson<String?>(json['daysOfWeek']),
      startTime: serializer.fromJson<String?>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      categoryScope: serializer.fromJson<String?>(json['categoryScope']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<double>(value),
      'minOrderAmount': serializer.toJson<double>(minOrderAmount),
      'active': serializer.toJson<bool>(active),
      'validFrom': serializer.toJson<DateTime?>(validFrom),
      'validUntil': serializer.toJson<DateTime?>(validUntil),
      'daysOfWeek': serializer.toJson<String?>(daysOfWeek),
      'startTime': serializer.toJson<String?>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'categoryScope': serializer.toJson<String?>(categoryScope),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Discount copyWith(
          {int? id,
          String? name,
          String? type,
          double? value,
          double? minOrderAmount,
          bool? active,
          Value<DateTime?> validFrom = const Value.absent(),
          Value<DateTime?> validUntil = const Value.absent(),
          Value<String?> daysOfWeek = const Value.absent(),
          Value<String?> startTime = const Value.absent(),
          Value<String?> endTime = const Value.absent(),
          Value<String?> categoryScope = const Value.absent(),
          DateTime? createdAt}) =>
      Discount(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        value: value ?? this.value,
        minOrderAmount: minOrderAmount ?? this.minOrderAmount,
        active: active ?? this.active,
        validFrom: validFrom.present ? validFrom.value : this.validFrom,
        validUntil: validUntil.present ? validUntil.value : this.validUntil,
        daysOfWeek: daysOfWeek.present ? daysOfWeek.value : this.daysOfWeek,
        startTime: startTime.present ? startTime.value : this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        categoryScope:
            categoryScope.present ? categoryScope.value : this.categoryScope,
        createdAt: createdAt ?? this.createdAt,
      );
  Discount copyWithCompanion(DiscountsCompanion data) {
    return Discount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
      minOrderAmount: data.minOrderAmount.present
          ? data.minOrderAmount.value
          : this.minOrderAmount,
      active: data.active.present ? data.active.value : this.active,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validUntil:
          data.validUntil.present ? data.validUntil.value : this.validUntil,
      daysOfWeek:
          data.daysOfWeek.present ? data.daysOfWeek.value : this.daysOfWeek,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      categoryScope: data.categoryScope.present
          ? data.categoryScope.value
          : this.categoryScope,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Discount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('minOrderAmount: $minOrderAmount, ')
          ..write('active: $active, ')
          ..write('validFrom: $validFrom, ')
          ..write('validUntil: $validUntil, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('categoryScope: $categoryScope, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      type,
      value,
      minOrderAmount,
      active,
      validFrom,
      validUntil,
      daysOfWeek,
      startTime,
      endTime,
      categoryScope,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Discount &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.value == this.value &&
          other.minOrderAmount == this.minOrderAmount &&
          other.active == this.active &&
          other.validFrom == this.validFrom &&
          other.validUntil == this.validUntil &&
          other.daysOfWeek == this.daysOfWeek &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.categoryScope == this.categoryScope &&
          other.createdAt == this.createdAt);
}

class DiscountsCompanion extends UpdateCompanion<Discount> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<double> value;
  final Value<double> minOrderAmount;
  final Value<bool> active;
  final Value<DateTime?> validFrom;
  final Value<DateTime?> validUntil;
  final Value<String?> daysOfWeek;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<String?> categoryScope;
  final Value<DateTime> createdAt;
  const DiscountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.minOrderAmount = const Value.absent(),
    this.active = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validUntil = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.categoryScope = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DiscountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    required double value,
    this.minOrderAmount = const Value.absent(),
    this.active = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validUntil = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.categoryScope = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        type = Value(type),
        value = Value(value);
  static Insertable<Discount> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<double>? value,
    Expression<double>? minOrderAmount,
    Expression<bool>? active,
    Expression<DateTime>? validFrom,
    Expression<DateTime>? validUntil,
    Expression<String>? daysOfWeek,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? categoryScope,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (minOrderAmount != null) 'min_order_amount': minOrderAmount,
      if (active != null) 'active': active,
      if (validFrom != null) 'valid_from': validFrom,
      if (validUntil != null) 'valid_until': validUntil,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (categoryScope != null) 'category_scope': categoryScope,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DiscountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? type,
      Value<double>? value,
      Value<double>? minOrderAmount,
      Value<bool>? active,
      Value<DateTime?>? validFrom,
      Value<DateTime?>? validUntil,
      Value<String?>? daysOfWeek,
      Value<String?>? startTime,
      Value<String?>? endTime,
      Value<String?>? categoryScope,
      Value<DateTime>? createdAt}) {
    return DiscountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      active: active ?? this.active,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      categoryScope: categoryScope ?? this.categoryScope,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (minOrderAmount.present) {
      map['min_order_amount'] = Variable<double>(minOrderAmount.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<DateTime>(validFrom.value);
    }
    if (validUntil.present) {
      map['valid_until'] = Variable<DateTime>(validUntil.value);
    }
    if (daysOfWeek.present) {
      map['days_of_week'] = Variable<String>(daysOfWeek.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (categoryScope.present) {
      map['category_scope'] = Variable<String>(categoryScope.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiscountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('minOrderAmount: $minOrderAmount, ')
          ..write('active: $active, ')
          ..write('validFrom: $validFrom, ')
          ..write('validUntil: $validUntil, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('categoryScope: $categoryScope, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TablesLayoutTable extends TablesLayout
    with TableInfo<$TablesLayoutTable, TablesLayoutData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TablesLayoutTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _capacityMeta =
      const VerificationMeta('capacity');
  @override
  late final GeneratedColumn<int> capacity = GeneratedColumn<int>(
      'capacity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(4));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('available'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, capacity, status, notes, active];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tables_layout';
  @override
  VerificationContext validateIntegrity(Insertable<TablesLayoutData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('capacity')) {
      context.handle(_capacityMeta,
          capacity.isAcceptableOrUnknown(data['capacity']!, _capacityMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TablesLayoutData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TablesLayoutData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      capacity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}capacity'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
    );
  }

  @override
  $TablesLayoutTable createAlias(String alias) {
    return $TablesLayoutTable(attachedDatabase, alias);
  }
}

class TablesLayoutData extends DataClass
    implements Insertable<TablesLayoutData> {
  final int id;
  final String name;
  final int capacity;
  final String status;
  final String? notes;
  final bool active;
  const TablesLayoutData(
      {required this.id,
      required this.name,
      required this.capacity,
      required this.status,
      this.notes,
      required this.active});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['capacity'] = Variable<int>(capacity);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  TablesLayoutCompanion toCompanion(bool nullToAbsent) {
    return TablesLayoutCompanion(
      id: Value(id),
      name: Value(name),
      capacity: Value(capacity),
      status: Value(status),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      active: Value(active),
    );
  }

  factory TablesLayoutData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TablesLayoutData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      capacity: serializer.fromJson<int>(json['capacity']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'capacity': serializer.toJson<int>(capacity),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'active': serializer.toJson<bool>(active),
    };
  }

  TablesLayoutData copyWith(
          {int? id,
          String? name,
          int? capacity,
          String? status,
          Value<String?> notes = const Value.absent(),
          bool? active}) =>
      TablesLayoutData(
        id: id ?? this.id,
        name: name ?? this.name,
        capacity: capacity ?? this.capacity,
        status: status ?? this.status,
        notes: notes.present ? notes.value : this.notes,
        active: active ?? this.active,
      );
  TablesLayoutData copyWithCompanion(TablesLayoutCompanion data) {
    return TablesLayoutData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      capacity: data.capacity.present ? data.capacity.value : this.capacity,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TablesLayoutData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('capacity: $capacity, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, capacity, status, notes, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TablesLayoutData &&
          other.id == this.id &&
          other.name == this.name &&
          other.capacity == this.capacity &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.active == this.active);
}

class TablesLayoutCompanion extends UpdateCompanion<TablesLayoutData> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> capacity;
  final Value<String> status;
  final Value<String?> notes;
  final Value<bool> active;
  const TablesLayoutCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.capacity = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.active = const Value.absent(),
  });
  TablesLayoutCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.capacity = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.active = const Value.absent(),
  }) : name = Value(name);
  static Insertable<TablesLayoutData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? capacity,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (capacity != null) 'capacity': capacity,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (active != null) 'active': active,
    });
  }

  TablesLayoutCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? capacity,
      Value<String>? status,
      Value<String?>? notes,
      Value<bool>? active}) {
    return TablesLayoutCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (capacity.present) {
      map['capacity'] = Variable<int>(capacity.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TablesLayoutCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('capacity: $capacity, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _visitsMeta = const VerificationMeta('visits');
  @override
  late final GeneratedColumn<int> visits = GeneratedColumn<int>(
      'visits', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalSpentMeta =
      const VerificationMeta('totalSpent');
  @override
  late final GeneratedColumn<double> totalSpent = GeneratedColumn<double>(
      'total_spent', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rfcMeta = const VerificationMeta('rfc');
  @override
  late final GeneratedColumn<String> rfc = GeneratedColumn<String>(
      'rfc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _razonSocialMeta =
      const VerificationMeta('razonSocial');
  @override
  late final GeneratedColumn<String> razonSocial = GeneratedColumn<String>(
      'razon_social', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cpFiscalMeta =
      const VerificationMeta('cpFiscal');
  @override
  late final GeneratedColumn<String> cpFiscal = GeneratedColumn<String>(
      'cp_fiscal', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _regimenFiscalMeta =
      const VerificationMeta('regimenFiscal');
  @override
  late final GeneratedColumn<String> regimenFiscal = GeneratedColumn<String>(
      'regimen_fiscal', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _usoCfdiPreferidoMeta =
      const VerificationMeta('usoCfdiPreferido');
  @override
  late final GeneratedColumn<String> usoCfdiPreferido = GeneratedColumn<String>(
      'uso_cfdi_preferido', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phone,
        email,
        visits,
        totalSpent,
        notes,
        rfc,
        razonSocial,
        cpFiscal,
        regimenFiscal,
        usoCfdiPreferido,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<Customer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('visits')) {
      context.handle(_visitsMeta,
          visits.isAcceptableOrUnknown(data['visits']!, _visitsMeta));
    }
    if (data.containsKey('total_spent')) {
      context.handle(
          _totalSpentMeta,
          totalSpent.isAcceptableOrUnknown(
              data['total_spent']!, _totalSpentMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('rfc')) {
      context.handle(
          _rfcMeta, rfc.isAcceptableOrUnknown(data['rfc']!, _rfcMeta));
    }
    if (data.containsKey('razon_social')) {
      context.handle(
          _razonSocialMeta,
          razonSocial.isAcceptableOrUnknown(
              data['razon_social']!, _razonSocialMeta));
    }
    if (data.containsKey('cp_fiscal')) {
      context.handle(_cpFiscalMeta,
          cpFiscal.isAcceptableOrUnknown(data['cp_fiscal']!, _cpFiscalMeta));
    }
    if (data.containsKey('regimen_fiscal')) {
      context.handle(
          _regimenFiscalMeta,
          regimenFiscal.isAcceptableOrUnknown(
              data['regimen_fiscal']!, _regimenFiscalMeta));
    }
    if (data.containsKey('uso_cfdi_preferido')) {
      context.handle(
          _usoCfdiPreferidoMeta,
          usoCfdiPreferido.isAcceptableOrUnknown(
              data['uso_cfdi_preferido']!, _usoCfdiPreferidoMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      visits: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}visits'])!,
      totalSpent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_spent'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      rfc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rfc']),
      razonSocial: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}razon_social']),
      cpFiscal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cp_fiscal']),
      regimenFiscal: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}regimen_fiscal']),
      usoCfdiPreferido: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}uso_cfdi_preferido']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final int visits;
  final double totalSpent;
  final String? notes;
  final String? rfc;
  final String? razonSocial;
  final String? cpFiscal;
  final String? regimenFiscal;
  final String? usoCfdiPreferido;
  final DateTime createdAt;
  const Customer(
      {required this.id,
      required this.name,
      this.phone,
      this.email,
      required this.visits,
      required this.totalSpent,
      this.notes,
      this.rfc,
      this.razonSocial,
      this.cpFiscal,
      this.regimenFiscal,
      this.usoCfdiPreferido,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['visits'] = Variable<int>(visits);
    map['total_spent'] = Variable<double>(totalSpent);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || rfc != null) {
      map['rfc'] = Variable<String>(rfc);
    }
    if (!nullToAbsent || razonSocial != null) {
      map['razon_social'] = Variable<String>(razonSocial);
    }
    if (!nullToAbsent || cpFiscal != null) {
      map['cp_fiscal'] = Variable<String>(cpFiscal);
    }
    if (!nullToAbsent || regimenFiscal != null) {
      map['regimen_fiscal'] = Variable<String>(regimenFiscal);
    }
    if (!nullToAbsent || usoCfdiPreferido != null) {
      map['uso_cfdi_preferido'] = Variable<String>(usoCfdiPreferido);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      visits: Value(visits),
      totalSpent: Value(totalSpent),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      rfc: rfc == null && nullToAbsent ? const Value.absent() : Value(rfc),
      razonSocial: razonSocial == null && nullToAbsent
          ? const Value.absent()
          : Value(razonSocial),
      cpFiscal: cpFiscal == null && nullToAbsent
          ? const Value.absent()
          : Value(cpFiscal),
      regimenFiscal: regimenFiscal == null && nullToAbsent
          ? const Value.absent()
          : Value(regimenFiscal),
      usoCfdiPreferido: usoCfdiPreferido == null && nullToAbsent
          ? const Value.absent()
          : Value(usoCfdiPreferido),
      createdAt: Value(createdAt),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      email: serializer.fromJson<String?>(json['email']),
      visits: serializer.fromJson<int>(json['visits']),
      totalSpent: serializer.fromJson<double>(json['totalSpent']),
      notes: serializer.fromJson<String?>(json['notes']),
      rfc: serializer.fromJson<String?>(json['rfc']),
      razonSocial: serializer.fromJson<String?>(json['razonSocial']),
      cpFiscal: serializer.fromJson<String?>(json['cpFiscal']),
      regimenFiscal: serializer.fromJson<String?>(json['regimenFiscal']),
      usoCfdiPreferido: serializer.fromJson<String?>(json['usoCfdiPreferido']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'email': serializer.toJson<String?>(email),
      'visits': serializer.toJson<int>(visits),
      'totalSpent': serializer.toJson<double>(totalSpent),
      'notes': serializer.toJson<String?>(notes),
      'rfc': serializer.toJson<String?>(rfc),
      'razonSocial': serializer.toJson<String?>(razonSocial),
      'cpFiscal': serializer.toJson<String?>(cpFiscal),
      'regimenFiscal': serializer.toJson<String?>(regimenFiscal),
      'usoCfdiPreferido': serializer.toJson<String?>(usoCfdiPreferido),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Customer copyWith(
          {int? id,
          String? name,
          Value<String?> phone = const Value.absent(),
          Value<String?> email = const Value.absent(),
          int? visits,
          double? totalSpent,
          Value<String?> notes = const Value.absent(),
          Value<String?> rfc = const Value.absent(),
          Value<String?> razonSocial = const Value.absent(),
          Value<String?> cpFiscal = const Value.absent(),
          Value<String?> regimenFiscal = const Value.absent(),
          Value<String?> usoCfdiPreferido = const Value.absent(),
          DateTime? createdAt}) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        email: email.present ? email.value : this.email,
        visits: visits ?? this.visits,
        totalSpent: totalSpent ?? this.totalSpent,
        notes: notes.present ? notes.value : this.notes,
        rfc: rfc.present ? rfc.value : this.rfc,
        razonSocial: razonSocial.present ? razonSocial.value : this.razonSocial,
        cpFiscal: cpFiscal.present ? cpFiscal.value : this.cpFiscal,
        regimenFiscal:
            regimenFiscal.present ? regimenFiscal.value : this.regimenFiscal,
        usoCfdiPreferido: usoCfdiPreferido.present
            ? usoCfdiPreferido.value
            : this.usoCfdiPreferido,
        createdAt: createdAt ?? this.createdAt,
      );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      visits: data.visits.present ? data.visits.value : this.visits,
      totalSpent:
          data.totalSpent.present ? data.totalSpent.value : this.totalSpent,
      notes: data.notes.present ? data.notes.value : this.notes,
      rfc: data.rfc.present ? data.rfc.value : this.rfc,
      razonSocial:
          data.razonSocial.present ? data.razonSocial.value : this.razonSocial,
      cpFiscal: data.cpFiscal.present ? data.cpFiscal.value : this.cpFiscal,
      regimenFiscal: data.regimenFiscal.present
          ? data.regimenFiscal.value
          : this.regimenFiscal,
      usoCfdiPreferido: data.usoCfdiPreferido.present
          ? data.usoCfdiPreferido.value
          : this.usoCfdiPreferido,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('visits: $visits, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('notes: $notes, ')
          ..write('rfc: $rfc, ')
          ..write('razonSocial: $razonSocial, ')
          ..write('cpFiscal: $cpFiscal, ')
          ..write('regimenFiscal: $regimenFiscal, ')
          ..write('usoCfdiPreferido: $usoCfdiPreferido, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      phone,
      email,
      visits,
      totalSpent,
      notes,
      rfc,
      razonSocial,
      cpFiscal,
      regimenFiscal,
      usoCfdiPreferido,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.visits == this.visits &&
          other.totalSpent == this.totalSpent &&
          other.notes == this.notes &&
          other.rfc == this.rfc &&
          other.razonSocial == this.razonSocial &&
          other.cpFiscal == this.cpFiscal &&
          other.regimenFiscal == this.regimenFiscal &&
          other.usoCfdiPreferido == this.usoCfdiPreferido &&
          other.createdAt == this.createdAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> email;
  final Value<int> visits;
  final Value<double> totalSpent;
  final Value<String?> notes;
  final Value<String?> rfc;
  final Value<String?> razonSocial;
  final Value<String?> cpFiscal;
  final Value<String?> regimenFiscal;
  final Value<String?> usoCfdiPreferido;
  final Value<DateTime> createdAt;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.visits = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.notes = const Value.absent(),
    this.rfc = const Value.absent(),
    this.razonSocial = const Value.absent(),
    this.cpFiscal = const Value.absent(),
    this.regimenFiscal = const Value.absent(),
    this.usoCfdiPreferido = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CustomersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.visits = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.notes = const Value.absent(),
    this.rfc = const Value.absent(),
    this.razonSocial = const Value.absent(),
    this.cpFiscal = const Value.absent(),
    this.regimenFiscal = const Value.absent(),
    this.usoCfdiPreferido = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Customer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<int>? visits,
    Expression<double>? totalSpent,
    Expression<String>? notes,
    Expression<String>? rfc,
    Expression<String>? razonSocial,
    Expression<String>? cpFiscal,
    Expression<String>? regimenFiscal,
    Expression<String>? usoCfdiPreferido,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (visits != null) 'visits': visits,
      if (totalSpent != null) 'total_spent': totalSpent,
      if (notes != null) 'notes': notes,
      if (rfc != null) 'rfc': rfc,
      if (razonSocial != null) 'razon_social': razonSocial,
      if (cpFiscal != null) 'cp_fiscal': cpFiscal,
      if (regimenFiscal != null) 'regimen_fiscal': regimenFiscal,
      if (usoCfdiPreferido != null) 'uso_cfdi_preferido': usoCfdiPreferido,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CustomersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? phone,
      Value<String?>? email,
      Value<int>? visits,
      Value<double>? totalSpent,
      Value<String?>? notes,
      Value<String?>? rfc,
      Value<String?>? razonSocial,
      Value<String?>? cpFiscal,
      Value<String?>? regimenFiscal,
      Value<String?>? usoCfdiPreferido,
      Value<DateTime>? createdAt}) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      visits: visits ?? this.visits,
      totalSpent: totalSpent ?? this.totalSpent,
      notes: notes ?? this.notes,
      rfc: rfc ?? this.rfc,
      razonSocial: razonSocial ?? this.razonSocial,
      cpFiscal: cpFiscal ?? this.cpFiscal,
      regimenFiscal: regimenFiscal ?? this.regimenFiscal,
      usoCfdiPreferido: usoCfdiPreferido ?? this.usoCfdiPreferido,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (visits.present) {
      map['visits'] = Variable<int>(visits.value);
    }
    if (totalSpent.present) {
      map['total_spent'] = Variable<double>(totalSpent.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rfc.present) {
      map['rfc'] = Variable<String>(rfc.value);
    }
    if (razonSocial.present) {
      map['razon_social'] = Variable<String>(razonSocial.value);
    }
    if (cpFiscal.present) {
      map['cp_fiscal'] = Variable<String>(cpFiscal.value);
    }
    if (regimenFiscal.present) {
      map['regimen_fiscal'] = Variable<String>(regimenFiscal.value);
    }
    if (usoCfdiPreferido.present) {
      map['uso_cfdi_preferido'] = Variable<String>(usoCfdiPreferido.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('visits: $visits, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('notes: $notes, ')
          ..write('rfc: $rfc, ')
          ..write('razonSocial: $razonSocial, ')
          ..write('cpFiscal: $cpFiscal, ')
          ..write('regimenFiscal: $regimenFiscal, ')
          ..write('usoCfdiPreferido: $usoCfdiPreferido, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $EmployeesTable extends Employees
    with TableInfo<$EmployeesTable, Employee> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pinMeta = const VerificationMeta('pin');
  @override
  late final GeneratedColumn<String> pin = GeneratedColumn<String>(
      'pin', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, pin, role, active, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees';
  @override
  VerificationContext validateIntegrity(Insertable<Employee> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('pin')) {
      context.handle(
          _pinMeta, pin.isAcceptableOrUnknown(data['pin']!, _pinMeta));
    } else if (isInserting) {
      context.missing(_pinMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Employee map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Employee(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      pin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pin'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EmployeesTable createAlias(String alias) {
    return $EmployeesTable(attachedDatabase, alias);
  }
}

class Employee extends DataClass implements Insertable<Employee> {
  final int id;
  final String name;
  final String pin;
  final String role;
  final bool active;
  final DateTime createdAt;
  const Employee(
      {required this.id,
      required this.name,
      required this.pin,
      required this.role,
      required this.active,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['pin'] = Variable<String>(pin);
    map['role'] = Variable<String>(role);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EmployeesCompanion toCompanion(bool nullToAbsent) {
    return EmployeesCompanion(
      id: Value(id),
      name: Value(name),
      pin: Value(pin),
      role: Value(role),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Employee(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      pin: serializer.fromJson<String>(json['pin']),
      role: serializer.fromJson<String>(json['role']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'pin': serializer.toJson<String>(pin),
      'role': serializer.toJson<String>(role),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Employee copyWith(
          {int? id,
          String? name,
          String? pin,
          String? role,
          bool? active,
          DateTime? createdAt}) =>
      Employee(
        id: id ?? this.id,
        name: name ?? this.name,
        pin: pin ?? this.pin,
        role: role ?? this.role,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
      );
  Employee copyWithCompanion(EmployeesCompanion data) {
    return Employee(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      pin: data.pin.present ? data.pin.value : this.pin,
      role: data.role.present ? data.role.value : this.role,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Employee(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pin: $pin, ')
          ..write('role: $role, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, pin, role, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Employee &&
          other.id == this.id &&
          other.name == this.name &&
          other.pin == this.pin &&
          other.role == this.role &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class EmployeesCompanion extends UpdateCompanion<Employee> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> pin;
  final Value<String> role;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  const EmployeesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.pin = const Value.absent(),
    this.role = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EmployeesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String pin,
    required String role,
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        pin = Value(pin),
        role = Value(role);
  static Insertable<Employee> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? pin,
    Expression<String>? role,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (pin != null) 'pin': pin,
      if (role != null) 'role': role,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EmployeesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? pin,
      Value<String>? role,
      Value<bool>? active,
      Value<DateTime>? createdAt}) {
    return EmployeesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (pin.present) {
      map['pin'] = Variable<String>(pin.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('pin: $pin, ')
          ..write('role: $role, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ShiftsTable extends Shifts with TableInfo<$ShiftsTable, Shift> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _startingCashMeta =
      const VerificationMeta('startingCash');
  @override
  late final GeneratedColumn<double> startingCash = GeneratedColumn<double>(
      'starting_cash', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _endingCashMeta =
      const VerificationMeta('endingCash');
  @override
  late final GeneratedColumn<double> endingCash = GeneratedColumn<double>(
      'ending_cash', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalSalesMeta =
      const VerificationMeta('totalSales');
  @override
  late final GeneratedColumn<double> totalSales = GeneratedColumn<double>(
      'total_sales', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _zNumberMeta =
      const VerificationMeta('zNumber');
  @override
  late final GeneratedColumn<int> zNumber = GeneratedColumn<int>(
      'z_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        employeeId,
        startedAt,
        endedAt,
        startingCash,
        endingCash,
        totalSales,
        notes,
        zNumber,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(Insertable<Shift> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('starting_cash')) {
      context.handle(
          _startingCashMeta,
          startingCash.isAcceptableOrUnknown(
              data['starting_cash']!, _startingCashMeta));
    }
    if (data.containsKey('ending_cash')) {
      context.handle(
          _endingCashMeta,
          endingCash.isAcceptableOrUnknown(
              data['ending_cash']!, _endingCashMeta));
    }
    if (data.containsKey('total_sales')) {
      context.handle(
          _totalSalesMeta,
          totalSales.isAcceptableOrUnknown(
              data['total_sales']!, _totalSalesMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('z_number')) {
      context.handle(_zNumberMeta,
          zNumber.isAcceptableOrUnknown(data['z_number']!, _zNumberMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shift map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shift(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      startingCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}starting_cash'])!,
      endingCash: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ending_cash']),
      totalSales: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_sales'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      zNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}z_number']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $ShiftsTable createAlias(String alias) {
    return $ShiftsTable(attachedDatabase, alias);
  }
}

class Shift extends DataClass implements Insertable<Shift> {
  final int id;
  final int employeeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double startingCash;
  final double? endingCash;
  final double totalSales;
  final String? notes;
  final int? zNumber;
  final DateTime? deletedAt;
  const Shift(
      {required this.id,
      required this.employeeId,
      required this.startedAt,
      this.endedAt,
      required this.startingCash,
      this.endingCash,
      required this.totalSales,
      this.notes,
      this.zNumber,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['employee_id'] = Variable<int>(employeeId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['starting_cash'] = Variable<double>(startingCash);
    if (!nullToAbsent || endingCash != null) {
      map['ending_cash'] = Variable<double>(endingCash);
    }
    map['total_sales'] = Variable<double>(totalSales);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || zNumber != null) {
      map['z_number'] = Variable<int>(zNumber);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ShiftsCompanion toCompanion(bool nullToAbsent) {
    return ShiftsCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      startingCash: Value(startingCash),
      endingCash: endingCash == null && nullToAbsent
          ? const Value.absent()
          : Value(endingCash),
      totalSales: Value(totalSales),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      zNumber: zNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(zNumber),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Shift.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shift(
      id: serializer.fromJson<int>(json['id']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      startingCash: serializer.fromJson<double>(json['startingCash']),
      endingCash: serializer.fromJson<double?>(json['endingCash']),
      totalSales: serializer.fromJson<double>(json['totalSales']),
      notes: serializer.fromJson<String?>(json['notes']),
      zNumber: serializer.fromJson<int?>(json['zNumber']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employeeId': serializer.toJson<int>(employeeId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'startingCash': serializer.toJson<double>(startingCash),
      'endingCash': serializer.toJson<double?>(endingCash),
      'totalSales': serializer.toJson<double>(totalSales),
      'notes': serializer.toJson<String?>(notes),
      'zNumber': serializer.toJson<int?>(zNumber),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Shift copyWith(
          {int? id,
          int? employeeId,
          DateTime? startedAt,
          Value<DateTime?> endedAt = const Value.absent(),
          double? startingCash,
          Value<double?> endingCash = const Value.absent(),
          double? totalSales,
          Value<String?> notes = const Value.absent(),
          Value<int?> zNumber = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Shift(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        startingCash: startingCash ?? this.startingCash,
        endingCash: endingCash.present ? endingCash.value : this.endingCash,
        totalSales: totalSales ?? this.totalSales,
        notes: notes.present ? notes.value : this.notes,
        zNumber: zNumber.present ? zNumber.value : this.zNumber,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Shift copyWithCompanion(ShiftsCompanion data) {
    return Shift(
      id: data.id.present ? data.id.value : this.id,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      startingCash: data.startingCash.present
          ? data.startingCash.value
          : this.startingCash,
      endingCash:
          data.endingCash.present ? data.endingCash.value : this.endingCash,
      totalSales:
          data.totalSales.present ? data.totalSales.value : this.totalSales,
      notes: data.notes.present ? data.notes.value : this.notes,
      zNumber: data.zNumber.present ? data.zNumber.value : this.zNumber,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shift(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('startingCash: $startingCash, ')
          ..write('endingCash: $endingCash, ')
          ..write('totalSales: $totalSales, ')
          ..write('notes: $notes, ')
          ..write('zNumber: $zNumber, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, employeeId, startedAt, endedAt,
      startingCash, endingCash, totalSales, notes, zNumber, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shift &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.startingCash == this.startingCash &&
          other.endingCash == this.endingCash &&
          other.totalSales == this.totalSales &&
          other.notes == this.notes &&
          other.zNumber == this.zNumber &&
          other.deletedAt == this.deletedAt);
}

class ShiftsCompanion extends UpdateCompanion<Shift> {
  final Value<int> id;
  final Value<int> employeeId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double> startingCash;
  final Value<double?> endingCash;
  final Value<double> totalSales;
  final Value<String?> notes;
  final Value<int?> zNumber;
  final Value<DateTime?> deletedAt;
  const ShiftsCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.startingCash = const Value.absent(),
    this.endingCash = const Value.absent(),
    this.totalSales = const Value.absent(),
    this.notes = const Value.absent(),
    this.zNumber = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  ShiftsCompanion.insert({
    this.id = const Value.absent(),
    required int employeeId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.startingCash = const Value.absent(),
    this.endingCash = const Value.absent(),
    this.totalSales = const Value.absent(),
    this.notes = const Value.absent(),
    this.zNumber = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : employeeId = Value(employeeId),
        startedAt = Value(startedAt);
  static Insertable<Shift> custom({
    Expression<int>? id,
    Expression<int>? employeeId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? startingCash,
    Expression<double>? endingCash,
    Expression<double>? totalSales,
    Expression<String>? notes,
    Expression<int>? zNumber,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (startingCash != null) 'starting_cash': startingCash,
      if (endingCash != null) 'ending_cash': endingCash,
      if (totalSales != null) 'total_sales': totalSales,
      if (notes != null) 'notes': notes,
      if (zNumber != null) 'z_number': zNumber,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  ShiftsCompanion copyWith(
      {Value<int>? id,
      Value<int>? employeeId,
      Value<DateTime>? startedAt,
      Value<DateTime?>? endedAt,
      Value<double>? startingCash,
      Value<double?>? endingCash,
      Value<double>? totalSales,
      Value<String?>? notes,
      Value<int?>? zNumber,
      Value<DateTime?>? deletedAt}) {
    return ShiftsCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      startingCash: startingCash ?? this.startingCash,
      endingCash: endingCash ?? this.endingCash,
      totalSales: totalSales ?? this.totalSales,
      notes: notes ?? this.notes,
      zNumber: zNumber ?? this.zNumber,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (startingCash.present) {
      map['starting_cash'] = Variable<double>(startingCash.value);
    }
    if (endingCash.present) {
      map['ending_cash'] = Variable<double>(endingCash.value);
    }
    if (totalSales.present) {
      map['total_sales'] = Variable<double>(totalSales.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (zNumber.present) {
      map['z_number'] = Variable<int>(zNumber.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftsCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('startingCash: $startingCash, ')
          ..write('endingCash: $endingCash, ')
          ..write('totalSales: $totalSales, ')
          ..write('notes: $notes, ')
          ..write('zNumber: $zNumber, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, Order> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _orderNumberMeta =
      const VerificationMeta('orderNumber');
  @override
  late final GeneratedColumn<String> orderNumber = GeneratedColumn<String>(
      'order_number', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tableIdMeta =
      const VerificationMeta('tableId');
  @override
  late final GeneratedColumn<int> tableId = GeneratedColumn<int>(
      'table_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tables_layout (id)'));
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<int> customerId = GeneratedColumn<int>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES customers (id)'));
  static const VerificationMeta _customerPhoneMeta =
      const VerificationMeta('customerPhone');
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
      'customer_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerAddressMeta =
      const VerificationMeta('customerAddress');
  @override
  late final GeneratedColumn<String> customerAddress = GeneratedColumn<String>(
      'customer_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _shiftIdMeta =
      const VerificationMeta('shiftId');
  @override
  late final GeneratedColumn<int> shiftId = GeneratedColumn<int>(
      'shift_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES shifts (id)'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendiente'));
  static const VerificationMeta _paymentStatusMeta =
      const VerificationMeta('paymentStatus');
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
      'payment_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendiente'));
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountAmountMeta =
      const VerificationMeta('discountAmount');
  @override
  late final GeneratedColumn<double> discountAmount = GeneratedColumn<double>(
      'discount_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _taxAmountMeta =
      const VerificationMeta('taxAmount');
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
      'tax_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _deliveryZoneMeta =
      const VerificationMeta('deliveryZone');
  @override
  late final GeneratedColumn<String> deliveryZone = GeneratedColumn<String>(
      'delivery_zone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deliveryFeeMeta =
      const VerificationMeta('deliveryFee');
  @override
  late final GeneratedColumn<double> deliveryFee = GeneratedColumn<double>(
      'delivery_fee', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _deliveryPaymentMethodMeta =
      const VerificationMeta('deliveryPaymentMethod');
  @override
  late final GeneratedColumn<String> deliveryPaymentMethod =
      GeneratedColumn<String>('delivery_payment_method', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deliveryCashAmountMeta =
      const VerificationMeta('deliveryCashAmount');
  @override
  late final GeneratedColumn<double> deliveryCashAmount =
      GeneratedColumn<double>('delivery_cash_amount', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _cancelReasonMeta =
      const VerificationMeta('cancelReason');
  @override
  late final GeneratedColumn<String> cancelReason = GeneratedColumn<String>(
      'cancel_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderNumber,
        type,
        tableId,
        customerName,
        customerId,
        customerPhone,
        customerAddress,
        employeeId,
        shiftId,
        note,
        status,
        paymentStatus,
        subtotal,
        discountAmount,
        taxAmount,
        total,
        deliveryZone,
        deliveryFee,
        deliveryPaymentMethod,
        deliveryCashAmount,
        cancelReason,
        createdAt,
        updatedAt,
        completedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(Insertable<Order> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_number')) {
      context.handle(
          _orderNumberMeta,
          orderNumber.isAcceptableOrUnknown(
              data['order_number']!, _orderNumberMeta));
    } else if (isInserting) {
      context.missing(_orderNumberMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('table_id')) {
      context.handle(_tableIdMeta,
          tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta));
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
          _customerPhoneMeta,
          customerPhone.isAcceptableOrUnknown(
              data['customer_phone']!, _customerPhoneMeta));
    }
    if (data.containsKey('customer_address')) {
      context.handle(
          _customerAddressMeta,
          customerAddress.isAcceptableOrUnknown(
              data['customer_address']!, _customerAddressMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(_shiftIdMeta,
          shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('payment_status')) {
      context.handle(
          _paymentStatusMeta,
          paymentStatus.isAcceptableOrUnknown(
              data['payment_status']!, _paymentStatusMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    }
    if (data.containsKey('discount_amount')) {
      context.handle(
          _discountAmountMeta,
          discountAmount.isAcceptableOrUnknown(
              data['discount_amount']!, _discountAmountMeta));
    }
    if (data.containsKey('tax_amount')) {
      context.handle(_taxAmountMeta,
          taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta));
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    }
    if (data.containsKey('delivery_zone')) {
      context.handle(
          _deliveryZoneMeta,
          deliveryZone.isAcceptableOrUnknown(
              data['delivery_zone']!, _deliveryZoneMeta));
    }
    if (data.containsKey('delivery_fee')) {
      context.handle(
          _deliveryFeeMeta,
          deliveryFee.isAcceptableOrUnknown(
              data['delivery_fee']!, _deliveryFeeMeta));
    }
    if (data.containsKey('delivery_payment_method')) {
      context.handle(
          _deliveryPaymentMethodMeta,
          deliveryPaymentMethod.isAcceptableOrUnknown(
              data['delivery_payment_method']!, _deliveryPaymentMethodMeta));
    }
    if (data.containsKey('delivery_cash_amount')) {
      context.handle(
          _deliveryCashAmountMeta,
          deliveryCashAmount.isAcceptableOrUnknown(
              data['delivery_cash_amount']!, _deliveryCashAmountMeta));
    }
    if (data.containsKey('cancel_reason')) {
      context.handle(
          _cancelReasonMeta,
          cancelReason.isAcceptableOrUnknown(
              data['cancel_reason']!, _cancelReasonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Order(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      orderNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_number'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      tableId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}table_id']),
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name']),
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}customer_id']),
      customerPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_phone']),
      customerAddress: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}customer_address']),
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id'])!,
      shiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shift_id']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      paymentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_status'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      discountAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}discount_amount'])!,
      taxAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax_amount'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
      deliveryZone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}delivery_zone']),
      deliveryFee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}delivery_fee'])!,
      deliveryPaymentMethod: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}delivery_payment_method']),
      deliveryCashAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}delivery_cash_amount']),
      cancelReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cancel_reason']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class Order extends DataClass implements Insertable<Order> {
  final int id;
  final String orderNumber;
  final String type;
  final int? tableId;
  final String? customerName;
  final int? customerId;
  final String? customerPhone;
  final String? customerAddress;
  final int employeeId;
  final int? shiftId;
  final String? note;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final String? deliveryZone;
  final double deliveryFee;
  final String? deliveryPaymentMethod;
  final double? deliveryCashAmount;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  const Order(
      {required this.id,
      required this.orderNumber,
      required this.type,
      this.tableId,
      this.customerName,
      this.customerId,
      this.customerPhone,
      this.customerAddress,
      required this.employeeId,
      this.shiftId,
      this.note,
      required this.status,
      required this.paymentStatus,
      required this.subtotal,
      required this.discountAmount,
      required this.taxAmount,
      required this.total,
      this.deliveryZone,
      required this.deliveryFee,
      this.deliveryPaymentMethod,
      this.deliveryCashAmount,
      this.cancelReason,
      required this.createdAt,
      required this.updatedAt,
      this.completedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_number'] = Variable<String>(orderNumber);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || tableId != null) {
      map['table_id'] = Variable<int>(tableId);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<int>(customerId);
    }
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    if (!nullToAbsent || customerAddress != null) {
      map['customer_address'] = Variable<String>(customerAddress);
    }
    map['employee_id'] = Variable<int>(employeeId);
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<int>(shiftId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['status'] = Variable<String>(status);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['subtotal'] = Variable<double>(subtotal);
    map['discount_amount'] = Variable<double>(discountAmount);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['total'] = Variable<double>(total);
    if (!nullToAbsent || deliveryZone != null) {
      map['delivery_zone'] = Variable<String>(deliveryZone);
    }
    map['delivery_fee'] = Variable<double>(deliveryFee);
    if (!nullToAbsent || deliveryPaymentMethod != null) {
      map['delivery_payment_method'] = Variable<String>(deliveryPaymentMethod);
    }
    if (!nullToAbsent || deliveryCashAmount != null) {
      map['delivery_cash_amount'] = Variable<double>(deliveryCashAmount);
    }
    if (!nullToAbsent || cancelReason != null) {
      map['cancel_reason'] = Variable<String>(cancelReason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      orderNumber: Value(orderNumber),
      type: Value(type),
      tableId: tableId == null && nullToAbsent
          ? const Value.absent()
          : Value(tableId),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      customerAddress: customerAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(customerAddress),
      employeeId: Value(employeeId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      status: Value(status),
      paymentStatus: Value(paymentStatus),
      subtotal: Value(subtotal),
      discountAmount: Value(discountAmount),
      taxAmount: Value(taxAmount),
      total: Value(total),
      deliveryZone: deliveryZone == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryZone),
      deliveryFee: Value(deliveryFee),
      deliveryPaymentMethod: deliveryPaymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryPaymentMethod),
      deliveryCashAmount: deliveryCashAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryCashAmount),
      cancelReason: cancelReason == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelReason),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Order.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Order(
      id: serializer.fromJson<int>(json['id']),
      orderNumber: serializer.fromJson<String>(json['orderNumber']),
      type: serializer.fromJson<String>(json['type']),
      tableId: serializer.fromJson<int?>(json['tableId']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerId: serializer.fromJson<int?>(json['customerId']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      customerAddress: serializer.fromJson<String?>(json['customerAddress']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      shiftId: serializer.fromJson<int?>(json['shiftId']),
      note: serializer.fromJson<String?>(json['note']),
      status: serializer.fromJson<String>(json['status']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discountAmount: serializer.fromJson<double>(json['discountAmount']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      total: serializer.fromJson<double>(json['total']),
      deliveryZone: serializer.fromJson<String?>(json['deliveryZone']),
      deliveryFee: serializer.fromJson<double>(json['deliveryFee']),
      deliveryPaymentMethod:
          serializer.fromJson<String?>(json['deliveryPaymentMethod']),
      deliveryCashAmount:
          serializer.fromJson<double?>(json['deliveryCashAmount']),
      cancelReason: serializer.fromJson<String?>(json['cancelReason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderNumber': serializer.toJson<String>(orderNumber),
      'type': serializer.toJson<String>(type),
      'tableId': serializer.toJson<int?>(tableId),
      'customerName': serializer.toJson<String?>(customerName),
      'customerId': serializer.toJson<int?>(customerId),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'customerAddress': serializer.toJson<String?>(customerAddress),
      'employeeId': serializer.toJson<int>(employeeId),
      'shiftId': serializer.toJson<int?>(shiftId),
      'note': serializer.toJson<String?>(note),
      'status': serializer.toJson<String>(status),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'subtotal': serializer.toJson<double>(subtotal),
      'discountAmount': serializer.toJson<double>(discountAmount),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'total': serializer.toJson<double>(total),
      'deliveryZone': serializer.toJson<String?>(deliveryZone),
      'deliveryFee': serializer.toJson<double>(deliveryFee),
      'deliveryPaymentMethod':
          serializer.toJson<String?>(deliveryPaymentMethod),
      'deliveryCashAmount': serializer.toJson<double?>(deliveryCashAmount),
      'cancelReason': serializer.toJson<String?>(cancelReason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Order copyWith(
          {int? id,
          String? orderNumber,
          String? type,
          Value<int?> tableId = const Value.absent(),
          Value<String?> customerName = const Value.absent(),
          Value<int?> customerId = const Value.absent(),
          Value<String?> customerPhone = const Value.absent(),
          Value<String?> customerAddress = const Value.absent(),
          int? employeeId,
          Value<int?> shiftId = const Value.absent(),
          Value<String?> note = const Value.absent(),
          String? status,
          String? paymentStatus,
          double? subtotal,
          double? discountAmount,
          double? taxAmount,
          double? total,
          Value<String?> deliveryZone = const Value.absent(),
          double? deliveryFee,
          Value<String?> deliveryPaymentMethod = const Value.absent(),
          Value<double?> deliveryCashAmount = const Value.absent(),
          Value<String?> cancelReason = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> completedAt = const Value.absent(),
          Value<DateTime?> deletedAt = const Value.absent()}) =>
      Order(
        id: id ?? this.id,
        orderNumber: orderNumber ?? this.orderNumber,
        type: type ?? this.type,
        tableId: tableId.present ? tableId.value : this.tableId,
        customerName:
            customerName.present ? customerName.value : this.customerName,
        customerId: customerId.present ? customerId.value : this.customerId,
        customerPhone:
            customerPhone.present ? customerPhone.value : this.customerPhone,
        customerAddress: customerAddress.present
            ? customerAddress.value
            : this.customerAddress,
        employeeId: employeeId ?? this.employeeId,
        shiftId: shiftId.present ? shiftId.value : this.shiftId,
        note: note.present ? note.value : this.note,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        subtotal: subtotal ?? this.subtotal,
        discountAmount: discountAmount ?? this.discountAmount,
        taxAmount: taxAmount ?? this.taxAmount,
        total: total ?? this.total,
        deliveryZone:
            deliveryZone.present ? deliveryZone.value : this.deliveryZone,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        deliveryPaymentMethod: deliveryPaymentMethod.present
            ? deliveryPaymentMethod.value
            : this.deliveryPaymentMethod,
        deliveryCashAmount: deliveryCashAmount.present
            ? deliveryCashAmount.value
            : this.deliveryCashAmount,
        cancelReason:
            cancelReason.present ? cancelReason.value : this.cancelReason,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Order copyWithCompanion(OrdersCompanion data) {
    return Order(
      id: data.id.present ? data.id.value : this.id,
      orderNumber:
          data.orderNumber.present ? data.orderNumber.value : this.orderNumber,
      type: data.type.present ? data.type.value : this.type,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      customerAddress: data.customerAddress.present
          ? data.customerAddress.value
          : this.customerAddress,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discountAmount: data.discountAmount.present
          ? data.discountAmount.value
          : this.discountAmount,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      total: data.total.present ? data.total.value : this.total,
      deliveryZone: data.deliveryZone.present
          ? data.deliveryZone.value
          : this.deliveryZone,
      deliveryFee:
          data.deliveryFee.present ? data.deliveryFee.value : this.deliveryFee,
      deliveryPaymentMethod: data.deliveryPaymentMethod.present
          ? data.deliveryPaymentMethod.value
          : this.deliveryPaymentMethod,
      deliveryCashAmount: data.deliveryCashAmount.present
          ? data.deliveryCashAmount.value
          : this.deliveryCashAmount,
      cancelReason: data.cancelReason.present
          ? data.cancelReason.value
          : this.cancelReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Order(')
          ..write('id: $id, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('type: $type, ')
          ..write('tableId: $tableId, ')
          ..write('customerName: $customerName, ')
          ..write('customerId: $customerId, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('employeeId: $employeeId, ')
          ..write('shiftId: $shiftId, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('total: $total, ')
          ..write('deliveryZone: $deliveryZone, ')
          ..write('deliveryFee: $deliveryFee, ')
          ..write('deliveryPaymentMethod: $deliveryPaymentMethod, ')
          ..write('deliveryCashAmount: $deliveryCashAmount, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        orderNumber,
        type,
        tableId,
        customerName,
        customerId,
        customerPhone,
        customerAddress,
        employeeId,
        shiftId,
        note,
        status,
        paymentStatus,
        subtotal,
        discountAmount,
        taxAmount,
        total,
        deliveryZone,
        deliveryFee,
        deliveryPaymentMethod,
        deliveryCashAmount,
        cancelReason,
        createdAt,
        updatedAt,
        completedAt,
        deletedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Order &&
          other.id == this.id &&
          other.orderNumber == this.orderNumber &&
          other.type == this.type &&
          other.tableId == this.tableId &&
          other.customerName == this.customerName &&
          other.customerId == this.customerId &&
          other.customerPhone == this.customerPhone &&
          other.customerAddress == this.customerAddress &&
          other.employeeId == this.employeeId &&
          other.shiftId == this.shiftId &&
          other.note == this.note &&
          other.status == this.status &&
          other.paymentStatus == this.paymentStatus &&
          other.subtotal == this.subtotal &&
          other.discountAmount == this.discountAmount &&
          other.taxAmount == this.taxAmount &&
          other.total == this.total &&
          other.deliveryZone == this.deliveryZone &&
          other.deliveryFee == this.deliveryFee &&
          other.deliveryPaymentMethod == this.deliveryPaymentMethod &&
          other.deliveryCashAmount == this.deliveryCashAmount &&
          other.cancelReason == this.cancelReason &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.deletedAt == this.deletedAt);
}

class OrdersCompanion extends UpdateCompanion<Order> {
  final Value<int> id;
  final Value<String> orderNumber;
  final Value<String> type;
  final Value<int?> tableId;
  final Value<String?> customerName;
  final Value<int?> customerId;
  final Value<String?> customerPhone;
  final Value<String?> customerAddress;
  final Value<int> employeeId;
  final Value<int?> shiftId;
  final Value<String?> note;
  final Value<String> status;
  final Value<String> paymentStatus;
  final Value<double> subtotal;
  final Value<double> discountAmount;
  final Value<double> taxAmount;
  final Value<double> total;
  final Value<String?> deliveryZone;
  final Value<double> deliveryFee;
  final Value<String?> deliveryPaymentMethod;
  final Value<double?> deliveryCashAmount;
  final Value<String?> cancelReason;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> deletedAt;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.orderNumber = const Value.absent(),
    this.type = const Value.absent(),
    this.tableId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.total = const Value.absent(),
    this.deliveryZone = const Value.absent(),
    this.deliveryFee = const Value.absent(),
    this.deliveryPaymentMethod = const Value.absent(),
    this.deliveryCashAmount = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  OrdersCompanion.insert({
    this.id = const Value.absent(),
    required String orderNumber,
    required String type,
    this.tableId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.customerAddress = const Value.absent(),
    required int employeeId,
    this.shiftId = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.total = const Value.absent(),
    this.deliveryZone = const Value.absent(),
    this.deliveryFee = const Value.absent(),
    this.deliveryPaymentMethod = const Value.absent(),
    this.deliveryCashAmount = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  })  : orderNumber = Value(orderNumber),
        type = Value(type),
        employeeId = Value(employeeId);
  static Insertable<Order> custom({
    Expression<int>? id,
    Expression<String>? orderNumber,
    Expression<String>? type,
    Expression<int>? tableId,
    Expression<String>? customerName,
    Expression<int>? customerId,
    Expression<String>? customerPhone,
    Expression<String>? customerAddress,
    Expression<int>? employeeId,
    Expression<int>? shiftId,
    Expression<String>? note,
    Expression<String>? status,
    Expression<String>? paymentStatus,
    Expression<double>? subtotal,
    Expression<double>? discountAmount,
    Expression<double>? taxAmount,
    Expression<double>? total,
    Expression<String>? deliveryZone,
    Expression<double>? deliveryFee,
    Expression<String>? deliveryPaymentMethod,
    Expression<double>? deliveryCashAmount,
    Expression<String>? cancelReason,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderNumber != null) 'order_number': orderNumber,
      if (type != null) 'type': type,
      if (tableId != null) 'table_id': tableId,
      if (customerName != null) 'customer_name': customerName,
      if (customerId != null) 'customer_id': customerId,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (employeeId != null) 'employee_id': employeeId,
      if (shiftId != null) 'shift_id': shiftId,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (subtotal != null) 'subtotal': subtotal,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (total != null) 'total': total,
      if (deliveryZone != null) 'delivery_zone': deliveryZone,
      if (deliveryFee != null) 'delivery_fee': deliveryFee,
      if (deliveryPaymentMethod != null)
        'delivery_payment_method': deliveryPaymentMethod,
      if (deliveryCashAmount != null)
        'delivery_cash_amount': deliveryCashAmount,
      if (cancelReason != null) 'cancel_reason': cancelReason,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  OrdersCompanion copyWith(
      {Value<int>? id,
      Value<String>? orderNumber,
      Value<String>? type,
      Value<int?>? tableId,
      Value<String?>? customerName,
      Value<int?>? customerId,
      Value<String?>? customerPhone,
      Value<String?>? customerAddress,
      Value<int>? employeeId,
      Value<int?>? shiftId,
      Value<String?>? note,
      Value<String>? status,
      Value<String>? paymentStatus,
      Value<double>? subtotal,
      Value<double>? discountAmount,
      Value<double>? taxAmount,
      Value<double>? total,
      Value<String?>? deliveryZone,
      Value<double>? deliveryFee,
      Value<String?>? deliveryPaymentMethod,
      Value<double?>? deliveryCashAmount,
      Value<String?>? cancelReason,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? completedAt,
      Value<DateTime?>? deletedAt}) {
    return OrdersCompanion(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      type: type ?? this.type,
      tableId: tableId ?? this.tableId,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      employeeId: employeeId ?? this.employeeId,
      shiftId: shiftId ?? this.shiftId,
      note: note ?? this.note,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      deliveryZone: deliveryZone ?? this.deliveryZone,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryPaymentMethod:
          deliveryPaymentMethod ?? this.deliveryPaymentMethod,
      deliveryCashAmount: deliveryCashAmount ?? this.deliveryCashAmount,
      cancelReason: cancelReason ?? this.cancelReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderNumber.present) {
      map['order_number'] = Variable<String>(orderNumber.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<int>(tableId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<int>(customerId.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (customerAddress.present) {
      map['customer_address'] = Variable<String>(customerAddress.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<int>(shiftId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discountAmount.present) {
      map['discount_amount'] = Variable<double>(discountAmount.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (deliveryZone.present) {
      map['delivery_zone'] = Variable<String>(deliveryZone.value);
    }
    if (deliveryFee.present) {
      map['delivery_fee'] = Variable<double>(deliveryFee.value);
    }
    if (deliveryPaymentMethod.present) {
      map['delivery_payment_method'] =
          Variable<String>(deliveryPaymentMethod.value);
    }
    if (deliveryCashAmount.present) {
      map['delivery_cash_amount'] = Variable<double>(deliveryCashAmount.value);
    }
    if (cancelReason.present) {
      map['cancel_reason'] = Variable<String>(cancelReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('type: $type, ')
          ..write('tableId: $tableId, ')
          ..write('customerName: $customerName, ')
          ..write('customerId: $customerId, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('employeeId: $employeeId, ')
          ..write('shiftId: $shiftId, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountAmount: $discountAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('total: $total, ')
          ..write('deliveryZone: $deliveryZone, ')
          ..write('deliveryFee: $deliveryFee, ')
          ..write('deliveryPaymentMethod: $deliveryPaymentMethod, ')
          ..write('deliveryCashAmount: $deliveryCashAmount, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class $OrderItemsTable extends OrderItems
    with TableInfo<$OrderItemsTable, OrderItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
      'order_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orders (id)'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceMeta =
      const VerificationMeta('unitPrice');
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
      'unit_price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _modifiersJsonMeta =
      const VerificationMeta('modifiersJson');
  @override
  late final GeneratedColumn<String> modifiersJson = GeneratedColumn<String>(
      'modifiers_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _itemNoteMeta =
      const VerificationMeta('itemNote');
  @override
  late final GeneratedColumn<String> itemNote = GeneratedColumn<String>(
      'item_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _itemStatusMeta =
      const VerificationMeta('itemStatus');
  @override
  late final GeneratedColumn<String> itemStatus = GeneratedColumn<String>(
      'item_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendiente'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        productId,
        productName,
        quantity,
        unitPrice,
        modifiersJson,
        itemNote,
        itemStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_items';
  @override
  VerificationContext validateIntegrity(Insertable<OrderItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(_unitPriceMeta,
          unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta));
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('modifiers_json')) {
      context.handle(
          _modifiersJsonMeta,
          modifiersJson.isAcceptableOrUnknown(
              data['modifiers_json']!, _modifiersJsonMeta));
    }
    if (data.containsKey('item_note')) {
      context.handle(_itemNoteMeta,
          itemNote.isAcceptableOrUnknown(data['item_note']!, _itemNoteMeta));
    }
    if (data.containsKey('item_status')) {
      context.handle(
          _itemStatusMeta,
          itemStatus.isAcceptableOrUnknown(
              data['item_status']!, _itemStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      unitPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_price'])!,
      modifiersJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}modifiers_json']),
      itemNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_note']),
      itemStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_status'])!,
    );
  }

  @override
  $OrderItemsTable createAlias(String alias) {
    return $OrderItemsTable(attachedDatabase, alias);
  }
}

class OrderItem extends DataClass implements Insertable<OrderItem> {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? modifiersJson;
  final String? itemNote;
  final String itemStatus;
  const OrderItem(
      {required this.id,
      required this.orderId,
      required this.productId,
      required this.productName,
      required this.quantity,
      required this.unitPrice,
      this.modifiersJson,
      this.itemNote,
      required this.itemStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_id'] = Variable<int>(orderId);
    map['product_id'] = Variable<int>(productId);
    map['product_name'] = Variable<String>(productName);
    map['quantity'] = Variable<int>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    if (!nullToAbsent || modifiersJson != null) {
      map['modifiers_json'] = Variable<String>(modifiersJson);
    }
    if (!nullToAbsent || itemNote != null) {
      map['item_note'] = Variable<String>(itemNote);
    }
    map['item_status'] = Variable<String>(itemStatus);
    return map;
  }

  OrderItemsCompanion toCompanion(bool nullToAbsent) {
    return OrderItemsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      productId: Value(productId),
      productName: Value(productName),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      modifiersJson: modifiersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiersJson),
      itemNote: itemNote == null && nullToAbsent
          ? const Value.absent()
          : Value(itemNote),
      itemStatus: Value(itemStatus),
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderItem(
      id: serializer.fromJson<int>(json['id']),
      orderId: serializer.fromJson<int>(json['orderId']),
      productId: serializer.fromJson<int>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      modifiersJson: serializer.fromJson<String?>(json['modifiersJson']),
      itemNote: serializer.fromJson<String?>(json['itemNote']),
      itemStatus: serializer.fromJson<String>(json['itemStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderId': serializer.toJson<int>(orderId),
      'productId': serializer.toJson<int>(productId),
      'productName': serializer.toJson<String>(productName),
      'quantity': serializer.toJson<int>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'modifiersJson': serializer.toJson<String?>(modifiersJson),
      'itemNote': serializer.toJson<String?>(itemNote),
      'itemStatus': serializer.toJson<String>(itemStatus),
    };
  }

  OrderItem copyWith(
          {int? id,
          int? orderId,
          int? productId,
          String? productName,
          int? quantity,
          double? unitPrice,
          Value<String?> modifiersJson = const Value.absent(),
          Value<String?> itemNote = const Value.absent(),
          String? itemStatus}) =>
      OrderItem(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        modifiersJson:
            modifiersJson.present ? modifiersJson.value : this.modifiersJson,
        itemNote: itemNote.present ? itemNote.value : this.itemNote,
        itemStatus: itemStatus ?? this.itemStatus,
      );
  OrderItem copyWithCompanion(OrderItemsCompanion data) {
    return OrderItem(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      modifiersJson: data.modifiersJson.present
          ? data.modifiersJson.value
          : this.modifiersJson,
      itemNote: data.itemNote.present ? data.itemNote.value : this.itemNote,
      itemStatus:
          data.itemStatus.present ? data.itemStatus.value : this.itemStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderItem(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('modifiersJson: $modifiersJson, ')
          ..write('itemNote: $itemNote, ')
          ..write('itemStatus: $itemStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, orderId, productId, productName, quantity,
      unitPrice, modifiersJson, itemNote, itemStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItem &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.modifiersJson == this.modifiersJson &&
          other.itemNote == this.itemNote &&
          other.itemStatus == this.itemStatus);
}

class OrderItemsCompanion extends UpdateCompanion<OrderItem> {
  final Value<int> id;
  final Value<int> orderId;
  final Value<int> productId;
  final Value<String> productName;
  final Value<int> quantity;
  final Value<double> unitPrice;
  final Value<String?> modifiersJson;
  final Value<String?> itemNote;
  final Value<String> itemStatus;
  const OrderItemsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.modifiersJson = const Value.absent(),
    this.itemNote = const Value.absent(),
    this.itemStatus = const Value.absent(),
  });
  OrderItemsCompanion.insert({
    this.id = const Value.absent(),
    required int orderId,
    required int productId,
    required String productName,
    required int quantity,
    required double unitPrice,
    this.modifiersJson = const Value.absent(),
    this.itemNote = const Value.absent(),
    this.itemStatus = const Value.absent(),
  })  : orderId = Value(orderId),
        productId = Value(productId),
        productName = Value(productName),
        quantity = Value(quantity),
        unitPrice = Value(unitPrice);
  static Insertable<OrderItem> custom({
    Expression<int>? id,
    Expression<int>? orderId,
    Expression<int>? productId,
    Expression<String>? productName,
    Expression<int>? quantity,
    Expression<double>? unitPrice,
    Expression<String>? modifiersJson,
    Expression<String>? itemNote,
    Expression<String>? itemStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (modifiersJson != null) 'modifiers_json': modifiersJson,
      if (itemNote != null) 'item_note': itemNote,
      if (itemStatus != null) 'item_status': itemStatus,
    });
  }

  OrderItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? orderId,
      Value<int>? productId,
      Value<String>? productName,
      Value<int>? quantity,
      Value<double>? unitPrice,
      Value<String?>? modifiersJson,
      Value<String?>? itemNote,
      Value<String>? itemStatus}) {
    return OrderItemsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      modifiersJson: modifiersJson ?? this.modifiersJson,
      itemNote: itemNote ?? this.itemNote,
      itemStatus: itemStatus ?? this.itemStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (modifiersJson.present) {
      map['modifiers_json'] = Variable<String>(modifiersJson.value);
    }
    if (itemNote.present) {
      map['item_note'] = Variable<String>(itemNote.value);
    }
    if (itemStatus.present) {
      map['item_status'] = Variable<String>(itemStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('modifiersJson: $modifiersJson, ')
          ..write('itemNote: $itemNote, ')
          ..write('itemStatus: $itemStatus')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
      'order_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orders (id)'));
  static const VerificationMeta _shiftIdMeta =
      const VerificationMeta('shiftId');
  @override
  late final GeneratedColumn<int> shiftId = GeneratedColumn<int>(
      'shift_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES shifts (id)'));
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountTenderedMeta =
      const VerificationMeta('amountTendered');
  @override
  late final GeneratedColumn<double> amountTendered = GeneratedColumn<double>(
      'amount_tendered', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _changeGivenMeta =
      const VerificationMeta('changeGiven');
  @override
  late final GeneratedColumn<double> changeGiven = GeneratedColumn<double>(
      'change_given', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _referenceMeta =
      const VerificationMeta('reference');
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
      'reference', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tipAmountMeta =
      const VerificationMeta('tipAmount');
  @override
  late final GeneratedColumn<double> tipAmount = GeneratedColumn<double>(
      'tip_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        shiftId,
        method,
        amountTendered,
        changeGiven,
        reference,
        tipAmount,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(Insertable<Payment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(_shiftIdMeta,
          shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta));
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount_tendered')) {
      context.handle(
          _amountTenderedMeta,
          amountTendered.isAcceptableOrUnknown(
              data['amount_tendered']!, _amountTenderedMeta));
    } else if (isInserting) {
      context.missing(_amountTenderedMeta);
    }
    if (data.containsKey('change_given')) {
      context.handle(
          _changeGivenMeta,
          changeGiven.isAcceptableOrUnknown(
              data['change_given']!, _changeGivenMeta));
    }
    if (data.containsKey('reference')) {
      context.handle(_referenceMeta,
          reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta));
    }
    if (data.containsKey('tip_amount')) {
      context.handle(_tipAmountMeta,
          tipAmount.isAcceptableOrUnknown(data['tip_amount']!, _tipAmountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_id'])!,
      shiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shift_id']),
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      amountTendered: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}amount_tendered'])!,
      changeGiven: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}change_given'])!,
      reference: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reference']),
      tipAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tip_amount'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final int id;
  final int orderId;
  final int? shiftId;
  final String method;
  final double amountTendered;
  final double changeGiven;
  final String? reference;
  final double tipAmount;
  final DateTime createdAt;
  const Payment(
      {required this.id,
      required this.orderId,
      this.shiftId,
      required this.method,
      required this.amountTendered,
      required this.changeGiven,
      this.reference,
      required this.tipAmount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_id'] = Variable<int>(orderId);
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<int>(shiftId);
    }
    map['method'] = Variable<String>(method);
    map['amount_tendered'] = Variable<double>(amountTendered);
    map['change_given'] = Variable<double>(changeGiven);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    map['tip_amount'] = Variable<double>(tipAmount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      method: Value(method),
      amountTendered: Value(amountTendered),
      changeGiven: Value(changeGiven),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      tipAmount: Value(tipAmount),
      createdAt: Value(createdAt),
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<int>(json['id']),
      orderId: serializer.fromJson<int>(json['orderId']),
      shiftId: serializer.fromJson<int?>(json['shiftId']),
      method: serializer.fromJson<String>(json['method']),
      amountTendered: serializer.fromJson<double>(json['amountTendered']),
      changeGiven: serializer.fromJson<double>(json['changeGiven']),
      reference: serializer.fromJson<String?>(json['reference']),
      tipAmount: serializer.fromJson<double>(json['tipAmount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderId': serializer.toJson<int>(orderId),
      'shiftId': serializer.toJson<int?>(shiftId),
      'method': serializer.toJson<String>(method),
      'amountTendered': serializer.toJson<double>(amountTendered),
      'changeGiven': serializer.toJson<double>(changeGiven),
      'reference': serializer.toJson<String?>(reference),
      'tipAmount': serializer.toJson<double>(tipAmount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Payment copyWith(
          {int? id,
          int? orderId,
          Value<int?> shiftId = const Value.absent(),
          String? method,
          double? amountTendered,
          double? changeGiven,
          Value<String?> reference = const Value.absent(),
          double? tipAmount,
          DateTime? createdAt}) =>
      Payment(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        shiftId: shiftId.present ? shiftId.value : this.shiftId,
        method: method ?? this.method,
        amountTendered: amountTendered ?? this.amountTendered,
        changeGiven: changeGiven ?? this.changeGiven,
        reference: reference.present ? reference.value : this.reference,
        tipAmount: tipAmount ?? this.tipAmount,
        createdAt: createdAt ?? this.createdAt,
      );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      method: data.method.present ? data.method.value : this.method,
      amountTendered: data.amountTendered.present
          ? data.amountTendered.value
          : this.amountTendered,
      changeGiven:
          data.changeGiven.present ? data.changeGiven.value : this.changeGiven,
      reference: data.reference.present ? data.reference.value : this.reference,
      tipAmount: data.tipAmount.present ? data.tipAmount.value : this.tipAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('shiftId: $shiftId, ')
          ..write('method: $method, ')
          ..write('amountTendered: $amountTendered, ')
          ..write('changeGiven: $changeGiven, ')
          ..write('reference: $reference, ')
          ..write('tipAmount: $tipAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, orderId, shiftId, method, amountTendered,
      changeGiven, reference, tipAmount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.shiftId == this.shiftId &&
          other.method == this.method &&
          other.amountTendered == this.amountTendered &&
          other.changeGiven == this.changeGiven &&
          other.reference == this.reference &&
          other.tipAmount == this.tipAmount &&
          other.createdAt == this.createdAt);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<int> id;
  final Value<int> orderId;
  final Value<int?> shiftId;
  final Value<String> method;
  final Value<double> amountTendered;
  final Value<double> changeGiven;
  final Value<String?> reference;
  final Value<double> tipAmount;
  final Value<DateTime> createdAt;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.method = const Value.absent(),
    this.amountTendered = const Value.absent(),
    this.changeGiven = const Value.absent(),
    this.reference = const Value.absent(),
    this.tipAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int orderId,
    this.shiftId = const Value.absent(),
    required String method,
    required double amountTendered,
    this.changeGiven = const Value.absent(),
    this.reference = const Value.absent(),
    this.tipAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : orderId = Value(orderId),
        method = Value(method),
        amountTendered = Value(amountTendered);
  static Insertable<Payment> custom({
    Expression<int>? id,
    Expression<int>? orderId,
    Expression<int>? shiftId,
    Expression<String>? method,
    Expression<double>? amountTendered,
    Expression<double>? changeGiven,
    Expression<String>? reference,
    Expression<double>? tipAmount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (shiftId != null) 'shift_id': shiftId,
      if (method != null) 'method': method,
      if (amountTendered != null) 'amount_tendered': amountTendered,
      if (changeGiven != null) 'change_given': changeGiven,
      if (reference != null) 'reference': reference,
      if (tipAmount != null) 'tip_amount': tipAmount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PaymentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? orderId,
      Value<int?>? shiftId,
      Value<String>? method,
      Value<double>? amountTendered,
      Value<double>? changeGiven,
      Value<String?>? reference,
      Value<double>? tipAmount,
      Value<DateTime>? createdAt}) {
    return PaymentsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      shiftId: shiftId ?? this.shiftId,
      method: method ?? this.method,
      amountTendered: amountTendered ?? this.amountTendered,
      changeGiven: changeGiven ?? this.changeGiven,
      reference: reference ?? this.reference,
      tipAmount: tipAmount ?? this.tipAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<int>(shiftId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amountTendered.present) {
      map['amount_tendered'] = Variable<double>(amountTendered.value);
    }
    if (changeGiven.present) {
      map['change_given'] = Variable<double>(changeGiven.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (tipAmount.present) {
      map['tip_amount'] = Variable<double>(tipAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('shiftId: $shiftId, ')
          ..write('method: $method, ')
          ..write('amountTendered: $amountTendered, ')
          ..write('changeGiven: $changeGiven, ')
          ..write('reference: $reference, ')
          ..write('tipAmount: $tipAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdByIdMeta =
      const VerificationMeta('createdById');
  @override
  late final GeneratedColumn<int> createdById = GeneratedColumn<int>(
      'created_by_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, category, description, amount, date, createdById, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(Insertable<Expense> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_by_id')) {
      context.handle(
          _createdByIdMeta,
          createdById.isAcceptableOrUnknown(
              data['created_by_id']!, _createdByIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      createdById: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_by_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final int id;
  final String category;
  final String description;
  final double amount;
  final DateTime date;
  final int? createdById;
  final DateTime createdAt;
  const Expense(
      {required this.id,
      required this.category,
      required this.description,
      required this.amount,
      required this.date,
      this.createdById,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category'] = Variable<String>(category);
    map['description'] = Variable<String>(description);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || createdById != null) {
      map['created_by_id'] = Variable<int>(createdById);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      category: Value(category),
      description: Value(description),
      amount: Value(amount),
      date: Value(date),
      createdById: createdById == null && nullToAbsent
          ? const Value.absent()
          : Value(createdById),
      createdAt: Value(createdAt),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<int>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      createdById: serializer.fromJson<int?>(json['createdById']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'createdById': serializer.toJson<int?>(createdById),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Expense copyWith(
          {int? id,
          String? category,
          String? description,
          double? amount,
          DateTime? date,
          Value<int?> createdById = const Value.absent(),
          DateTime? createdAt}) =>
      Expense(
        id: id ?? this.id,
        category: category ?? this.category,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        createdById: createdById.present ? createdById.value : this.createdById,
        createdAt: createdAt ?? this.createdAt,
      );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      description:
          data.description.present ? data.description.value : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      createdById:
          data.createdById.present ? data.createdById.value : this.createdById,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('createdById: $createdById, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, category, description, amount, date, createdById, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.category == this.category &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.createdById == this.createdById &&
          other.createdAt == this.createdAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<int> id;
  final Value<String> category;
  final Value<String> description;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<int?> createdById;
  final Value<DateTime> createdAt;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.createdById = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required String category,
    required String description,
    required double amount,
    required DateTime date,
    this.createdById = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : category = Value(category),
        description = Value(description),
        amount = Value(amount),
        date = Value(date);
  static Insertable<Expense> custom({
    Expression<int>? id,
    Expression<String>? category,
    Expression<String>? description,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<int>? createdById,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (createdById != null) 'created_by_id': createdById,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExpensesCompanion copyWith(
      {Value<int>? id,
      Value<String>? category,
      Value<String>? description,
      Value<double>? amount,
      Value<DateTime>? date,
      Value<int?>? createdById,
      Value<DateTime>? createdAt}) {
    return ExpensesCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (createdById.present) {
      map['created_by_id'] = Variable<int>(createdById.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('createdById: $createdById, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InventoryMovementsTable extends InventoryMovements
    with TableInfo<$InventoryMovementsTable, InventoryMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<int> delta = GeneratedColumn<int>(
      'delta', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
      'order_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orders (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, productId, delta, reason, note, orderId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_movements';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryMovement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('delta')) {
      context.handle(
          _deltaMeta, delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta));
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryMovement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      delta: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}delta'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InventoryMovementsTable createAlias(String alias) {
    return $InventoryMovementsTable(attachedDatabase, alias);
  }
}

class InventoryMovement extends DataClass
    implements Insertable<InventoryMovement> {
  final int id;
  final int productId;
  final int delta;
  final String reason;
  final String? note;
  final int? orderId;
  final DateTime createdAt;
  const InventoryMovement(
      {required this.id,
      required this.productId,
      required this.delta,
      required this.reason,
      this.note,
      this.orderId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['delta'] = Variable<int>(delta);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<int>(orderId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InventoryMovementsCompanion toCompanion(bool nullToAbsent) {
    return InventoryMovementsCompanion(
      id: Value(id),
      productId: Value(productId),
      delta: Value(delta),
      reason: Value(reason),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      createdAt: Value(createdAt),
    );
  }

  factory InventoryMovement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryMovement(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      delta: serializer.fromJson<int>(json['delta']),
      reason: serializer.fromJson<String>(json['reason']),
      note: serializer.fromJson<String?>(json['note']),
      orderId: serializer.fromJson<int?>(json['orderId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'delta': serializer.toJson<int>(delta),
      'reason': serializer.toJson<String>(reason),
      'note': serializer.toJson<String?>(note),
      'orderId': serializer.toJson<int?>(orderId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InventoryMovement copyWith(
          {int? id,
          int? productId,
          int? delta,
          String? reason,
          Value<String?> note = const Value.absent(),
          Value<int?> orderId = const Value.absent(),
          DateTime? createdAt}) =>
      InventoryMovement(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        delta: delta ?? this.delta,
        reason: reason ?? this.reason,
        note: note.present ? note.value : this.note,
        orderId: orderId.present ? orderId.value : this.orderId,
        createdAt: createdAt ?? this.createdAt,
      );
  InventoryMovement copyWithCompanion(InventoryMovementsCompanion data) {
    return InventoryMovement(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      delta: data.delta.present ? data.delta.value : this.delta,
      reason: data.reason.present ? data.reason.value : this.reason,
      note: data.note.present ? data.note.value : this.note,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryMovement(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('orderId: $orderId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, delta, reason, note, orderId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryMovement &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.delta == this.delta &&
          other.reason == this.reason &&
          other.note == this.note &&
          other.orderId == this.orderId &&
          other.createdAt == this.createdAt);
}

class InventoryMovementsCompanion extends UpdateCompanion<InventoryMovement> {
  final Value<int> id;
  final Value<int> productId;
  final Value<int> delta;
  final Value<String> reason;
  final Value<String?> note;
  final Value<int?> orderId;
  final Value<DateTime> createdAt;
  const InventoryMovementsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.delta = const Value.absent(),
    this.reason = const Value.absent(),
    this.note = const Value.absent(),
    this.orderId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InventoryMovementsCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required int delta,
    required String reason,
    this.note = const Value.absent(),
    this.orderId = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : productId = Value(productId),
        delta = Value(delta),
        reason = Value(reason);
  static Insertable<InventoryMovement> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<int>? delta,
    Expression<String>? reason,
    Expression<String>? note,
    Expression<int>? orderId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (delta != null) 'delta': delta,
      if (reason != null) 'reason': reason,
      if (note != null) 'note': note,
      if (orderId != null) 'order_id': orderId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InventoryMovementsCompanion copyWith(
      {Value<int>? id,
      Value<int>? productId,
      Value<int>? delta,
      Value<String>? reason,
      Value<String?>? note,
      Value<int?>? orderId,
      Value<DateTime>? createdAt}) {
    return InventoryMovementsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      delta: delta ?? this.delta,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (delta.present) {
      map['delta'] = Variable<int>(delta.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryMovementsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('orderId: $orderId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
      'ts', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<int> entityId = GeneratedColumn<int>(
      'entity_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _detailJsonMeta =
      const VerificationMeta('detailJson');
  @override
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
      'detail_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, ts, employeeId, action, entity, entityId, detailJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(Insertable<AuditLogData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    }
    if (data.containsKey('detail_json')) {
      context.handle(
          _detailJsonMeta,
          detailJson.isAcceptableOrUnknown(
              data['detail_json']!, _detailJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ts: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ts'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id']),
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity']),
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}entity_id']),
      detailJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}detail_json']),
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogData extends DataClass implements Insertable<AuditLogData> {
  final int id;
  final DateTime ts;
  final int? employeeId;
  final String action;
  final String? entity;
  final int? entityId;
  final String? detailJson;
  const AuditLogData(
      {required this.id,
      required this.ts,
      this.employeeId,
      required this.action,
      this.entity,
      this.entityId,
      this.detailJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ts'] = Variable<DateTime>(ts);
    if (!nullToAbsent || employeeId != null) {
      map['employee_id'] = Variable<int>(employeeId);
    }
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || entity != null) {
      map['entity'] = Variable<String>(entity);
    }
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<int>(entityId);
    }
    if (!nullToAbsent || detailJson != null) {
      map['detail_json'] = Variable<String>(detailJson);
    }
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      ts: Value(ts),
      employeeId: employeeId == null && nullToAbsent
          ? const Value.absent()
          : Value(employeeId),
      action: Value(action),
      entity:
          entity == null && nullToAbsent ? const Value.absent() : Value(entity),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      detailJson: detailJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailJson),
    );
  }

  factory AuditLogData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogData(
      id: serializer.fromJson<int>(json['id']),
      ts: serializer.fromJson<DateTime>(json['ts']),
      employeeId: serializer.fromJson<int?>(json['employeeId']),
      action: serializer.fromJson<String>(json['action']),
      entity: serializer.fromJson<String?>(json['entity']),
      entityId: serializer.fromJson<int?>(json['entityId']),
      detailJson: serializer.fromJson<String?>(json['detailJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ts': serializer.toJson<DateTime>(ts),
      'employeeId': serializer.toJson<int?>(employeeId),
      'action': serializer.toJson<String>(action),
      'entity': serializer.toJson<String?>(entity),
      'entityId': serializer.toJson<int?>(entityId),
      'detailJson': serializer.toJson<String?>(detailJson),
    };
  }

  AuditLogData copyWith(
          {int? id,
          DateTime? ts,
          Value<int?> employeeId = const Value.absent(),
          String? action,
          Value<String?> entity = const Value.absent(),
          Value<int?> entityId = const Value.absent(),
          Value<String?> detailJson = const Value.absent()}) =>
      AuditLogData(
        id: id ?? this.id,
        ts: ts ?? this.ts,
        employeeId: employeeId.present ? employeeId.value : this.employeeId,
        action: action ?? this.action,
        entity: entity.present ? entity.value : this.entity,
        entityId: entityId.present ? entityId.value : this.entityId,
        detailJson: detailJson.present ? detailJson.value : this.detailJson,
      );
  AuditLogData copyWithCompanion(AuditLogCompanion data) {
    return AuditLogData(
      id: data.id.present ? data.id.value : this.id,
      ts: data.ts.present ? data.ts.value : this.ts,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      action: data.action.present ? data.action.value : this.action,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      detailJson:
          data.detailJson.present ? data.detailJson.value : this.detailJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogData(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('employeeId: $employeeId, ')
          ..write('action: $action, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('detailJson: $detailJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ts, employeeId, action, entity, entityId, detailJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogData &&
          other.id == this.id &&
          other.ts == this.ts &&
          other.employeeId == this.employeeId &&
          other.action == this.action &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.detailJson == this.detailJson);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogData> {
  final Value<int> id;
  final Value<DateTime> ts;
  final Value<int?> employeeId;
  final Value<String> action;
  final Value<String?> entity;
  final Value<int?> entityId;
  final Value<String?> detailJson;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.ts = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.action = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.detailJson = const Value.absent(),
  });
  AuditLogCompanion.insert({
    this.id = const Value.absent(),
    this.ts = const Value.absent(),
    this.employeeId = const Value.absent(),
    required String action,
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.detailJson = const Value.absent(),
  }) : action = Value(action);
  static Insertable<AuditLogData> custom({
    Expression<int>? id,
    Expression<DateTime>? ts,
    Expression<int>? employeeId,
    Expression<String>? action,
    Expression<String>? entity,
    Expression<int>? entityId,
    Expression<String>? detailJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ts != null) 'ts': ts,
      if (employeeId != null) 'employee_id': employeeId,
      if (action != null) 'action': action,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (detailJson != null) 'detail_json': detailJson,
    });
  }

  AuditLogCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? ts,
      Value<int?>? employeeId,
      Value<String>? action,
      Value<String?>? entity,
      Value<int?>? entityId,
      Value<String?>? detailJson}) {
    return AuditLogCompanion(
      id: id ?? this.id,
      ts: ts ?? this.ts,
      employeeId: employeeId ?? this.employeeId,
      action: action ?? this.action,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      detailJson: detailJson ?? this.detailJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<int>(entityId.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('employeeId: $employeeId, ')
          ..write('action: $action, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('detailJson: $detailJson')
          ..write(')'))
        .toString();
  }
}

class $CashMovementsTable extends CashMovements
    with TableInfo<$CashMovementsTable, CashMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _shiftIdMeta =
      const VerificationMeta('shiftId');
  @override
  late final GeneratedColumn<int> shiftId = GeneratedColumn<int>(
      'shift_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES shifts (id)'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
      'ts', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, shiftId, employeeId, type, amount, reason, ts];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_movements';
  @override
  VerificationContext validateIntegrity(Insertable<CashMovement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shift_id')) {
      context.handle(_shiftIdMeta,
          shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta));
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashMovement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      shiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shift_id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
      ts: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ts'])!,
    );
  }

  @override
  $CashMovementsTable createAlias(String alias) {
    return $CashMovementsTable(attachedDatabase, alias);
  }
}

class CashMovement extends DataClass implements Insertable<CashMovement> {
  final int id;
  final int shiftId;
  final int employeeId;
  final String type;
  final double amount;
  final String? reason;
  final DateTime ts;
  const CashMovement(
      {required this.id,
      required this.shiftId,
      required this.employeeId,
      required this.type,
      required this.amount,
      this.reason,
      required this.ts});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shift_id'] = Variable<int>(shiftId);
    map['employee_id'] = Variable<int>(employeeId);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['ts'] = Variable<DateTime>(ts);
    return map;
  }

  CashMovementsCompanion toCompanion(bool nullToAbsent) {
    return CashMovementsCompanion(
      id: Value(id),
      shiftId: Value(shiftId),
      employeeId: Value(employeeId),
      type: Value(type),
      amount: Value(amount),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      ts: Value(ts),
    );
  }

  factory CashMovement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashMovement(
      id: serializer.fromJson<int>(json['id']),
      shiftId: serializer.fromJson<int>(json['shiftId']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      reason: serializer.fromJson<String?>(json['reason']),
      ts: serializer.fromJson<DateTime>(json['ts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shiftId': serializer.toJson<int>(shiftId),
      'employeeId': serializer.toJson<int>(employeeId),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'reason': serializer.toJson<String?>(reason),
      'ts': serializer.toJson<DateTime>(ts),
    };
  }

  CashMovement copyWith(
          {int? id,
          int? shiftId,
          int? employeeId,
          String? type,
          double? amount,
          Value<String?> reason = const Value.absent(),
          DateTime? ts}) =>
      CashMovement(
        id: id ?? this.id,
        shiftId: shiftId ?? this.shiftId,
        employeeId: employeeId ?? this.employeeId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        reason: reason.present ? reason.value : this.reason,
        ts: ts ?? this.ts,
      );
  CashMovement copyWithCompanion(CashMovementsCompanion data) {
    return CashMovement(
      id: data.id.present ? data.id.value : this.id,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      ts: data.ts.present ? data.ts.value : this.ts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashMovement(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('employeeId: $employeeId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, shiftId, employeeId, type, amount, reason, ts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashMovement &&
          other.id == this.id &&
          other.shiftId == this.shiftId &&
          other.employeeId == this.employeeId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.ts == this.ts);
}

class CashMovementsCompanion extends UpdateCompanion<CashMovement> {
  final Value<int> id;
  final Value<int> shiftId;
  final Value<int> employeeId;
  final Value<String> type;
  final Value<double> amount;
  final Value<String?> reason;
  final Value<DateTime> ts;
  const CashMovementsCompanion({
    this.id = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.ts = const Value.absent(),
  });
  CashMovementsCompanion.insert({
    this.id = const Value.absent(),
    required int shiftId,
    required int employeeId,
    required String type,
    required double amount,
    this.reason = const Value.absent(),
    this.ts = const Value.absent(),
  })  : shiftId = Value(shiftId),
        employeeId = Value(employeeId),
        type = Value(type),
        amount = Value(amount);
  static Insertable<CashMovement> custom({
    Expression<int>? id,
    Expression<int>? shiftId,
    Expression<int>? employeeId,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? reason,
    Expression<DateTime>? ts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shiftId != null) 'shift_id': shiftId,
      if (employeeId != null) 'employee_id': employeeId,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (ts != null) 'ts': ts,
    });
  }

  CashMovementsCompanion copyWith(
      {Value<int>? id,
      Value<int>? shiftId,
      Value<int>? employeeId,
      Value<String>? type,
      Value<double>? amount,
      Value<String?>? reason,
      Value<DateTime>? ts}) {
    return CashMovementsCompanion(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      employeeId: employeeId ?? this.employeeId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      ts: ts ?? this.ts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<int>(shiftId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashMovementsCompanion(')
          ..write('id: $id, ')
          ..write('shiftId: $shiftId, ')
          ..write('employeeId: $employeeId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }
}

class $RefundsTable extends Refunds with TableInfo<$RefundsTable, Refund> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
      'order_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orders (id)'));
  static const VerificationMeta _orderItemIdMeta =
      const VerificationMeta('orderItemId');
  @override
  late final GeneratedColumn<int> orderItemId = GeneratedColumn<int>(
      'order_item_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES order_items (id)'));
  static const VerificationMeta _shiftIdMeta =
      const VerificationMeta('shiftId');
  @override
  late final GeneratedColumn<int> shiftId = GeneratedColumn<int>(
      'shift_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES shifts (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _restockedMeta =
      const VerificationMeta('restocked');
  @override
  late final GeneratedColumn<bool> restocked = GeneratedColumn<bool>(
      'restocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("restocked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _supervisorIdMeta =
      const VerificationMeta('supervisorId');
  @override
  late final GeneratedColumn<int> supervisorId = GeneratedColumn<int>(
      'supervisor_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<DateTime> ts = GeneratedColumn<DateTime>(
      'ts', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        orderItemId,
        shiftId,
        amount,
        reason,
        restocked,
        employeeId,
        supervisorId,
        ts
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refunds';
  @override
  VerificationContext validateIntegrity(Insertable<Refund> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('order_item_id')) {
      context.handle(
          _orderItemIdMeta,
          orderItemId.isAcceptableOrUnknown(
              data['order_item_id']!, _orderItemIdMeta));
    }
    if (data.containsKey('shift_id')) {
      context.handle(_shiftIdMeta,
          shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('restocked')) {
      context.handle(_restockedMeta,
          restocked.isAcceptableOrUnknown(data['restocked']!, _restockedMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('supervisor_id')) {
      context.handle(
          _supervisorIdMeta,
          supervisorId.isAcceptableOrUnknown(
              data['supervisor_id']!, _supervisorIdMeta));
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Refund map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Refund(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_id'])!,
      orderItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_item_id']),
      shiftId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shift_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
      restocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}restocked'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id'])!,
      supervisorId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}supervisor_id']),
      ts: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ts'])!,
    );
  }

  @override
  $RefundsTable createAlias(String alias) {
    return $RefundsTable(attachedDatabase, alias);
  }
}

class Refund extends DataClass implements Insertable<Refund> {
  final int id;
  final int orderId;
  final int? orderItemId;
  final int? shiftId;
  final double amount;
  final String? reason;
  final bool restocked;
  final int employeeId;
  final int? supervisorId;
  final DateTime ts;
  const Refund(
      {required this.id,
      required this.orderId,
      this.orderItemId,
      this.shiftId,
      required this.amount,
      this.reason,
      required this.restocked,
      required this.employeeId,
      this.supervisorId,
      required this.ts});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_id'] = Variable<int>(orderId);
    if (!nullToAbsent || orderItemId != null) {
      map['order_item_id'] = Variable<int>(orderItemId);
    }
    if (!nullToAbsent || shiftId != null) {
      map['shift_id'] = Variable<int>(shiftId);
    }
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['restocked'] = Variable<bool>(restocked);
    map['employee_id'] = Variable<int>(employeeId);
    if (!nullToAbsent || supervisorId != null) {
      map['supervisor_id'] = Variable<int>(supervisorId);
    }
    map['ts'] = Variable<DateTime>(ts);
    return map;
  }

  RefundsCompanion toCompanion(bool nullToAbsent) {
    return RefundsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      orderItemId: orderItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderItemId),
      shiftId: shiftId == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftId),
      amount: Value(amount),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      restocked: Value(restocked),
      employeeId: Value(employeeId),
      supervisorId: supervisorId == null && nullToAbsent
          ? const Value.absent()
          : Value(supervisorId),
      ts: Value(ts),
    );
  }

  factory Refund.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Refund(
      id: serializer.fromJson<int>(json['id']),
      orderId: serializer.fromJson<int>(json['orderId']),
      orderItemId: serializer.fromJson<int?>(json['orderItemId']),
      shiftId: serializer.fromJson<int?>(json['shiftId']),
      amount: serializer.fromJson<double>(json['amount']),
      reason: serializer.fromJson<String?>(json['reason']),
      restocked: serializer.fromJson<bool>(json['restocked']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      supervisorId: serializer.fromJson<int?>(json['supervisorId']),
      ts: serializer.fromJson<DateTime>(json['ts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderId': serializer.toJson<int>(orderId),
      'orderItemId': serializer.toJson<int?>(orderItemId),
      'shiftId': serializer.toJson<int?>(shiftId),
      'amount': serializer.toJson<double>(amount),
      'reason': serializer.toJson<String?>(reason),
      'restocked': serializer.toJson<bool>(restocked),
      'employeeId': serializer.toJson<int>(employeeId),
      'supervisorId': serializer.toJson<int?>(supervisorId),
      'ts': serializer.toJson<DateTime>(ts),
    };
  }

  Refund copyWith(
          {int? id,
          int? orderId,
          Value<int?> orderItemId = const Value.absent(),
          Value<int?> shiftId = const Value.absent(),
          double? amount,
          Value<String?> reason = const Value.absent(),
          bool? restocked,
          int? employeeId,
          Value<int?> supervisorId = const Value.absent(),
          DateTime? ts}) =>
      Refund(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        orderItemId: orderItemId.present ? orderItemId.value : this.orderItemId,
        shiftId: shiftId.present ? shiftId.value : this.shiftId,
        amount: amount ?? this.amount,
        reason: reason.present ? reason.value : this.reason,
        restocked: restocked ?? this.restocked,
        employeeId: employeeId ?? this.employeeId,
        supervisorId:
            supervisorId.present ? supervisorId.value : this.supervisorId,
        ts: ts ?? this.ts,
      );
  Refund copyWithCompanion(RefundsCompanion data) {
    return Refund(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      orderItemId:
          data.orderItemId.present ? data.orderItemId.value : this.orderItemId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      restocked: data.restocked.present ? data.restocked.value : this.restocked,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      supervisorId: data.supervisorId.present
          ? data.supervisorId.value
          : this.supervisorId,
      ts: data.ts.present ? data.ts.value : this.ts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Refund(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('orderItemId: $orderItemId, ')
          ..write('shiftId: $shiftId, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('restocked: $restocked, ')
          ..write('employeeId: $employeeId, ')
          ..write('supervisorId: $supervisorId, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, orderId, orderItemId, shiftId, amount,
      reason, restocked, employeeId, supervisorId, ts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Refund &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.orderItemId == this.orderItemId &&
          other.shiftId == this.shiftId &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.restocked == this.restocked &&
          other.employeeId == this.employeeId &&
          other.supervisorId == this.supervisorId &&
          other.ts == this.ts);
}

class RefundsCompanion extends UpdateCompanion<Refund> {
  final Value<int> id;
  final Value<int> orderId;
  final Value<int?> orderItemId;
  final Value<int?> shiftId;
  final Value<double> amount;
  final Value<String?> reason;
  final Value<bool> restocked;
  final Value<int> employeeId;
  final Value<int?> supervisorId;
  final Value<DateTime> ts;
  const RefundsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.orderItemId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.restocked = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.supervisorId = const Value.absent(),
    this.ts = const Value.absent(),
  });
  RefundsCompanion.insert({
    this.id = const Value.absent(),
    required int orderId,
    this.orderItemId = const Value.absent(),
    this.shiftId = const Value.absent(),
    required double amount,
    this.reason = const Value.absent(),
    this.restocked = const Value.absent(),
    required int employeeId,
    this.supervisorId = const Value.absent(),
    this.ts = const Value.absent(),
  })  : orderId = Value(orderId),
        amount = Value(amount),
        employeeId = Value(employeeId);
  static Insertable<Refund> custom({
    Expression<int>? id,
    Expression<int>? orderId,
    Expression<int>? orderItemId,
    Expression<int>? shiftId,
    Expression<double>? amount,
    Expression<String>? reason,
    Expression<bool>? restocked,
    Expression<int>? employeeId,
    Expression<int>? supervisorId,
    Expression<DateTime>? ts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (orderItemId != null) 'order_item_id': orderItemId,
      if (shiftId != null) 'shift_id': shiftId,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (restocked != null) 'restocked': restocked,
      if (employeeId != null) 'employee_id': employeeId,
      if (supervisorId != null) 'supervisor_id': supervisorId,
      if (ts != null) 'ts': ts,
    });
  }

  RefundsCompanion copyWith(
      {Value<int>? id,
      Value<int>? orderId,
      Value<int?>? orderItemId,
      Value<int?>? shiftId,
      Value<double>? amount,
      Value<String?>? reason,
      Value<bool>? restocked,
      Value<int>? employeeId,
      Value<int?>? supervisorId,
      Value<DateTime>? ts}) {
    return RefundsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderItemId: orderItemId ?? this.orderItemId,
      shiftId: shiftId ?? this.shiftId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      restocked: restocked ?? this.restocked,
      employeeId: employeeId ?? this.employeeId,
      supervisorId: supervisorId ?? this.supervisorId,
      ts: ts ?? this.ts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (orderItemId.present) {
      map['order_item_id'] = Variable<int>(orderItemId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<int>(shiftId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (restocked.present) {
      map['restocked'] = Variable<bool>(restocked.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (supervisorId.present) {
      map['supervisor_id'] = Variable<int>(supervisorId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<DateTime>(ts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefundsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('orderItemId: $orderItemId, ')
          ..write('shiftId: $shiftId, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('restocked: $restocked, ')
          ..write('employeeId: $employeeId, ')
          ..write('supervisorId: $supervisorId, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }
}

class $SuppliersTable extends Suppliers
    with TableInfo<$SuppliersTable, Supplier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuppliersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contactNameMeta =
      const VerificationMeta('contactName');
  @override
  late final GeneratedColumn<String> contactName = GeneratedColumn<String>(
      'contact_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, contactName, phone, note, active, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suppliers';
  @override
  VerificationContext validateIntegrity(Insertable<Supplier> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('contact_name')) {
      context.handle(
          _contactNameMeta,
          contactName.isAcceptableOrUnknown(
              data['contact_name']!, _contactNameMeta));
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Supplier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Supplier(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      contactName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}contact_name']),
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SuppliersTable createAlias(String alias) {
    return $SuppliersTable(attachedDatabase, alias);
  }
}

class Supplier extends DataClass implements Insertable<Supplier> {
  final int id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? note;
  final bool active;
  final DateTime createdAt;
  const Supplier(
      {required this.id,
      required this.name,
      this.contactName,
      this.phone,
      this.note,
      required this.active,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || contactName != null) {
      map['contact_name'] = Variable<String>(contactName);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SuppliersCompanion toCompanion(bool nullToAbsent) {
    return SuppliersCompanion(
      id: Value(id),
      name: Value(name),
      contactName: contactName == null && nullToAbsent
          ? const Value.absent()
          : Value(contactName),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Supplier(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      contactName: serializer.fromJson<String?>(json['contactName']),
      phone: serializer.fromJson<String?>(json['phone']),
      note: serializer.fromJson<String?>(json['note']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'contactName': serializer.toJson<String?>(contactName),
      'phone': serializer.toJson<String?>(phone),
      'note': serializer.toJson<String?>(note),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Supplier copyWith(
          {int? id,
          String? name,
          Value<String?> contactName = const Value.absent(),
          Value<String?> phone = const Value.absent(),
          Value<String?> note = const Value.absent(),
          bool? active,
          DateTime? createdAt}) =>
      Supplier(
        id: id ?? this.id,
        name: name ?? this.name,
        contactName: contactName.present ? contactName.value : this.contactName,
        phone: phone.present ? phone.value : this.phone,
        note: note.present ? note.value : this.note,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
      );
  Supplier copyWithCompanion(SuppliersCompanion data) {
    return Supplier(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      contactName:
          data.contactName.present ? data.contactName.value : this.contactName,
      phone: data.phone.present ? data.phone.value : this.phone,
      note: data.note.present ? data.note.value : this.note,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Supplier(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contactName: $contactName, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, contactName, phone, note, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Supplier &&
          other.id == this.id &&
          other.name == this.name &&
          other.contactName == this.contactName &&
          other.phone == this.phone &&
          other.note == this.note &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class SuppliersCompanion extends UpdateCompanion<Supplier> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> contactName;
  final Value<String?> phone;
  final Value<String?> note;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  const SuppliersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.contactName = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SuppliersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.contactName = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Supplier> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? contactName,
    Expression<String>? phone,
    Expression<String>? note,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (contactName != null) 'contact_name': contactName,
      if (phone != null) 'phone': phone,
      if (note != null) 'note': note,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SuppliersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? contactName,
      Value<String?>? phone,
      Value<String?>? note,
      Value<bool>? active,
      Value<DateTime>? createdAt}) {
    return SuppliersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (contactName.present) {
      map['contact_name'] = Variable<String>(contactName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuppliersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contactName: $contactName, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IngredientsTable extends Ingredients
    with TableInfo<$IngredientsTable, Ingredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stockQuantityMeta =
      const VerificationMeta('stockQuantity');
  @override
  late final GeneratedColumn<double> stockQuantity = GeneratedColumn<double>(
      'stock_quantity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minStockMeta =
      const VerificationMeta('minStock');
  @override
  late final GeneratedColumn<double> minStock = GeneratedColumn<double>(
      'min_stock', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastUnitCostMeta =
      const VerificationMeta('lastUnitCost');
  @override
  late final GeneratedColumn<double> lastUnitCost = GeneratedColumn<double>(
      'last_unit_cost', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        unit,
        stockQuantity,
        minStock,
        lastUnitCost,
        active,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredients';
  @override
  VerificationContext validateIntegrity(Insertable<Ingredient> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('stock_quantity')) {
      context.handle(
          _stockQuantityMeta,
          stockQuantity.isAcceptableOrUnknown(
              data['stock_quantity']!, _stockQuantityMeta));
    }
    if (data.containsKey('min_stock')) {
      context.handle(_minStockMeta,
          minStock.isAcceptableOrUnknown(data['min_stock']!, _minStockMeta));
    }
    if (data.containsKey('last_unit_cost')) {
      context.handle(
          _lastUnitCostMeta,
          lastUnitCost.isAcceptableOrUnknown(
              data['last_unit_cost']!, _lastUnitCostMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ingredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ingredient(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      stockQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stock_quantity'])!,
      minStock: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_stock'])!,
      lastUnitCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}last_unit_cost']),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $IngredientsTable createAlias(String alias) {
    return $IngredientsTable(attachedDatabase, alias);
  }
}

class Ingredient extends DataClass implements Insertable<Ingredient> {
  final int id;
  final String name;
  final String unit;
  final double stockQuantity;
  final double minStock;
  final double? lastUnitCost;
  final bool active;
  final DateTime createdAt;
  const Ingredient(
      {required this.id,
      required this.name,
      required this.unit,
      required this.stockQuantity,
      required this.minStock,
      this.lastUnitCost,
      required this.active,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['stock_quantity'] = Variable<double>(stockQuantity);
    map['min_stock'] = Variable<double>(minStock);
    if (!nullToAbsent || lastUnitCost != null) {
      map['last_unit_cost'] = Variable<double>(lastUnitCost);
    }
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IngredientsCompanion toCompanion(bool nullToAbsent) {
    return IngredientsCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value(unit),
      stockQuantity: Value(stockQuantity),
      minStock: Value(minStock),
      lastUnitCost: lastUnitCost == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUnitCost),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory Ingredient.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ingredient(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      stockQuantity: serializer.fromJson<double>(json['stockQuantity']),
      minStock: serializer.fromJson<double>(json['minStock']),
      lastUnitCost: serializer.fromJson<double?>(json['lastUnitCost']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'stockQuantity': serializer.toJson<double>(stockQuantity),
      'minStock': serializer.toJson<double>(minStock),
      'lastUnitCost': serializer.toJson<double?>(lastUnitCost),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Ingredient copyWith(
          {int? id,
          String? name,
          String? unit,
          double? stockQuantity,
          double? minStock,
          Value<double?> lastUnitCost = const Value.absent(),
          bool? active,
          DateTime? createdAt}) =>
      Ingredient(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        minStock: minStock ?? this.minStock,
        lastUnitCost:
            lastUnitCost.present ? lastUnitCost.value : this.lastUnitCost,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
      );
  Ingredient copyWithCompanion(IngredientsCompanion data) {
    return Ingredient(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      stockQuantity: data.stockQuantity.present
          ? data.stockQuantity.value
          : this.stockQuantity,
      minStock: data.minStock.present ? data.minStock.value : this.minStock,
      lastUnitCost: data.lastUnitCost.present
          ? data.lastUnitCost.value
          : this.lastUnitCost,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ingredient(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minStock: $minStock, ')
          ..write('lastUnitCost: $lastUnitCost, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, unit, stockQuantity, minStock, lastUnitCost, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingredient &&
          other.id == this.id &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.stockQuantity == this.stockQuantity &&
          other.minStock == this.minStock &&
          other.lastUnitCost == this.lastUnitCost &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class IngredientsCompanion extends UpdateCompanion<Ingredient> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> unit;
  final Value<double> stockQuantity;
  final Value<double> minStock;
  final Value<double?> lastUnitCost;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  const IngredientsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.minStock = const Value.absent(),
    this.lastUnitCost = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IngredientsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String unit,
    this.stockQuantity = const Value.absent(),
    this.minStock = const Value.absent(),
    this.lastUnitCost = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        unit = Value(unit);
  static Insertable<Ingredient> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<double>? stockQuantity,
    Expression<double>? minStock,
    Expression<double>? lastUnitCost,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      if (minStock != null) 'min_stock': minStock,
      if (lastUnitCost != null) 'last_unit_cost': lastUnitCost,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IngredientsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? unit,
      Value<double>? stockQuantity,
      Value<double>? minStock,
      Value<double?>? lastUnitCost,
      Value<bool>? active,
      Value<DateTime>? createdAt}) {
    return IngredientsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStock: minStock ?? this.minStock,
      lastUnitCost: lastUnitCost ?? this.lastUnitCost,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (stockQuantity.present) {
      map['stock_quantity'] = Variable<double>(stockQuantity.value);
    }
    if (minStock.present) {
      map['min_stock'] = Variable<double>(minStock.value);
    }
    if (lastUnitCost.present) {
      map['last_unit_cost'] = Variable<double>(lastUnitCost.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minStock: $minStock, ')
          ..write('lastUnitCost: $lastUnitCost, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IngredientPurchasesTable extends IngredientPurchases
    with TableInfo<$IngredientPurchasesTable, IngredientPurchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientPurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _supplierIdMeta =
      const VerificationMeta('supplierId');
  @override
  late final GeneratedColumn<int> supplierId = GeneratedColumn<int>(
      'supplier_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES suppliers (id)'));
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<int> employeeId = GeneratedColumn<int>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES employees (id)'));
  static const VerificationMeta _totalCostMeta =
      const VerificationMeta('totalCost');
  @override
  late final GeneratedColumn<double> totalCost = GeneratedColumn<double>(
      'total_cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, supplierId, employeeId, totalCost, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_purchases';
  @override
  VerificationContext validateIntegrity(Insertable<IngredientPurchase> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
          _supplierIdMeta,
          supplierId.isAcceptableOrUnknown(
              data['supplier_id']!, _supplierIdMeta));
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('total_cost')) {
      context.handle(_totalCostMeta,
          totalCost.isAcceptableOrUnknown(data['total_cost']!, _totalCostMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientPurchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientPurchase(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      supplierId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}supplier_id']),
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}employee_id'])!,
      totalCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_cost'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $IngredientPurchasesTable createAlias(String alias) {
    return $IngredientPurchasesTable(attachedDatabase, alias);
  }
}

class IngredientPurchase extends DataClass
    implements Insertable<IngredientPurchase> {
  final int id;
  final int? supplierId;
  final int employeeId;
  final double totalCost;
  final String? note;
  final DateTime createdAt;
  const IngredientPurchase(
      {required this.id,
      this.supplierId,
      required this.employeeId,
      required this.totalCost,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || supplierId != null) {
      map['supplier_id'] = Variable<int>(supplierId);
    }
    map['employee_id'] = Variable<int>(employeeId);
    map['total_cost'] = Variable<double>(totalCost);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IngredientPurchasesCompanion toCompanion(bool nullToAbsent) {
    return IngredientPurchasesCompanion(
      id: Value(id),
      supplierId: supplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierId),
      employeeId: Value(employeeId),
      totalCost: Value(totalCost),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory IngredientPurchase.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientPurchase(
      id: serializer.fromJson<int>(json['id']),
      supplierId: serializer.fromJson<int?>(json['supplierId']),
      employeeId: serializer.fromJson<int>(json['employeeId']),
      totalCost: serializer.fromJson<double>(json['totalCost']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'supplierId': serializer.toJson<int?>(supplierId),
      'employeeId': serializer.toJson<int>(employeeId),
      'totalCost': serializer.toJson<double>(totalCost),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IngredientPurchase copyWith(
          {int? id,
          Value<int?> supplierId = const Value.absent(),
          int? employeeId,
          double? totalCost,
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      IngredientPurchase(
        id: id ?? this.id,
        supplierId: supplierId.present ? supplierId.value : this.supplierId,
        employeeId: employeeId ?? this.employeeId,
        totalCost: totalCost ?? this.totalCost,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  IngredientPurchase copyWithCompanion(IngredientPurchasesCompanion data) {
    return IngredientPurchase(
      id: data.id.present ? data.id.value : this.id,
      supplierId:
          data.supplierId.present ? data.supplierId.value : this.supplierId,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      totalCost: data.totalCost.present ? data.totalCost.value : this.totalCost,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientPurchase(')
          ..write('id: $id, ')
          ..write('supplierId: $supplierId, ')
          ..write('employeeId: $employeeId, ')
          ..write('totalCost: $totalCost, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, supplierId, employeeId, totalCost, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientPurchase &&
          other.id == this.id &&
          other.supplierId == this.supplierId &&
          other.employeeId == this.employeeId &&
          other.totalCost == this.totalCost &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class IngredientPurchasesCompanion extends UpdateCompanion<IngredientPurchase> {
  final Value<int> id;
  final Value<int?> supplierId;
  final Value<int> employeeId;
  final Value<double> totalCost;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const IngredientPurchasesCompanion({
    this.id = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.totalCost = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IngredientPurchasesCompanion.insert({
    this.id = const Value.absent(),
    this.supplierId = const Value.absent(),
    required int employeeId,
    this.totalCost = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : employeeId = Value(employeeId);
  static Insertable<IngredientPurchase> custom({
    Expression<int>? id,
    Expression<int>? supplierId,
    Expression<int>? employeeId,
    Expression<double>? totalCost,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supplierId != null) 'supplier_id': supplierId,
      if (employeeId != null) 'employee_id': employeeId,
      if (totalCost != null) 'total_cost': totalCost,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IngredientPurchasesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? supplierId,
      Value<int>? employeeId,
      Value<double>? totalCost,
      Value<String?>? note,
      Value<DateTime>? createdAt}) {
    return IngredientPurchasesCompanion(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      employeeId: employeeId ?? this.employeeId,
      totalCost: totalCost ?? this.totalCost,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<int>(supplierId.value);
    }
    if (employeeId.present) {
      map['employee_id'] = Variable<int>(employeeId.value);
    }
    if (totalCost.present) {
      map['total_cost'] = Variable<double>(totalCost.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientPurchasesCompanion(')
          ..write('id: $id, ')
          ..write('supplierId: $supplierId, ')
          ..write('employeeId: $employeeId, ')
          ..write('totalCost: $totalCost, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IngredientMovementsTable extends IngredientMovements
    with TableInfo<$IngredientMovementsTable, IngredientMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
      'ingredient_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES ingredients (id)'));
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<double> delta = GeneratedColumn<double>(
      'delta', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
      'order_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orders (id)'));
  static const VerificationMeta _purchaseIdMeta =
      const VerificationMeta('purchaseId');
  @override
  late final GeneratedColumn<int> purchaseId = GeneratedColumn<int>(
      'purchase_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES ingredient_purchases (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, ingredientId, delta, reason, note, orderId, purchaseId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_movements';
  @override
  VerificationContext validateIntegrity(Insertable<IngredientMovement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('delta')) {
      context.handle(
          _deltaMeta, delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta));
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    }
    if (data.containsKey('purchase_id')) {
      context.handle(
          _purchaseIdMeta,
          purchaseId.isAcceptableOrUnknown(
              data['purchase_id']!, _purchaseIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientMovement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ingredient_id'])!,
      delta: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}delta'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_id']),
      purchaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}purchase_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $IngredientMovementsTable createAlias(String alias) {
    return $IngredientMovementsTable(attachedDatabase, alias);
  }
}

class IngredientMovement extends DataClass
    implements Insertable<IngredientMovement> {
  final int id;
  final int ingredientId;
  final double delta;
  final String reason;
  final String? note;
  final int? orderId;
  final int? purchaseId;
  final DateTime createdAt;
  const IngredientMovement(
      {required this.id,
      required this.ingredientId,
      required this.delta,
      required this.reason,
      this.note,
      this.orderId,
      this.purchaseId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ingredient_id'] = Variable<int>(ingredientId);
    map['delta'] = Variable<double>(delta);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<int>(orderId);
    }
    if (!nullToAbsent || purchaseId != null) {
      map['purchase_id'] = Variable<int>(purchaseId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IngredientMovementsCompanion toCompanion(bool nullToAbsent) {
    return IngredientMovementsCompanion(
      id: Value(id),
      ingredientId: Value(ingredientId),
      delta: Value(delta),
      reason: Value(reason),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      purchaseId: purchaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseId),
      createdAt: Value(createdAt),
    );
  }

  factory IngredientMovement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientMovement(
      id: serializer.fromJson<int>(json['id']),
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
      delta: serializer.fromJson<double>(json['delta']),
      reason: serializer.fromJson<String>(json['reason']),
      note: serializer.fromJson<String?>(json['note']),
      orderId: serializer.fromJson<int?>(json['orderId']),
      purchaseId: serializer.fromJson<int?>(json['purchaseId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ingredientId': serializer.toJson<int>(ingredientId),
      'delta': serializer.toJson<double>(delta),
      'reason': serializer.toJson<String>(reason),
      'note': serializer.toJson<String?>(note),
      'orderId': serializer.toJson<int?>(orderId),
      'purchaseId': serializer.toJson<int?>(purchaseId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IngredientMovement copyWith(
          {int? id,
          int? ingredientId,
          double? delta,
          String? reason,
          Value<String?> note = const Value.absent(),
          Value<int?> orderId = const Value.absent(),
          Value<int?> purchaseId = const Value.absent(),
          DateTime? createdAt}) =>
      IngredientMovement(
        id: id ?? this.id,
        ingredientId: ingredientId ?? this.ingredientId,
        delta: delta ?? this.delta,
        reason: reason ?? this.reason,
        note: note.present ? note.value : this.note,
        orderId: orderId.present ? orderId.value : this.orderId,
        purchaseId: purchaseId.present ? purchaseId.value : this.purchaseId,
        createdAt: createdAt ?? this.createdAt,
      );
  IngredientMovement copyWithCompanion(IngredientMovementsCompanion data) {
    return IngredientMovement(
      id: data.id.present ? data.id.value : this.id,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      delta: data.delta.present ? data.delta.value : this.delta,
      reason: data.reason.present ? data.reason.value : this.reason,
      note: data.note.present ? data.note.value : this.note,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      purchaseId:
          data.purchaseId.present ? data.purchaseId.value : this.purchaseId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientMovement(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('orderId: $orderId, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, ingredientId, delta, reason, note, orderId, purchaseId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientMovement &&
          other.id == this.id &&
          other.ingredientId == this.ingredientId &&
          other.delta == this.delta &&
          other.reason == this.reason &&
          other.note == this.note &&
          other.orderId == this.orderId &&
          other.purchaseId == this.purchaseId &&
          other.createdAt == this.createdAt);
}

class IngredientMovementsCompanion extends UpdateCompanion<IngredientMovement> {
  final Value<int> id;
  final Value<int> ingredientId;
  final Value<double> delta;
  final Value<String> reason;
  final Value<String?> note;
  final Value<int?> orderId;
  final Value<int?> purchaseId;
  final Value<DateTime> createdAt;
  const IngredientMovementsCompanion({
    this.id = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.delta = const Value.absent(),
    this.reason = const Value.absent(),
    this.note = const Value.absent(),
    this.orderId = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IngredientMovementsCompanion.insert({
    this.id = const Value.absent(),
    required int ingredientId,
    required double delta,
    required String reason,
    this.note = const Value.absent(),
    this.orderId = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : ingredientId = Value(ingredientId),
        delta = Value(delta),
        reason = Value(reason);
  static Insertable<IngredientMovement> custom({
    Expression<int>? id,
    Expression<int>? ingredientId,
    Expression<double>? delta,
    Expression<String>? reason,
    Expression<String>? note,
    Expression<int>? orderId,
    Expression<int>? purchaseId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (delta != null) 'delta': delta,
      if (reason != null) 'reason': reason,
      if (note != null) 'note': note,
      if (orderId != null) 'order_id': orderId,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IngredientMovementsCompanion copyWith(
      {Value<int>? id,
      Value<int>? ingredientId,
      Value<double>? delta,
      Value<String>? reason,
      Value<String?>? note,
      Value<int?>? orderId,
      Value<int?>? purchaseId,
      Value<DateTime>? createdAt}) {
    return IngredientMovementsCompanion(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      delta: delta ?? this.delta,
      reason: reason ?? this.reason,
      note: note ?? this.note,
      orderId: orderId ?? this.orderId,
      purchaseId: purchaseId ?? this.purchaseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (delta.present) {
      map['delta'] = Variable<double>(delta.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (purchaseId.present) {
      map['purchase_id'] = Variable<int>(purchaseId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientMovementsCompanion(')
          ..write('id: $id, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('note: $note, ')
          ..write('orderId: $orderId, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IngredientPurchaseItemsTable extends IngredientPurchaseItems
    with TableInfo<$IngredientPurchaseItemsTable, IngredientPurchaseItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IngredientPurchaseItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _purchaseIdMeta =
      const VerificationMeta('purchaseId');
  @override
  late final GeneratedColumn<int> purchaseId = GeneratedColumn<int>(
      'purchase_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES ingredient_purchases (id)'));
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
      'ingredient_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES ingredients (id)'));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitCostMeta =
      const VerificationMeta('unitCost');
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
      'unit_cost', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, purchaseId, ingredientId, quantity, unitCost];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ingredient_purchase_items';
  @override
  VerificationContext validateIntegrity(
      Insertable<IngredientPurchaseItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('purchase_id')) {
      context.handle(
          _purchaseIdMeta,
          purchaseId.isAcceptableOrUnknown(
              data['purchase_id']!, _purchaseIdMeta));
    } else if (isInserting) {
      context.missing(_purchaseIdMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_cost')) {
      context.handle(_unitCostMeta,
          unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta));
    } else if (isInserting) {
      context.missing(_unitCostMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IngredientPurchaseItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IngredientPurchaseItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      purchaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}purchase_id'])!,
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ingredient_id'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      unitCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_cost'])!,
    );
  }

  @override
  $IngredientPurchaseItemsTable createAlias(String alias) {
    return $IngredientPurchaseItemsTable(attachedDatabase, alias);
  }
}

class IngredientPurchaseItem extends DataClass
    implements Insertable<IngredientPurchaseItem> {
  final int id;
  final int purchaseId;
  final int ingredientId;
  final double quantity;
  final double unitCost;
  const IngredientPurchaseItem(
      {required this.id,
      required this.purchaseId,
      required this.ingredientId,
      required this.quantity,
      required this.unitCost});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['purchase_id'] = Variable<int>(purchaseId);
    map['ingredient_id'] = Variable<int>(ingredientId);
    map['quantity'] = Variable<double>(quantity);
    map['unit_cost'] = Variable<double>(unitCost);
    return map;
  }

  IngredientPurchaseItemsCompanion toCompanion(bool nullToAbsent) {
    return IngredientPurchaseItemsCompanion(
      id: Value(id),
      purchaseId: Value(purchaseId),
      ingredientId: Value(ingredientId),
      quantity: Value(quantity),
      unitCost: Value(unitCost),
    );
  }

  factory IngredientPurchaseItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IngredientPurchaseItem(
      id: serializer.fromJson<int>(json['id']),
      purchaseId: serializer.fromJson<int>(json['purchaseId']),
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitCost: serializer.fromJson<double>(json['unitCost']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'purchaseId': serializer.toJson<int>(purchaseId),
      'ingredientId': serializer.toJson<int>(ingredientId),
      'quantity': serializer.toJson<double>(quantity),
      'unitCost': serializer.toJson<double>(unitCost),
    };
  }

  IngredientPurchaseItem copyWith(
          {int? id,
          int? purchaseId,
          int? ingredientId,
          double? quantity,
          double? unitCost}) =>
      IngredientPurchaseItem(
        id: id ?? this.id,
        purchaseId: purchaseId ?? this.purchaseId,
        ingredientId: ingredientId ?? this.ingredientId,
        quantity: quantity ?? this.quantity,
        unitCost: unitCost ?? this.unitCost,
      );
  IngredientPurchaseItem copyWithCompanion(
      IngredientPurchaseItemsCompanion data) {
    return IngredientPurchaseItem(
      id: data.id.present ? data.id.value : this.id,
      purchaseId:
          data.purchaseId.present ? data.purchaseId.value : this.purchaseId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IngredientPurchaseItem(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, purchaseId, ingredientId, quantity, unitCost);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IngredientPurchaseItem &&
          other.id == this.id &&
          other.purchaseId == this.purchaseId &&
          other.ingredientId == this.ingredientId &&
          other.quantity == this.quantity &&
          other.unitCost == this.unitCost);
}

class IngredientPurchaseItemsCompanion
    extends UpdateCompanion<IngredientPurchaseItem> {
  final Value<int> id;
  final Value<int> purchaseId;
  final Value<int> ingredientId;
  final Value<double> quantity;
  final Value<double> unitCost;
  const IngredientPurchaseItemsCompanion({
    this.id = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCost = const Value.absent(),
  });
  IngredientPurchaseItemsCompanion.insert({
    this.id = const Value.absent(),
    required int purchaseId,
    required int ingredientId,
    required double quantity,
    required double unitCost,
  })  : purchaseId = Value(purchaseId),
        ingredientId = Value(ingredientId),
        quantity = Value(quantity),
        unitCost = Value(unitCost);
  static Insertable<IngredientPurchaseItem> custom({
    Expression<int>? id,
    Expression<int>? purchaseId,
    Expression<int>? ingredientId,
    Expression<double>? quantity,
    Expression<double>? unitCost,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (quantity != null) 'quantity': quantity,
      if (unitCost != null) 'unit_cost': unitCost,
    });
  }

  IngredientPurchaseItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? purchaseId,
      Value<int>? ingredientId,
      Value<double>? quantity,
      Value<double>? unitCost}) {
    return IngredientPurchaseItemsCompanion(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      ingredientId: ingredientId ?? this.ingredientId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (purchaseId.present) {
      map['purchase_id'] = Variable<int>(purchaseId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IngredientPurchaseItemsCompanion(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost')
          ..write(')'))
        .toString();
  }
}

class $RecipeItemsTable extends RecipeItems
    with TableInfo<$RecipeItemsTable, RecipeItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
      'product_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES products (id)'));
  static const VerificationMeta _ingredientIdMeta =
      const VerificationMeta('ingredientId');
  @override
  late final GeneratedColumn<int> ingredientId = GeneratedColumn<int>(
      'ingredient_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES ingredients (id)'));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, productId, ingredientId, quantity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_items';
  @override
  VerificationContext validateIntegrity(Insertable<RecipeItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('ingredient_id')) {
      context.handle(
          _ingredientIdMeta,
          ingredientId.isAcceptableOrUnknown(
              data['ingredient_id']!, _ingredientIdMeta));
    } else if (isInserting) {
      context.missing(_ingredientIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}product_id'])!,
      ingredientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ingredient_id'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
    );
  }

  @override
  $RecipeItemsTable createAlias(String alias) {
    return $RecipeItemsTable(attachedDatabase, alias);
  }
}

class RecipeItem extends DataClass implements Insertable<RecipeItem> {
  final int id;
  final int productId;
  final int ingredientId;
  final double quantity;
  const RecipeItem(
      {required this.id,
      required this.productId,
      required this.ingredientId,
      required this.quantity});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['ingredient_id'] = Variable<int>(ingredientId);
    map['quantity'] = Variable<double>(quantity);
    return map;
  }

  RecipeItemsCompanion toCompanion(bool nullToAbsent) {
    return RecipeItemsCompanion(
      id: Value(id),
      productId: Value(productId),
      ingredientId: Value(ingredientId),
      quantity: Value(quantity),
    );
  }

  factory RecipeItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeItem(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      ingredientId: serializer.fromJson<int>(json['ingredientId']),
      quantity: serializer.fromJson<double>(json['quantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'ingredientId': serializer.toJson<int>(ingredientId),
      'quantity': serializer.toJson<double>(quantity),
    };
  }

  RecipeItem copyWith(
          {int? id, int? productId, int? ingredientId, double? quantity}) =>
      RecipeItem(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        ingredientId: ingredientId ?? this.ingredientId,
        quantity: quantity ?? this.quantity,
      );
  RecipeItem copyWithCompanion(RecipeItemsCompanion data) {
    return RecipeItem(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      ingredientId: data.ingredientId.present
          ? data.ingredientId.value
          : this.ingredientId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeItem(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, ingredientId, quantity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeItem &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.ingredientId == this.ingredientId &&
          other.quantity == this.quantity);
}

class RecipeItemsCompanion extends UpdateCompanion<RecipeItem> {
  final Value<int> id;
  final Value<int> productId;
  final Value<int> ingredientId;
  final Value<double> quantity;
  const RecipeItemsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.ingredientId = const Value.absent(),
    this.quantity = const Value.absent(),
  });
  RecipeItemsCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required int ingredientId,
    required double quantity,
  })  : productId = Value(productId),
        ingredientId = Value(ingredientId),
        quantity = Value(quantity);
  static Insertable<RecipeItem> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<int>? ingredientId,
    Expression<double>? quantity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (ingredientId != null) 'ingredient_id': ingredientId,
      if (quantity != null) 'quantity': quantity,
    });
  }

  RecipeItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? productId,
      Value<int>? ingredientId,
      Value<double>? quantity}) {
    return RecipeItemsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      ingredientId: ingredientId ?? this.ingredientId,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (ingredientId.present) {
      map['ingredient_id'] = Variable<int>(ingredientId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeItemsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('ingredientId: $ingredientId, ')
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }
}

class $DeliveryZonesTable extends DeliveryZones
    with TableInfo<$DeliveryZonesTable, DeliveryZone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliveryZonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _feeMeta = const VerificationMeta('fee');
  @override
  late final GeneratedColumn<double> fee = GeneratedColumn<double>(
      'fee', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [id, name, fee, active];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_zones';
  @override
  VerificationContext validateIntegrity(Insertable<DeliveryZone> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('fee')) {
      context.handle(
          _feeMeta, fee.isAcceptableOrUnknown(data['fee']!, _feeMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeliveryZone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryZone(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      fee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fee'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
    );
  }

  @override
  $DeliveryZonesTable createAlias(String alias) {
    return $DeliveryZonesTable(attachedDatabase, alias);
  }
}

class DeliveryZone extends DataClass implements Insertable<DeliveryZone> {
  final int id;
  final String name;
  final double fee;
  final bool active;
  const DeliveryZone(
      {required this.id,
      required this.name,
      required this.fee,
      required this.active});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['fee'] = Variable<double>(fee);
    map['active'] = Variable<bool>(active);
    return map;
  }

  DeliveryZonesCompanion toCompanion(bool nullToAbsent) {
    return DeliveryZonesCompanion(
      id: Value(id),
      name: Value(name),
      fee: Value(fee),
      active: Value(active),
    );
  }

  factory DeliveryZone.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryZone(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      fee: serializer.fromJson<double>(json['fee']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'fee': serializer.toJson<double>(fee),
      'active': serializer.toJson<bool>(active),
    };
  }

  DeliveryZone copyWith({int? id, String? name, double? fee, bool? active}) =>
      DeliveryZone(
        id: id ?? this.id,
        name: name ?? this.name,
        fee: fee ?? this.fee,
        active: active ?? this.active,
      );
  DeliveryZone copyWithCompanion(DeliveryZonesCompanion data) {
    return DeliveryZone(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      fee: data.fee.present ? data.fee.value : this.fee,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryZone(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fee: $fee, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, fee, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryZone &&
          other.id == this.id &&
          other.name == this.name &&
          other.fee == this.fee &&
          other.active == this.active);
}

class DeliveryZonesCompanion extends UpdateCompanion<DeliveryZone> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> fee;
  final Value<bool> active;
  const DeliveryZonesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.fee = const Value.absent(),
    this.active = const Value.absent(),
  });
  DeliveryZonesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.fee = const Value.absent(),
    this.active = const Value.absent(),
  }) : name = Value(name);
  static Insertable<DeliveryZone> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? fee,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (fee != null) 'fee': fee,
      if (active != null) 'active': active,
    });
  }

  DeliveryZonesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? fee,
      Value<bool>? active}) {
    return DeliveryZonesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      fee: fee ?? this.fee,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fee.present) {
      map['fee'] = Variable<double>(fee.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryZonesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fee: $fee, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $FiscalDocsTable extends FiscalDocs
    with TableInfo<$FiscalDocsTable, FiscalDoc> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FiscalDocsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _orderIdMeta =
      const VerificationMeta('orderId');
  @override
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
      'order_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES orders (id)'));
  static const VerificationMeta _receptorRfcMeta =
      const VerificationMeta('receptorRfc');
  @override
  late final GeneratedColumn<String> receptorRfc = GeneratedColumn<String>(
      'receptor_rfc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receptorRazonSocialMeta =
      const VerificationMeta('receptorRazonSocial');
  @override
  late final GeneratedColumn<String> receptorRazonSocial =
      GeneratedColumn<String>('receptor_razon_social', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receptorCpFiscalMeta =
      const VerificationMeta('receptorCpFiscal');
  @override
  late final GeneratedColumn<String> receptorCpFiscal = GeneratedColumn<String>(
      'receptor_cp_fiscal', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receptorRegimenMeta =
      const VerificationMeta('receptorRegimen');
  @override
  late final GeneratedColumn<String> receptorRegimen = GeneratedColumn<String>(
      'receptor_regimen', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receptorUsoCfdiMeta =
      const VerificationMeta('receptorUsoCfdi');
  @override
  late final GeneratedColumn<String> receptorUsoCfdi = GeneratedColumn<String>(
      'receptor_uso_cfdi', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
      'tipo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
      'estado', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pendiente'));
  static const VerificationMeta _periodoRefMeta =
      const VerificationMeta('periodoRef');
  @override
  late final GeneratedColumn<String> periodoRef = GeneratedColumn<String>(
      'periodo_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _exportedAtMeta =
      const VerificationMeta('exportedAt');
  @override
  late final GeneratedColumn<DateTime> exportedAt = GeneratedColumn<DateTime>(
      'exported_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        orderId,
        receptorRfc,
        receptorRazonSocial,
        receptorCpFiscal,
        receptorRegimen,
        receptorUsoCfdi,
        tipo,
        estado,
        periodoRef,
        exportedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fiscal_docs';
  @override
  VerificationContext validateIntegrity(Insertable<FiscalDoc> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_id')) {
      context.handle(_orderIdMeta,
          orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta));
    }
    if (data.containsKey('receptor_rfc')) {
      context.handle(
          _receptorRfcMeta,
          receptorRfc.isAcceptableOrUnknown(
              data['receptor_rfc']!, _receptorRfcMeta));
    }
    if (data.containsKey('receptor_razon_social')) {
      context.handle(
          _receptorRazonSocialMeta,
          receptorRazonSocial.isAcceptableOrUnknown(
              data['receptor_razon_social']!, _receptorRazonSocialMeta));
    }
    if (data.containsKey('receptor_cp_fiscal')) {
      context.handle(
          _receptorCpFiscalMeta,
          receptorCpFiscal.isAcceptableOrUnknown(
              data['receptor_cp_fiscal']!, _receptorCpFiscalMeta));
    }
    if (data.containsKey('receptor_regimen')) {
      context.handle(
          _receptorRegimenMeta,
          receptorRegimen.isAcceptableOrUnknown(
              data['receptor_regimen']!, _receptorRegimenMeta));
    }
    if (data.containsKey('receptor_uso_cfdi')) {
      context.handle(
          _receptorUsoCfdiMeta,
          receptorUsoCfdi.isAcceptableOrUnknown(
              data['receptor_uso_cfdi']!, _receptorUsoCfdiMeta));
    }
    if (data.containsKey('tipo')) {
      context.handle(
          _tipoMeta, tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta));
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('estado')) {
      context.handle(_estadoMeta,
          estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta));
    }
    if (data.containsKey('periodo_ref')) {
      context.handle(
          _periodoRefMeta,
          periodoRef.isAcceptableOrUnknown(
              data['periodo_ref']!, _periodoRefMeta));
    }
    if (data.containsKey('exported_at')) {
      context.handle(
          _exportedAtMeta,
          exportedAt.isAcceptableOrUnknown(
              data['exported_at']!, _exportedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FiscalDoc map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FiscalDoc(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      orderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_id']),
      receptorRfc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receptor_rfc']),
      receptorRazonSocial: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}receptor_razon_social']),
      receptorCpFiscal: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}receptor_cp_fiscal']),
      receptorRegimen: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}receptor_regimen']),
      receptorUsoCfdi: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}receptor_uso_cfdi']),
      tipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo'])!,
      estado: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}estado'])!,
      periodoRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}periodo_ref']),
      exportedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}exported_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FiscalDocsTable createAlias(String alias) {
    return $FiscalDocsTable(attachedDatabase, alias);
  }
}

class FiscalDoc extends DataClass implements Insertable<FiscalDoc> {
  final int id;
  final int? orderId;
  final String? receptorRfc;
  final String? receptorRazonSocial;
  final String? receptorCpFiscal;
  final String? receptorRegimen;
  final String? receptorUsoCfdi;
  final String tipo;
  final String estado;
  final String? periodoRef;
  final DateTime? exportedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FiscalDoc(
      {required this.id,
      this.orderId,
      this.receptorRfc,
      this.receptorRazonSocial,
      this.receptorCpFiscal,
      this.receptorRegimen,
      this.receptorUsoCfdi,
      required this.tipo,
      required this.estado,
      this.periodoRef,
      this.exportedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || orderId != null) {
      map['order_id'] = Variable<int>(orderId);
    }
    if (!nullToAbsent || receptorRfc != null) {
      map['receptor_rfc'] = Variable<String>(receptorRfc);
    }
    if (!nullToAbsent || receptorRazonSocial != null) {
      map['receptor_razon_social'] = Variable<String>(receptorRazonSocial);
    }
    if (!nullToAbsent || receptorCpFiscal != null) {
      map['receptor_cp_fiscal'] = Variable<String>(receptorCpFiscal);
    }
    if (!nullToAbsent || receptorRegimen != null) {
      map['receptor_regimen'] = Variable<String>(receptorRegimen);
    }
    if (!nullToAbsent || receptorUsoCfdi != null) {
      map['receptor_uso_cfdi'] = Variable<String>(receptorUsoCfdi);
    }
    map['tipo'] = Variable<String>(tipo);
    map['estado'] = Variable<String>(estado);
    if (!nullToAbsent || periodoRef != null) {
      map['periodo_ref'] = Variable<String>(periodoRef);
    }
    if (!nullToAbsent || exportedAt != null) {
      map['exported_at'] = Variable<DateTime>(exportedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FiscalDocsCompanion toCompanion(bool nullToAbsent) {
    return FiscalDocsCompanion(
      id: Value(id),
      orderId: orderId == null && nullToAbsent
          ? const Value.absent()
          : Value(orderId),
      receptorRfc: receptorRfc == null && nullToAbsent
          ? const Value.absent()
          : Value(receptorRfc),
      receptorRazonSocial: receptorRazonSocial == null && nullToAbsent
          ? const Value.absent()
          : Value(receptorRazonSocial),
      receptorCpFiscal: receptorCpFiscal == null && nullToAbsent
          ? const Value.absent()
          : Value(receptorCpFiscal),
      receptorRegimen: receptorRegimen == null && nullToAbsent
          ? const Value.absent()
          : Value(receptorRegimen),
      receptorUsoCfdi: receptorUsoCfdi == null && nullToAbsent
          ? const Value.absent()
          : Value(receptorUsoCfdi),
      tipo: Value(tipo),
      estado: Value(estado),
      periodoRef: periodoRef == null && nullToAbsent
          ? const Value.absent()
          : Value(periodoRef),
      exportedAt: exportedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(exportedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FiscalDoc.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FiscalDoc(
      id: serializer.fromJson<int>(json['id']),
      orderId: serializer.fromJson<int?>(json['orderId']),
      receptorRfc: serializer.fromJson<String?>(json['receptorRfc']),
      receptorRazonSocial:
          serializer.fromJson<String?>(json['receptorRazonSocial']),
      receptorCpFiscal: serializer.fromJson<String?>(json['receptorCpFiscal']),
      receptorRegimen: serializer.fromJson<String?>(json['receptorRegimen']),
      receptorUsoCfdi: serializer.fromJson<String?>(json['receptorUsoCfdi']),
      tipo: serializer.fromJson<String>(json['tipo']),
      estado: serializer.fromJson<String>(json['estado']),
      periodoRef: serializer.fromJson<String?>(json['periodoRef']),
      exportedAt: serializer.fromJson<DateTime?>(json['exportedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderId': serializer.toJson<int?>(orderId),
      'receptorRfc': serializer.toJson<String?>(receptorRfc),
      'receptorRazonSocial': serializer.toJson<String?>(receptorRazonSocial),
      'receptorCpFiscal': serializer.toJson<String?>(receptorCpFiscal),
      'receptorRegimen': serializer.toJson<String?>(receptorRegimen),
      'receptorUsoCfdi': serializer.toJson<String?>(receptorUsoCfdi),
      'tipo': serializer.toJson<String>(tipo),
      'estado': serializer.toJson<String>(estado),
      'periodoRef': serializer.toJson<String?>(periodoRef),
      'exportedAt': serializer.toJson<DateTime?>(exportedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FiscalDoc copyWith(
          {int? id,
          Value<int?> orderId = const Value.absent(),
          Value<String?> receptorRfc = const Value.absent(),
          Value<String?> receptorRazonSocial = const Value.absent(),
          Value<String?> receptorCpFiscal = const Value.absent(),
          Value<String?> receptorRegimen = const Value.absent(),
          Value<String?> receptorUsoCfdi = const Value.absent(),
          String? tipo,
          String? estado,
          Value<String?> periodoRef = const Value.absent(),
          Value<DateTime?> exportedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      FiscalDoc(
        id: id ?? this.id,
        orderId: orderId.present ? orderId.value : this.orderId,
        receptorRfc: receptorRfc.present ? receptorRfc.value : this.receptorRfc,
        receptorRazonSocial: receptorRazonSocial.present
            ? receptorRazonSocial.value
            : this.receptorRazonSocial,
        receptorCpFiscal: receptorCpFiscal.present
            ? receptorCpFiscal.value
            : this.receptorCpFiscal,
        receptorRegimen: receptorRegimen.present
            ? receptorRegimen.value
            : this.receptorRegimen,
        receptorUsoCfdi: receptorUsoCfdi.present
            ? receptorUsoCfdi.value
            : this.receptorUsoCfdi,
        tipo: tipo ?? this.tipo,
        estado: estado ?? this.estado,
        periodoRef: periodoRef.present ? periodoRef.value : this.periodoRef,
        exportedAt: exportedAt.present ? exportedAt.value : this.exportedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FiscalDoc copyWithCompanion(FiscalDocsCompanion data) {
    return FiscalDoc(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      receptorRfc:
          data.receptorRfc.present ? data.receptorRfc.value : this.receptorRfc,
      receptorRazonSocial: data.receptorRazonSocial.present
          ? data.receptorRazonSocial.value
          : this.receptorRazonSocial,
      receptorCpFiscal: data.receptorCpFiscal.present
          ? data.receptorCpFiscal.value
          : this.receptorCpFiscal,
      receptorRegimen: data.receptorRegimen.present
          ? data.receptorRegimen.value
          : this.receptorRegimen,
      receptorUsoCfdi: data.receptorUsoCfdi.present
          ? data.receptorUsoCfdi.value
          : this.receptorUsoCfdi,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      estado: data.estado.present ? data.estado.value : this.estado,
      periodoRef:
          data.periodoRef.present ? data.periodoRef.value : this.periodoRef,
      exportedAt:
          data.exportedAt.present ? data.exportedAt.value : this.exportedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FiscalDoc(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('receptorRfc: $receptorRfc, ')
          ..write('receptorRazonSocial: $receptorRazonSocial, ')
          ..write('receptorCpFiscal: $receptorCpFiscal, ')
          ..write('receptorRegimen: $receptorRegimen, ')
          ..write('receptorUsoCfdi: $receptorUsoCfdi, ')
          ..write('tipo: $tipo, ')
          ..write('estado: $estado, ')
          ..write('periodoRef: $periodoRef, ')
          ..write('exportedAt: $exportedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      orderId,
      receptorRfc,
      receptorRazonSocial,
      receptorCpFiscal,
      receptorRegimen,
      receptorUsoCfdi,
      tipo,
      estado,
      periodoRef,
      exportedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiscalDoc &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.receptorRfc == this.receptorRfc &&
          other.receptorRazonSocial == this.receptorRazonSocial &&
          other.receptorCpFiscal == this.receptorCpFiscal &&
          other.receptorRegimen == this.receptorRegimen &&
          other.receptorUsoCfdi == this.receptorUsoCfdi &&
          other.tipo == this.tipo &&
          other.estado == this.estado &&
          other.periodoRef == this.periodoRef &&
          other.exportedAt == this.exportedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FiscalDocsCompanion extends UpdateCompanion<FiscalDoc> {
  final Value<int> id;
  final Value<int?> orderId;
  final Value<String?> receptorRfc;
  final Value<String?> receptorRazonSocial;
  final Value<String?> receptorCpFiscal;
  final Value<String?> receptorRegimen;
  final Value<String?> receptorUsoCfdi;
  final Value<String> tipo;
  final Value<String> estado;
  final Value<String?> periodoRef;
  final Value<DateTime?> exportedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FiscalDocsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.receptorRfc = const Value.absent(),
    this.receptorRazonSocial = const Value.absent(),
    this.receptorCpFiscal = const Value.absent(),
    this.receptorRegimen = const Value.absent(),
    this.receptorUsoCfdi = const Value.absent(),
    this.tipo = const Value.absent(),
    this.estado = const Value.absent(),
    this.periodoRef = const Value.absent(),
    this.exportedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FiscalDocsCompanion.insert({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.receptorRfc = const Value.absent(),
    this.receptorRazonSocial = const Value.absent(),
    this.receptorCpFiscal = const Value.absent(),
    this.receptorRegimen = const Value.absent(),
    this.receptorUsoCfdi = const Value.absent(),
    required String tipo,
    this.estado = const Value.absent(),
    this.periodoRef = const Value.absent(),
    this.exportedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : tipo = Value(tipo);
  static Insertable<FiscalDoc> custom({
    Expression<int>? id,
    Expression<int>? orderId,
    Expression<String>? receptorRfc,
    Expression<String>? receptorRazonSocial,
    Expression<String>? receptorCpFiscal,
    Expression<String>? receptorRegimen,
    Expression<String>? receptorUsoCfdi,
    Expression<String>? tipo,
    Expression<String>? estado,
    Expression<String>? periodoRef,
    Expression<DateTime>? exportedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (receptorRfc != null) 'receptor_rfc': receptorRfc,
      if (receptorRazonSocial != null)
        'receptor_razon_social': receptorRazonSocial,
      if (receptorCpFiscal != null) 'receptor_cp_fiscal': receptorCpFiscal,
      if (receptorRegimen != null) 'receptor_regimen': receptorRegimen,
      if (receptorUsoCfdi != null) 'receptor_uso_cfdi': receptorUsoCfdi,
      if (tipo != null) 'tipo': tipo,
      if (estado != null) 'estado': estado,
      if (periodoRef != null) 'periodo_ref': periodoRef,
      if (exportedAt != null) 'exported_at': exportedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FiscalDocsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? orderId,
      Value<String?>? receptorRfc,
      Value<String?>? receptorRazonSocial,
      Value<String?>? receptorCpFiscal,
      Value<String?>? receptorRegimen,
      Value<String?>? receptorUsoCfdi,
      Value<String>? tipo,
      Value<String>? estado,
      Value<String?>? periodoRef,
      Value<DateTime?>? exportedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return FiscalDocsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      receptorRfc: receptorRfc ?? this.receptorRfc,
      receptorRazonSocial: receptorRazonSocial ?? this.receptorRazonSocial,
      receptorCpFiscal: receptorCpFiscal ?? this.receptorCpFiscal,
      receptorRegimen: receptorRegimen ?? this.receptorRegimen,
      receptorUsoCfdi: receptorUsoCfdi ?? this.receptorUsoCfdi,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      periodoRef: periodoRef ?? this.periodoRef,
      exportedAt: exportedAt ?? this.exportedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (receptorRfc.present) {
      map['receptor_rfc'] = Variable<String>(receptorRfc.value);
    }
    if (receptorRazonSocial.present) {
      map['receptor_razon_social'] =
          Variable<String>(receptorRazonSocial.value);
    }
    if (receptorCpFiscal.present) {
      map['receptor_cp_fiscal'] = Variable<String>(receptorCpFiscal.value);
    }
    if (receptorRegimen.present) {
      map['receptor_regimen'] = Variable<String>(receptorRegimen.value);
    }
    if (receptorUsoCfdi.present) {
      map['receptor_uso_cfdi'] = Variable<String>(receptorUsoCfdi.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (periodoRef.present) {
      map['periodo_ref'] = Variable<String>(periodoRef.value);
    }
    if (exportedAt.present) {
      map['exported_at'] = Variable<DateTime>(exportedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiscalDocsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('receptorRfc: $receptorRfc, ')
          ..write('receptorRazonSocial: $receptorRazonSocial, ')
          ..write('receptorCpFiscal: $receptorCpFiscal, ')
          ..write('receptorRegimen: $receptorRegimen, ')
          ..write('receptorUsoCfdi: $receptorUsoCfdi, ')
          ..write('tipo: $tipo, ')
          ..write('estado: $estado, ')
          ..write('periodoRef: $periodoRef, ')
          ..write('exportedAt: $exportedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FiscalDocItemsTable extends FiscalDocItems
    with TableInfo<$FiscalDocItemsTable, FiscalDocItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FiscalDocItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _fiscalDocIdMeta =
      const VerificationMeta('fiscalDocId');
  @override
  late final GeneratedColumn<int> fiscalDocId = GeneratedColumn<int>(
      'fiscal_doc_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES fiscal_docs (id)'));
  static const VerificationMeta _claveProdServMeta =
      const VerificationMeta('claveProdServ');
  @override
  late final GeneratedColumn<String> claveProdServ = GeneratedColumn<String>(
      'clave_prod_serv', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _claveUnidadMeta =
      const VerificationMeta('claveUnidad');
  @override
  late final GeneratedColumn<String> claveUnidad = GeneratedColumn<String>(
      'clave_unidad', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descripcionMeta =
      const VerificationMeta('descripcion');
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
      'descripcion', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cantidadMeta =
      const VerificationMeta('cantidad');
  @override
  late final GeneratedColumn<double> cantidad = GeneratedColumn<double>(
      'cantidad', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _valorUnitarioMeta =
      const VerificationMeta('valorUnitario');
  @override
  late final GeneratedColumn<double> valorUnitario = GeneratedColumn<double>(
      'valor_unitario', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _importeMeta =
      const VerificationMeta('importe');
  @override
  late final GeneratedColumn<double> importe = GeneratedColumn<double>(
      'importe', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _descuentoMeta =
      const VerificationMeta('descuento');
  @override
  late final GeneratedColumn<double> descuento = GeneratedColumn<double>(
      'descuento', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _objetoImpMeta =
      const VerificationMeta('objetoImp');
  @override
  late final GeneratedColumn<String> objetoImp = GeneratedColumn<String>(
      'objeto_imp', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _baseMeta = const VerificationMeta('base');
  @override
  late final GeneratedColumn<double> base = GeneratedColumn<double>(
      'base', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _tasaIvaMeta =
      const VerificationMeta('tasaIva');
  @override
  late final GeneratedColumn<double> tasaIva = GeneratedColumn<double>(
      'tasa_iva', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _importeIvaMeta =
      const VerificationMeta('importeIva');
  @override
  late final GeneratedColumn<double> importeIva = GeneratedColumn<double>(
      'importe_iva', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fiscalDocId,
        claveProdServ,
        claveUnidad,
        descripcion,
        cantidad,
        valorUnitario,
        importe,
        descuento,
        objetoImp,
        base,
        tasaIva,
        importeIva
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fiscal_doc_items';
  @override
  VerificationContext validateIntegrity(Insertable<FiscalDocItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fiscal_doc_id')) {
      context.handle(
          _fiscalDocIdMeta,
          fiscalDocId.isAcceptableOrUnknown(
              data['fiscal_doc_id']!, _fiscalDocIdMeta));
    } else if (isInserting) {
      context.missing(_fiscalDocIdMeta);
    }
    if (data.containsKey('clave_prod_serv')) {
      context.handle(
          _claveProdServMeta,
          claveProdServ.isAcceptableOrUnknown(
              data['clave_prod_serv']!, _claveProdServMeta));
    }
    if (data.containsKey('clave_unidad')) {
      context.handle(
          _claveUnidadMeta,
          claveUnidad.isAcceptableOrUnknown(
              data['clave_unidad']!, _claveUnidadMeta));
    }
    if (data.containsKey('descripcion')) {
      context.handle(
          _descripcionMeta,
          descripcion.isAcceptableOrUnknown(
              data['descripcion']!, _descripcionMeta));
    } else if (isInserting) {
      context.missing(_descripcionMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(_cantidadMeta,
          cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta));
    } else if (isInserting) {
      context.missing(_cantidadMeta);
    }
    if (data.containsKey('valor_unitario')) {
      context.handle(
          _valorUnitarioMeta,
          valorUnitario.isAcceptableOrUnknown(
              data['valor_unitario']!, _valorUnitarioMeta));
    } else if (isInserting) {
      context.missing(_valorUnitarioMeta);
    }
    if (data.containsKey('importe')) {
      context.handle(_importeMeta,
          importe.isAcceptableOrUnknown(data['importe']!, _importeMeta));
    } else if (isInserting) {
      context.missing(_importeMeta);
    }
    if (data.containsKey('descuento')) {
      context.handle(_descuentoMeta,
          descuento.isAcceptableOrUnknown(data['descuento']!, _descuentoMeta));
    }
    if (data.containsKey('objeto_imp')) {
      context.handle(_objetoImpMeta,
          objetoImp.isAcceptableOrUnknown(data['objeto_imp']!, _objetoImpMeta));
    }
    if (data.containsKey('base')) {
      context.handle(
          _baseMeta, base.isAcceptableOrUnknown(data['base']!, _baseMeta));
    } else if (isInserting) {
      context.missing(_baseMeta);
    }
    if (data.containsKey('tasa_iva')) {
      context.handle(_tasaIvaMeta,
          tasaIva.isAcceptableOrUnknown(data['tasa_iva']!, _tasaIvaMeta));
    }
    if (data.containsKey('importe_iva')) {
      context.handle(
          _importeIvaMeta,
          importeIva.isAcceptableOrUnknown(
              data['importe_iva']!, _importeIvaMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FiscalDocItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FiscalDocItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      fiscalDocId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fiscal_doc_id'])!,
      claveProdServ: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}clave_prod_serv']),
      claveUnidad: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}clave_unidad']),
      descripcion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descripcion'])!,
      cantidad: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cantidad'])!,
      valorUnitario: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}valor_unitario'])!,
      importe: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}importe'])!,
      descuento: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}descuento'])!,
      objetoImp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}objeto_imp']),
      base: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}base'])!,
      tasaIva: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tasa_iva'])!,
      importeIva: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}importe_iva'])!,
    );
  }

  @override
  $FiscalDocItemsTable createAlias(String alias) {
    return $FiscalDocItemsTable(attachedDatabase, alias);
  }
}

class FiscalDocItem extends DataClass implements Insertable<FiscalDocItem> {
  final int id;
  final int fiscalDocId;
  final String? claveProdServ;
  final String? claveUnidad;
  final String descripcion;
  final double cantidad;
  final double valorUnitario;
  final double importe;
  final double descuento;
  final String? objetoImp;
  final double base;
  final double tasaIva;
  final double importeIva;
  const FiscalDocItem(
      {required this.id,
      required this.fiscalDocId,
      this.claveProdServ,
      this.claveUnidad,
      required this.descripcion,
      required this.cantidad,
      required this.valorUnitario,
      required this.importe,
      required this.descuento,
      this.objetoImp,
      required this.base,
      required this.tasaIva,
      required this.importeIva});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['fiscal_doc_id'] = Variable<int>(fiscalDocId);
    if (!nullToAbsent || claveProdServ != null) {
      map['clave_prod_serv'] = Variable<String>(claveProdServ);
    }
    if (!nullToAbsent || claveUnidad != null) {
      map['clave_unidad'] = Variable<String>(claveUnidad);
    }
    map['descripcion'] = Variable<String>(descripcion);
    map['cantidad'] = Variable<double>(cantidad);
    map['valor_unitario'] = Variable<double>(valorUnitario);
    map['importe'] = Variable<double>(importe);
    map['descuento'] = Variable<double>(descuento);
    if (!nullToAbsent || objetoImp != null) {
      map['objeto_imp'] = Variable<String>(objetoImp);
    }
    map['base'] = Variable<double>(base);
    map['tasa_iva'] = Variable<double>(tasaIva);
    map['importe_iva'] = Variable<double>(importeIva);
    return map;
  }

  FiscalDocItemsCompanion toCompanion(bool nullToAbsent) {
    return FiscalDocItemsCompanion(
      id: Value(id),
      fiscalDocId: Value(fiscalDocId),
      claveProdServ: claveProdServ == null && nullToAbsent
          ? const Value.absent()
          : Value(claveProdServ),
      claveUnidad: claveUnidad == null && nullToAbsent
          ? const Value.absent()
          : Value(claveUnidad),
      descripcion: Value(descripcion),
      cantidad: Value(cantidad),
      valorUnitario: Value(valorUnitario),
      importe: Value(importe),
      descuento: Value(descuento),
      objetoImp: objetoImp == null && nullToAbsent
          ? const Value.absent()
          : Value(objetoImp),
      base: Value(base),
      tasaIva: Value(tasaIva),
      importeIva: Value(importeIva),
    );
  }

  factory FiscalDocItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FiscalDocItem(
      id: serializer.fromJson<int>(json['id']),
      fiscalDocId: serializer.fromJson<int>(json['fiscalDocId']),
      claveProdServ: serializer.fromJson<String?>(json['claveProdServ']),
      claveUnidad: serializer.fromJson<String?>(json['claveUnidad']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      cantidad: serializer.fromJson<double>(json['cantidad']),
      valorUnitario: serializer.fromJson<double>(json['valorUnitario']),
      importe: serializer.fromJson<double>(json['importe']),
      descuento: serializer.fromJson<double>(json['descuento']),
      objetoImp: serializer.fromJson<String?>(json['objetoImp']),
      base: serializer.fromJson<double>(json['base']),
      tasaIva: serializer.fromJson<double>(json['tasaIva']),
      importeIva: serializer.fromJson<double>(json['importeIva']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fiscalDocId': serializer.toJson<int>(fiscalDocId),
      'claveProdServ': serializer.toJson<String?>(claveProdServ),
      'claveUnidad': serializer.toJson<String?>(claveUnidad),
      'descripcion': serializer.toJson<String>(descripcion),
      'cantidad': serializer.toJson<double>(cantidad),
      'valorUnitario': serializer.toJson<double>(valorUnitario),
      'importe': serializer.toJson<double>(importe),
      'descuento': serializer.toJson<double>(descuento),
      'objetoImp': serializer.toJson<String?>(objetoImp),
      'base': serializer.toJson<double>(base),
      'tasaIva': serializer.toJson<double>(tasaIva),
      'importeIva': serializer.toJson<double>(importeIva),
    };
  }

  FiscalDocItem copyWith(
          {int? id,
          int? fiscalDocId,
          Value<String?> claveProdServ = const Value.absent(),
          Value<String?> claveUnidad = const Value.absent(),
          String? descripcion,
          double? cantidad,
          double? valorUnitario,
          double? importe,
          double? descuento,
          Value<String?> objetoImp = const Value.absent(),
          double? base,
          double? tasaIva,
          double? importeIva}) =>
      FiscalDocItem(
        id: id ?? this.id,
        fiscalDocId: fiscalDocId ?? this.fiscalDocId,
        claveProdServ:
            claveProdServ.present ? claveProdServ.value : this.claveProdServ,
        claveUnidad: claveUnidad.present ? claveUnidad.value : this.claveUnidad,
        descripcion: descripcion ?? this.descripcion,
        cantidad: cantidad ?? this.cantidad,
        valorUnitario: valorUnitario ?? this.valorUnitario,
        importe: importe ?? this.importe,
        descuento: descuento ?? this.descuento,
        objetoImp: objetoImp.present ? objetoImp.value : this.objetoImp,
        base: base ?? this.base,
        tasaIva: tasaIva ?? this.tasaIva,
        importeIva: importeIva ?? this.importeIva,
      );
  FiscalDocItem copyWithCompanion(FiscalDocItemsCompanion data) {
    return FiscalDocItem(
      id: data.id.present ? data.id.value : this.id,
      fiscalDocId:
          data.fiscalDocId.present ? data.fiscalDocId.value : this.fiscalDocId,
      claveProdServ: data.claveProdServ.present
          ? data.claveProdServ.value
          : this.claveProdServ,
      claveUnidad:
          data.claveUnidad.present ? data.claveUnidad.value : this.claveUnidad,
      descripcion:
          data.descripcion.present ? data.descripcion.value : this.descripcion,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      valorUnitario: data.valorUnitario.present
          ? data.valorUnitario.value
          : this.valorUnitario,
      importe: data.importe.present ? data.importe.value : this.importe,
      descuento: data.descuento.present ? data.descuento.value : this.descuento,
      objetoImp: data.objetoImp.present ? data.objetoImp.value : this.objetoImp,
      base: data.base.present ? data.base.value : this.base,
      tasaIva: data.tasaIva.present ? data.tasaIva.value : this.tasaIva,
      importeIva:
          data.importeIva.present ? data.importeIva.value : this.importeIva,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FiscalDocItem(')
          ..write('id: $id, ')
          ..write('fiscalDocId: $fiscalDocId, ')
          ..write('claveProdServ: $claveProdServ, ')
          ..write('claveUnidad: $claveUnidad, ')
          ..write('descripcion: $descripcion, ')
          ..write('cantidad: $cantidad, ')
          ..write('valorUnitario: $valorUnitario, ')
          ..write('importe: $importe, ')
          ..write('descuento: $descuento, ')
          ..write('objetoImp: $objetoImp, ')
          ..write('base: $base, ')
          ..write('tasaIva: $tasaIva, ')
          ..write('importeIva: $importeIva')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      fiscalDocId,
      claveProdServ,
      claveUnidad,
      descripcion,
      cantidad,
      valorUnitario,
      importe,
      descuento,
      objetoImp,
      base,
      tasaIva,
      importeIva);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FiscalDocItem &&
          other.id == this.id &&
          other.fiscalDocId == this.fiscalDocId &&
          other.claveProdServ == this.claveProdServ &&
          other.claveUnidad == this.claveUnidad &&
          other.descripcion == this.descripcion &&
          other.cantidad == this.cantidad &&
          other.valorUnitario == this.valorUnitario &&
          other.importe == this.importe &&
          other.descuento == this.descuento &&
          other.objetoImp == this.objetoImp &&
          other.base == this.base &&
          other.tasaIva == this.tasaIva &&
          other.importeIva == this.importeIva);
}

class FiscalDocItemsCompanion extends UpdateCompanion<FiscalDocItem> {
  final Value<int> id;
  final Value<int> fiscalDocId;
  final Value<String?> claveProdServ;
  final Value<String?> claveUnidad;
  final Value<String> descripcion;
  final Value<double> cantidad;
  final Value<double> valorUnitario;
  final Value<double> importe;
  final Value<double> descuento;
  final Value<String?> objetoImp;
  final Value<double> base;
  final Value<double> tasaIva;
  final Value<double> importeIva;
  const FiscalDocItemsCompanion({
    this.id = const Value.absent(),
    this.fiscalDocId = const Value.absent(),
    this.claveProdServ = const Value.absent(),
    this.claveUnidad = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.valorUnitario = const Value.absent(),
    this.importe = const Value.absent(),
    this.descuento = const Value.absent(),
    this.objetoImp = const Value.absent(),
    this.base = const Value.absent(),
    this.tasaIva = const Value.absent(),
    this.importeIva = const Value.absent(),
  });
  FiscalDocItemsCompanion.insert({
    this.id = const Value.absent(),
    required int fiscalDocId,
    this.claveProdServ = const Value.absent(),
    this.claveUnidad = const Value.absent(),
    required String descripcion,
    required double cantidad,
    required double valorUnitario,
    required double importe,
    this.descuento = const Value.absent(),
    this.objetoImp = const Value.absent(),
    required double base,
    this.tasaIva = const Value.absent(),
    this.importeIva = const Value.absent(),
  })  : fiscalDocId = Value(fiscalDocId),
        descripcion = Value(descripcion),
        cantidad = Value(cantidad),
        valorUnitario = Value(valorUnitario),
        importe = Value(importe),
        base = Value(base);
  static Insertable<FiscalDocItem> custom({
    Expression<int>? id,
    Expression<int>? fiscalDocId,
    Expression<String>? claveProdServ,
    Expression<String>? claveUnidad,
    Expression<String>? descripcion,
    Expression<double>? cantidad,
    Expression<double>? valorUnitario,
    Expression<double>? importe,
    Expression<double>? descuento,
    Expression<String>? objetoImp,
    Expression<double>? base,
    Expression<double>? tasaIva,
    Expression<double>? importeIva,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fiscalDocId != null) 'fiscal_doc_id': fiscalDocId,
      if (claveProdServ != null) 'clave_prod_serv': claveProdServ,
      if (claveUnidad != null) 'clave_unidad': claveUnidad,
      if (descripcion != null) 'descripcion': descripcion,
      if (cantidad != null) 'cantidad': cantidad,
      if (valorUnitario != null) 'valor_unitario': valorUnitario,
      if (importe != null) 'importe': importe,
      if (descuento != null) 'descuento': descuento,
      if (objetoImp != null) 'objeto_imp': objetoImp,
      if (base != null) 'base': base,
      if (tasaIva != null) 'tasa_iva': tasaIva,
      if (importeIva != null) 'importe_iva': importeIva,
    });
  }

  FiscalDocItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? fiscalDocId,
      Value<String?>? claveProdServ,
      Value<String?>? claveUnidad,
      Value<String>? descripcion,
      Value<double>? cantidad,
      Value<double>? valorUnitario,
      Value<double>? importe,
      Value<double>? descuento,
      Value<String?>? objetoImp,
      Value<double>? base,
      Value<double>? tasaIva,
      Value<double>? importeIva}) {
    return FiscalDocItemsCompanion(
      id: id ?? this.id,
      fiscalDocId: fiscalDocId ?? this.fiscalDocId,
      claveProdServ: claveProdServ ?? this.claveProdServ,
      claveUnidad: claveUnidad ?? this.claveUnidad,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      importe: importe ?? this.importe,
      descuento: descuento ?? this.descuento,
      objetoImp: objetoImp ?? this.objetoImp,
      base: base ?? this.base,
      tasaIva: tasaIva ?? this.tasaIva,
      importeIva: importeIva ?? this.importeIva,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fiscalDocId.present) {
      map['fiscal_doc_id'] = Variable<int>(fiscalDocId.value);
    }
    if (claveProdServ.present) {
      map['clave_prod_serv'] = Variable<String>(claveProdServ.value);
    }
    if (claveUnidad.present) {
      map['clave_unidad'] = Variable<String>(claveUnidad.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<double>(cantidad.value);
    }
    if (valorUnitario.present) {
      map['valor_unitario'] = Variable<double>(valorUnitario.value);
    }
    if (importe.present) {
      map['importe'] = Variable<double>(importe.value);
    }
    if (descuento.present) {
      map['descuento'] = Variable<double>(descuento.value);
    }
    if (objetoImp.present) {
      map['objeto_imp'] = Variable<String>(objetoImp.value);
    }
    if (base.present) {
      map['base'] = Variable<double>(base.value);
    }
    if (tasaIva.present) {
      map['tasa_iva'] = Variable<double>(tasaIva.value);
    }
    if (importeIva.present) {
      map['importe_iva'] = Variable<double>(importeIva.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FiscalDocItemsCompanion(')
          ..write('id: $id, ')
          ..write('fiscalDocId: $fiscalDocId, ')
          ..write('claveProdServ: $claveProdServ, ')
          ..write('claveUnidad: $claveUnidad, ')
          ..write('descripcion: $descripcion, ')
          ..write('cantidad: $cantidad, ')
          ..write('valorUnitario: $valorUnitario, ')
          ..write('importe: $importe, ')
          ..write('descuento: $descuento, ')
          ..write('objetoImp: $objetoImp, ')
          ..write('base: $base, ')
          ..write('tasaIva: $tasaIva, ')
          ..write('importeIva: $importeIva')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ModifiersTable modifiers = $ModifiersTable(this);
  late final $DiscountsTable discounts = $DiscountsTable(this);
  late final $TablesLayoutTable tablesLayout = $TablesLayoutTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $EmployeesTable employees = $EmployeesTable(this);
  late final $ShiftsTable shifts = $ShiftsTable(this);
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderItemsTable orderItems = $OrderItemsTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $InventoryMovementsTable inventoryMovements =
      $InventoryMovementsTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $CashMovementsTable cashMovements = $CashMovementsTable(this);
  late final $RefundsTable refunds = $RefundsTable(this);
  late final $SuppliersTable suppliers = $SuppliersTable(this);
  late final $IngredientsTable ingredients = $IngredientsTable(this);
  late final $IngredientPurchasesTable ingredientPurchases =
      $IngredientPurchasesTable(this);
  late final $IngredientMovementsTable ingredientMovements =
      $IngredientMovementsTable(this);
  late final $IngredientPurchaseItemsTable ingredientPurchaseItems =
      $IngredientPurchaseItemsTable(this);
  late final $RecipeItemsTable recipeItems = $RecipeItemsTable(this);
  late final $DeliveryZonesTable deliveryZones = $DeliveryZonesTable(this);
  late final $FiscalDocsTable fiscalDocs = $FiscalDocsTable(this);
  late final $FiscalDocItemsTable fiscalDocItems = $FiscalDocItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        settings,
        categories,
        products,
        modifiers,
        discounts,
        tablesLayout,
        customers,
        employees,
        shifts,
        orders,
        orderItems,
        payments,
        expenses,
        inventoryMovements,
        auditLog,
        cashMovements,
        refunds,
        suppliers,
        ingredients,
        ingredientPurchases,
        ingredientMovements,
        ingredientPurchaseItems,
        recipeItems,
        deliveryZones,
        fiscalDocs,
        fiscalDocItems
      ];
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required String color,
  required String icon,
  Value<int> sortOrder,
  Value<bool> active,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> color,
  Value<String> icon,
  Value<int> sortOrder,
  Value<bool> active,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductsTable, List<Product>> _productsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.products,
          aliasName:
              $_aliasNameGenerator(db.categories.id, db.products.categoryId));

  $$ProductsTableProcessedTableManager get productsRefs {
    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  Expression<bool> productsRefs(
      Expression<bool> Function($$ProductsTableFilterComposer f) f) {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  Expression<T> productsRefs<T extends Object>(
      Expression<T> Function($$ProductsTableAnnotationComposer a) f) {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool productsRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> active = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            color: color,
            icon: icon,
            sortOrder: sortOrder,
            active: active,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String color,
            required String icon,
            Value<int> sortOrder = const Value.absent(),
            Value<bool> active = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            color: color,
            icon: icon,
            sortOrder: sortOrder,
            active: active,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productsRefs) db.products],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            Product>(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._productsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .productsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool productsRefs})>;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> description,
  required double price,
  Value<double> cost,
  required int categoryId,
  Value<String?> sku,
  Value<String?> imagePath,
  Value<bool> available,
  Value<bool> trackInventory,
  Value<int> stockQuantity,
  Value<int> minStock,
  Value<double?> taxRate,
  Value<bool?> taxIncluded,
  Value<bool> usesRecipe,
  Value<String?> claveProdServ,
  Value<String?> claveUnidad,
  Value<String?> objetoImp,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> description,
  Value<double> price,
  Value<double> cost,
  Value<int> categoryId,
  Value<String?> sku,
  Value<String?> imagePath,
  Value<bool> available,
  Value<bool> trackInventory,
  Value<int> stockQuantity,
  Value<int> minStock,
  Value<double?> taxRate,
  Value<bool?> taxIncluded,
  Value<bool> usesRecipe,
  Value<String?> claveProdServ,
  Value<String?> claveUnidad,
  Value<String?> objetoImp,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.products.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$OrderItemsTable, List<OrderItem>>
      _orderItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.orderItems,
          aliasName:
              $_aliasNameGenerator(db.products.id, db.orderItems.productId));

  $$OrderItemsTableProcessedTableManager get orderItemsRefs {
    final manager = $$OrderItemsTableTableManager($_db, $_db.orderItems)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InventoryMovementsTable, List<InventoryMovement>>
      _inventoryMovementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.inventoryMovements,
              aliasName: $_aliasNameGenerator(
                  db.products.id, db.inventoryMovements.productId));

  $$InventoryMovementsTableProcessedTableManager get inventoryMovementsRefs {
    final manager =
        $$InventoryMovementsTableTableManager($_db, $_db.inventoryMovements)
            .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_inventoryMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecipeItemsTable, List<RecipeItem>>
      _recipeItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.recipeItems,
          aliasName:
              $_aliasNameGenerator(db.products.id, db.recipeItems.productId));

  $$RecipeItemsTableProcessedTableManager get recipeItemsRefs {
    final manager = $$RecipeItemsTableTableManager($_db, $_db.recipeItems)
        .filter((f) => f.productId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cost => $composableBuilder(
      column: $table.cost, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get available => $composableBuilder(
      column: $table.available, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get trackInventory => $composableBuilder(
      column: $table.trackInventory,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minStock => $composableBuilder(
      column: $table.minStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get taxIncluded => $composableBuilder(
      column: $table.taxIncluded, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get usesRecipe => $composableBuilder(
      column: $table.usesRecipe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get claveProdServ => $composableBuilder(
      column: $table.claveProdServ, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get claveUnidad => $composableBuilder(
      column: $table.claveUnidad, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get objetoImp => $composableBuilder(
      column: $table.objetoImp, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> orderItemsRefs(
      Expression<bool> Function($$OrderItemsTableFilterComposer f) f) {
    final $$OrderItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableFilterComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> inventoryMovementsRefs(
      Expression<bool> Function($$InventoryMovementsTableFilterComposer f) f) {
    final $$InventoryMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.inventoryMovements,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryMovementsTableFilterComposer(
              $db: $db,
              $table: $db.inventoryMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recipeItemsRefs(
      Expression<bool> Function($$RecipeItemsTableFilterComposer f) f) {
    final $$RecipeItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeItemsTableFilterComposer(
              $db: $db,
              $table: $db.recipeItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cost => $composableBuilder(
      column: $table.cost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get available => $composableBuilder(
      column: $table.available, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get trackInventory => $composableBuilder(
      column: $table.trackInventory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minStock => $composableBuilder(
      column: $table.minStock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxRate => $composableBuilder(
      column: $table.taxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get taxIncluded => $composableBuilder(
      column: $table.taxIncluded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get usesRecipe => $composableBuilder(
      column: $table.usesRecipe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get claveProdServ => $composableBuilder(
      column: $table.claveProdServ,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get claveUnidad => $composableBuilder(
      column: $table.claveUnidad, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get objetoImp => $composableBuilder(
      column: $table.objetoImp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get available =>
      $composableBuilder(column: $table.available, builder: (column) => column);

  GeneratedColumn<bool> get trackInventory => $composableBuilder(
      column: $table.trackInventory, builder: (column) => column);

  GeneratedColumn<int> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity, builder: (column) => column);

  GeneratedColumn<int> get minStock =>
      $composableBuilder(column: $table.minStock, builder: (column) => column);

  GeneratedColumn<double> get taxRate =>
      $composableBuilder(column: $table.taxRate, builder: (column) => column);

  GeneratedColumn<bool> get taxIncluded => $composableBuilder(
      column: $table.taxIncluded, builder: (column) => column);

  GeneratedColumn<bool> get usesRecipe => $composableBuilder(
      column: $table.usesRecipe, builder: (column) => column);

  GeneratedColumn<String> get claveProdServ => $composableBuilder(
      column: $table.claveProdServ, builder: (column) => column);

  GeneratedColumn<String> get claveUnidad => $composableBuilder(
      column: $table.claveUnidad, builder: (column) => column);

  GeneratedColumn<String> get objetoImp =>
      $composableBuilder(column: $table.objetoImp, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> orderItemsRefs<T extends Object>(
      Expression<T> Function($$OrderItemsTableAnnotationComposer a) f) {
    final $$OrderItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> inventoryMovementsRefs<T extends Object>(
      Expression<T> Function($$InventoryMovementsTableAnnotationComposer a) f) {
    final $$InventoryMovementsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.inventoryMovements,
            getReferencedColumn: (t) => t.productId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InventoryMovementsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.inventoryMovements,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> recipeItemsRefs<T extends Object>(
      Expression<T> Function($$RecipeItemsTableAnnotationComposer a) f) {
    final $$RecipeItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeItems,
        getReferencedColumn: (t) => t.productId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.recipeItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, $$ProductsTableReferences),
    Product,
    PrefetchHooks Function(
        {bool categoryId,
        bool orderItemsRefs,
        bool inventoryMovementsRefs,
        bool recipeItemsRefs})> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double> cost = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<String?> sku = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> available = const Value.absent(),
            Value<bool> trackInventory = const Value.absent(),
            Value<int> stockQuantity = const Value.absent(),
            Value<int> minStock = const Value.absent(),
            Value<double?> taxRate = const Value.absent(),
            Value<bool?> taxIncluded = const Value.absent(),
            Value<bool> usesRecipe = const Value.absent(),
            Value<String?> claveProdServ = const Value.absent(),
            Value<String?> claveUnidad = const Value.absent(),
            Value<String?> objetoImp = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            name: name,
            description: description,
            price: price,
            cost: cost,
            categoryId: categoryId,
            sku: sku,
            imagePath: imagePath,
            available: available,
            trackInventory: trackInventory,
            stockQuantity: stockQuantity,
            minStock: minStock,
            taxRate: taxRate,
            taxIncluded: taxIncluded,
            usesRecipe: usesRecipe,
            claveProdServ: claveProdServ,
            claveUnidad: claveUnidad,
            objetoImp: objetoImp,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> description = const Value.absent(),
            required double price,
            Value<double> cost = const Value.absent(),
            required int categoryId,
            Value<String?> sku = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> available = const Value.absent(),
            Value<bool> trackInventory = const Value.absent(),
            Value<int> stockQuantity = const Value.absent(),
            Value<int> minStock = const Value.absent(),
            Value<double?> taxRate = const Value.absent(),
            Value<bool?> taxIncluded = const Value.absent(),
            Value<bool> usesRecipe = const Value.absent(),
            Value<String?> claveProdServ = const Value.absent(),
            Value<String?> claveUnidad = const Value.absent(),
            Value<String?> objetoImp = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            name: name,
            description: description,
            price: price,
            cost: cost,
            categoryId: categoryId,
            sku: sku,
            imagePath: imagePath,
            available: available,
            trackInventory: trackInventory,
            stockQuantity: stockQuantity,
            minStock: minStock,
            taxRate: taxRate,
            taxIncluded: taxIncluded,
            usesRecipe: usesRecipe,
            claveProdServ: claveProdServ,
            claveUnidad: claveUnidad,
            objetoImp: objetoImp,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProductsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false,
              orderItemsRefs = false,
              inventoryMovementsRefs = false,
              recipeItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (orderItemsRefs) db.orderItems,
                if (inventoryMovementsRefs) db.inventoryMovements,
                if (recipeItemsRefs) db.recipeItems
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$ProductsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$ProductsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (orderItemsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            OrderItem>(
                        currentTable: table,
                        referencedTable:
                            $$ProductsTableReferences._orderItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .orderItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (inventoryMovementsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            InventoryMovement>(
                        currentTable: table,
                        referencedTable: $$ProductsTableReferences
                            ._inventoryMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .inventoryMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items),
                  if (recipeItemsRefs)
                    await $_getPrefetchedData<Product, $ProductsTable,
                            RecipeItem>(
                        currentTable: table,
                        referencedTable:
                            $$ProductsTableReferences._recipeItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProductsTableReferences(db, table, p0)
                                .recipeItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.productId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, $$ProductsTableReferences),
    Product,
    PrefetchHooks Function(
        {bool categoryId,
        bool orderItemsRefs,
        bool inventoryMovementsRefs,
        bool recipeItemsRefs})>;
typedef $$ModifiersTableCreateCompanionBuilder = ModifiersCompanion Function({
  Value<int> id,
  required String name,
  Value<double> priceDelta,
  Value<String?> categoryScope,
});
typedef $$ModifiersTableUpdateCompanionBuilder = ModifiersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<double> priceDelta,
  Value<String?> categoryScope,
});

class $$ModifiersTableFilterComposer
    extends Composer<_$AppDatabase, $ModifiersTable> {
  $$ModifiersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priceDelta => $composableBuilder(
      column: $table.priceDelta, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryScope => $composableBuilder(
      column: $table.categoryScope, builder: (column) => ColumnFilters(column));
}

class $$ModifiersTableOrderingComposer
    extends Composer<_$AppDatabase, $ModifiersTable> {
  $$ModifiersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priceDelta => $composableBuilder(
      column: $table.priceDelta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryScope => $composableBuilder(
      column: $table.categoryScope,
      builder: (column) => ColumnOrderings(column));
}

class $$ModifiersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModifiersTable> {
  $$ModifiersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get priceDelta => $composableBuilder(
      column: $table.priceDelta, builder: (column) => column);

  GeneratedColumn<String> get categoryScope => $composableBuilder(
      column: $table.categoryScope, builder: (column) => column);
}

class $$ModifiersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ModifiersTable,
    Modifier,
    $$ModifiersTableFilterComposer,
    $$ModifiersTableOrderingComposer,
    $$ModifiersTableAnnotationComposer,
    $$ModifiersTableCreateCompanionBuilder,
    $$ModifiersTableUpdateCompanionBuilder,
    (Modifier, BaseReferences<_$AppDatabase, $ModifiersTable, Modifier>),
    Modifier,
    PrefetchHooks Function()> {
  $$ModifiersTableTableManager(_$AppDatabase db, $ModifiersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ModifiersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ModifiersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ModifiersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> priceDelta = const Value.absent(),
            Value<String?> categoryScope = const Value.absent(),
          }) =>
              ModifiersCompanion(
            id: id,
            name: name,
            priceDelta: priceDelta,
            categoryScope: categoryScope,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<double> priceDelta = const Value.absent(),
            Value<String?> categoryScope = const Value.absent(),
          }) =>
              ModifiersCompanion.insert(
            id: id,
            name: name,
            priceDelta: priceDelta,
            categoryScope: categoryScope,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ModifiersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ModifiersTable,
    Modifier,
    $$ModifiersTableFilterComposer,
    $$ModifiersTableOrderingComposer,
    $$ModifiersTableAnnotationComposer,
    $$ModifiersTableCreateCompanionBuilder,
    $$ModifiersTableUpdateCompanionBuilder,
    (Modifier, BaseReferences<_$AppDatabase, $ModifiersTable, Modifier>),
    Modifier,
    PrefetchHooks Function()>;
typedef $$DiscountsTableCreateCompanionBuilder = DiscountsCompanion Function({
  Value<int> id,
  required String name,
  required String type,
  required double value,
  Value<double> minOrderAmount,
  Value<bool> active,
  Value<DateTime?> validFrom,
  Value<DateTime?> validUntil,
  Value<String?> daysOfWeek,
  Value<String?> startTime,
  Value<String?> endTime,
  Value<String?> categoryScope,
  Value<DateTime> createdAt,
});
typedef $$DiscountsTableUpdateCompanionBuilder = DiscountsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> type,
  Value<double> value,
  Value<double> minOrderAmount,
  Value<bool> active,
  Value<DateTime?> validFrom,
  Value<DateTime?> validUntil,
  Value<String?> daysOfWeek,
  Value<String?> startTime,
  Value<String?> endTime,
  Value<String?> categoryScope,
  Value<DateTime> createdAt,
});

class $$DiscountsTableFilterComposer
    extends Composer<_$AppDatabase, $DiscountsTable> {
  $$DiscountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minOrderAmount => $composableBuilder(
      column: $table.minOrderAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get validFrom => $composableBuilder(
      column: $table.validFrom, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get validUntil => $composableBuilder(
      column: $table.validUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get daysOfWeek => $composableBuilder(
      column: $table.daysOfWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryScope => $composableBuilder(
      column: $table.categoryScope, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DiscountsTableOrderingComposer
    extends Composer<_$AppDatabase, $DiscountsTable> {
  $$DiscountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minOrderAmount => $composableBuilder(
      column: $table.minOrderAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get validFrom => $composableBuilder(
      column: $table.validFrom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get validUntil => $composableBuilder(
      column: $table.validUntil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get daysOfWeek => $composableBuilder(
      column: $table.daysOfWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryScope => $composableBuilder(
      column: $table.categoryScope,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DiscountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiscountsTable> {
  $$DiscountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get minOrderAmount => $composableBuilder(
      column: $table.minOrderAmount, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get validUntil => $composableBuilder(
      column: $table.validUntil, builder: (column) => column);

  GeneratedColumn<String> get daysOfWeek => $composableBuilder(
      column: $table.daysOfWeek, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get categoryScope => $composableBuilder(
      column: $table.categoryScope, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DiscountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiscountsTable,
    Discount,
    $$DiscountsTableFilterComposer,
    $$DiscountsTableOrderingComposer,
    $$DiscountsTableAnnotationComposer,
    $$DiscountsTableCreateCompanionBuilder,
    $$DiscountsTableUpdateCompanionBuilder,
    (Discount, BaseReferences<_$AppDatabase, $DiscountsTable, Discount>),
    Discount,
    PrefetchHooks Function()> {
  $$DiscountsTableTableManager(_$AppDatabase db, $DiscountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiscountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiscountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiscountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<double> minOrderAmount = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime?> validFrom = const Value.absent(),
            Value<DateTime?> validUntil = const Value.absent(),
            Value<String?> daysOfWeek = const Value.absent(),
            Value<String?> startTime = const Value.absent(),
            Value<String?> endTime = const Value.absent(),
            Value<String?> categoryScope = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DiscountsCompanion(
            id: id,
            name: name,
            type: type,
            value: value,
            minOrderAmount: minOrderAmount,
            active: active,
            validFrom: validFrom,
            validUntil: validUntil,
            daysOfWeek: daysOfWeek,
            startTime: startTime,
            endTime: endTime,
            categoryScope: categoryScope,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String type,
            required double value,
            Value<double> minOrderAmount = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime?> validFrom = const Value.absent(),
            Value<DateTime?> validUntil = const Value.absent(),
            Value<String?> daysOfWeek = const Value.absent(),
            Value<String?> startTime = const Value.absent(),
            Value<String?> endTime = const Value.absent(),
            Value<String?> categoryScope = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DiscountsCompanion.insert(
            id: id,
            name: name,
            type: type,
            value: value,
            minOrderAmount: minOrderAmount,
            active: active,
            validFrom: validFrom,
            validUntil: validUntil,
            daysOfWeek: daysOfWeek,
            startTime: startTime,
            endTime: endTime,
            categoryScope: categoryScope,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DiscountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DiscountsTable,
    Discount,
    $$DiscountsTableFilterComposer,
    $$DiscountsTableOrderingComposer,
    $$DiscountsTableAnnotationComposer,
    $$DiscountsTableCreateCompanionBuilder,
    $$DiscountsTableUpdateCompanionBuilder,
    (Discount, BaseReferences<_$AppDatabase, $DiscountsTable, Discount>),
    Discount,
    PrefetchHooks Function()>;
typedef $$TablesLayoutTableCreateCompanionBuilder = TablesLayoutCompanion
    Function({
  Value<int> id,
  required String name,
  Value<int> capacity,
  Value<String> status,
  Value<String?> notes,
  Value<bool> active,
});
typedef $$TablesLayoutTableUpdateCompanionBuilder = TablesLayoutCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int> capacity,
  Value<String> status,
  Value<String?> notes,
  Value<bool> active,
});

final class $$TablesLayoutTableReferences extends BaseReferences<_$AppDatabase,
    $TablesLayoutTable, TablesLayoutData> {
  $$TablesLayoutTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrdersTable, List<Order>> _ordersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.orders,
          aliasName:
              $_aliasNameGenerator(db.tablesLayout.id, db.orders.tableId));

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.tableId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TablesLayoutTableFilterComposer
    extends Composer<_$AppDatabase, $TablesLayoutTable> {
  $$TablesLayoutTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get capacity => $composableBuilder(
      column: $table.capacity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  Expression<bool> ordersRefs(
      Expression<bool> Function($$OrdersTableFilterComposer f) f) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.tableId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TablesLayoutTableOrderingComposer
    extends Composer<_$AppDatabase, $TablesLayoutTable> {
  $$TablesLayoutTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capacity => $composableBuilder(
      column: $table.capacity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));
}

class $$TablesLayoutTableAnnotationComposer
    extends Composer<_$AppDatabase, $TablesLayoutTable> {
  $$TablesLayoutTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get capacity =>
      $composableBuilder(column: $table.capacity, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  Expression<T> ordersRefs<T extends Object>(
      Expression<T> Function($$OrdersTableAnnotationComposer a) f) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.tableId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TablesLayoutTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TablesLayoutTable,
    TablesLayoutData,
    $$TablesLayoutTableFilterComposer,
    $$TablesLayoutTableOrderingComposer,
    $$TablesLayoutTableAnnotationComposer,
    $$TablesLayoutTableCreateCompanionBuilder,
    $$TablesLayoutTableUpdateCompanionBuilder,
    (TablesLayoutData, $$TablesLayoutTableReferences),
    TablesLayoutData,
    PrefetchHooks Function({bool ordersRefs})> {
  $$TablesLayoutTableTableManager(_$AppDatabase db, $TablesLayoutTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TablesLayoutTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TablesLayoutTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TablesLayoutTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> capacity = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> active = const Value.absent(),
          }) =>
              TablesLayoutCompanion(
            id: id,
            name: name,
            capacity: capacity,
            status: status,
            notes: notes,
            active: active,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int> capacity = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> active = const Value.absent(),
          }) =>
              TablesLayoutCompanion.insert(
            id: id,
            name: name,
            capacity: capacity,
            status: status,
            notes: notes,
            active: active,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TablesLayoutTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({ordersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ordersRefs) db.orders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ordersRefs)
                    await $_getPrefetchedData<TablesLayoutData,
                            $TablesLayoutTable, Order>(
                        currentTable: table,
                        referencedTable:
                            $$TablesLayoutTableReferences._ordersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TablesLayoutTableReferences(db, table, p0)
                                .ordersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tableId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TablesLayoutTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TablesLayoutTable,
    TablesLayoutData,
    $$TablesLayoutTableFilterComposer,
    $$TablesLayoutTableOrderingComposer,
    $$TablesLayoutTableAnnotationComposer,
    $$TablesLayoutTableCreateCompanionBuilder,
    $$TablesLayoutTableUpdateCompanionBuilder,
    (TablesLayoutData, $$TablesLayoutTableReferences),
    TablesLayoutData,
    PrefetchHooks Function({bool ordersRefs})>;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> phone,
  Value<String?> email,
  Value<int> visits,
  Value<double> totalSpent,
  Value<String?> notes,
  Value<String?> rfc,
  Value<String?> razonSocial,
  Value<String?> cpFiscal,
  Value<String?> regimenFiscal,
  Value<String?> usoCfdiPreferido,
  Value<DateTime> createdAt,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> phone,
  Value<String?> email,
  Value<int> visits,
  Value<double> totalSpent,
  Value<String?> notes,
  Value<String?> rfc,
  Value<String?> razonSocial,
  Value<String?> cpFiscal,
  Value<String?> regimenFiscal,
  Value<String?> usoCfdiPreferido,
  Value<DateTime> createdAt,
});

final class $$CustomersTableReferences
    extends BaseReferences<_$AppDatabase, $CustomersTable, Customer> {
  $$CustomersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrdersTable, List<Order>> _ordersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.orders,
          aliasName:
              $_aliasNameGenerator(db.customers.id, db.orders.customerId));

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.customerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get visits => $composableBuilder(
      column: $table.visits, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalSpent => $composableBuilder(
      column: $table.totalSpent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rfc => $composableBuilder(
      column: $table.rfc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get razonSocial => $composableBuilder(
      column: $table.razonSocial, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cpFiscal => $composableBuilder(
      column: $table.cpFiscal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get regimenFiscal => $composableBuilder(
      column: $table.regimenFiscal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get usoCfdiPreferido => $composableBuilder(
      column: $table.usoCfdiPreferido,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> ordersRefs(
      Expression<bool> Function($$OrdersTableFilterComposer f) f) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get visits => $composableBuilder(
      column: $table.visits, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalSpent => $composableBuilder(
      column: $table.totalSpent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rfc => $composableBuilder(
      column: $table.rfc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get razonSocial => $composableBuilder(
      column: $table.razonSocial, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cpFiscal => $composableBuilder(
      column: $table.cpFiscal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get regimenFiscal => $composableBuilder(
      column: $table.regimenFiscal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get usoCfdiPreferido => $composableBuilder(
      column: $table.usoCfdiPreferido,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<int> get visits =>
      $composableBuilder(column: $table.visits, builder: (column) => column);

  GeneratedColumn<double> get totalSpent => $composableBuilder(
      column: $table.totalSpent, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get rfc =>
      $composableBuilder(column: $table.rfc, builder: (column) => column);

  GeneratedColumn<String> get razonSocial => $composableBuilder(
      column: $table.razonSocial, builder: (column) => column);

  GeneratedColumn<String> get cpFiscal =>
      $composableBuilder(column: $table.cpFiscal, builder: (column) => column);

  GeneratedColumn<String> get regimenFiscal => $composableBuilder(
      column: $table.regimenFiscal, builder: (column) => column);

  GeneratedColumn<String> get usoCfdiPreferido => $composableBuilder(
      column: $table.usoCfdiPreferido, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> ordersRefs<T extends Object>(
      Expression<T> Function($$OrdersTableAnnotationComposer a) f) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.customerId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, $$CustomersTableReferences),
    Customer,
    PrefetchHooks Function({bool ordersRefs})> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<int> visits = const Value.absent(),
            Value<double> totalSpent = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> rfc = const Value.absent(),
            Value<String?> razonSocial = const Value.absent(),
            Value<String?> cpFiscal = const Value.absent(),
            Value<String?> regimenFiscal = const Value.absent(),
            Value<String?> usoCfdiPreferido = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            name: name,
            phone: phone,
            email: email,
            visits: visits,
            totalSpent: totalSpent,
            notes: notes,
            rfc: rfc,
            razonSocial: razonSocial,
            cpFiscal: cpFiscal,
            regimenFiscal: regimenFiscal,
            usoCfdiPreferido: usoCfdiPreferido,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> phone = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<int> visits = const Value.absent(),
            Value<double> totalSpent = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> rfc = const Value.absent(),
            Value<String?> razonSocial = const Value.absent(),
            Value<String?> cpFiscal = const Value.absent(),
            Value<String?> regimenFiscal = const Value.absent(),
            Value<String?> usoCfdiPreferido = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            email: email,
            visits: visits,
            totalSpent: totalSpent,
            notes: notes,
            rfc: rfc,
            razonSocial: razonSocial,
            cpFiscal: cpFiscal,
            regimenFiscal: regimenFiscal,
            usoCfdiPreferido: usoCfdiPreferido,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CustomersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({ordersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ordersRefs) db.orders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ordersRefs)
                    await $_getPrefetchedData<Customer, $CustomersTable, Order>(
                        currentTable: table,
                        referencedTable:
                            $$CustomersTableReferences._ordersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CustomersTableReferences(db, table, p0)
                                .ordersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.customerId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CustomersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, $$CustomersTableReferences),
    Customer,
    PrefetchHooks Function({bool ordersRefs})>;
typedef $$EmployeesTableCreateCompanionBuilder = EmployeesCompanion Function({
  Value<int> id,
  required String name,
  required String pin,
  required String role,
  Value<bool> active,
  Value<DateTime> createdAt,
});
typedef $$EmployeesTableUpdateCompanionBuilder = EmployeesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> pin,
  Value<String> role,
  Value<bool> active,
  Value<DateTime> createdAt,
});

final class $$EmployeesTableReferences
    extends BaseReferences<_$AppDatabase, $EmployeesTable, Employee> {
  $$EmployeesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShiftsTable, List<Shift>> _shiftsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.shifts,
          aliasName:
              $_aliasNameGenerator(db.employees.id, db.shifts.employeeId));

  $$ShiftsTableProcessedTableManager get shiftsRefs {
    final manager = $$ShiftsTableTableManager($_db, $_db.shifts)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_shiftsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$OrdersTable, List<Order>> _ordersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.orders,
          aliasName:
              $_aliasNameGenerator(db.employees.id, db.orders.employeeId));

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.expenses,
          aliasName:
              $_aliasNameGenerator(db.employees.id, db.expenses.createdById));

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses)
        .filter((f) => f.createdById.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AuditLogTable, List<AuditLogData>>
      _auditLogRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.auditLog,
          aliasName:
              $_aliasNameGenerator(db.employees.id, db.auditLog.employeeId));

  $$AuditLogTableProcessedTableManager get auditLogRefs {
    final manager = $$AuditLogTableTableManager($_db, $_db.auditLog)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_auditLogRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CashMovementsTable, List<CashMovement>>
      _cashMovementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cashMovements,
              aliasName: $_aliasNameGenerator(
                  db.employees.id, db.cashMovements.employeeId));

  $$CashMovementsTableProcessedTableManager get cashMovementsRefs {
    final manager = $$CashMovementsTableTableManager($_db, $_db.cashMovements)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cashMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RefundsTable, List<Refund>> _refundsIssuedTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.refunds,
          aliasName:
              $_aliasNameGenerator(db.employees.id, db.refunds.employeeId));

  $$RefundsTableProcessedTableManager get refundsIssued {
    final manager = $$RefundsTableTableManager($_db, $_db.refunds)
        .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_refundsIssuedTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RefundsTable, List<Refund>>
      _refundsAuthorizedTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.refunds,
              aliasName: $_aliasNameGenerator(
                  db.employees.id, db.refunds.supervisorId));

  $$RefundsTableProcessedTableManager get refundsAuthorized {
    final manager = $$RefundsTableTableManager($_db, $_db.refunds)
        .filter((f) => f.supervisorId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_refundsAuthorizedTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IngredientPurchasesTable,
      List<IngredientPurchase>> _ingredientPurchasesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.ingredientPurchases,
          aliasName: $_aliasNameGenerator(
              db.employees.id, db.ingredientPurchases.employeeId));

  $$IngredientPurchasesTableProcessedTableManager get ingredientPurchasesRefs {
    final manager =
        $$IngredientPurchasesTableTableManager($_db, $_db.ingredientPurchases)
            .filter((f) => f.employeeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientPurchasesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EmployeesTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pin => $composableBuilder(
      column: $table.pin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> shiftsRefs(
      Expression<bool> Function($$ShiftsTableFilterComposer f) f) {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableFilterComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ordersRefs(
      Expression<bool> Function($$OrdersTableFilterComposer f) f) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> expensesRefs(
      Expression<bool> Function($$ExpensesTableFilterComposer f) f) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.createdById,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableFilterComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> auditLogRefs(
      Expression<bool> Function($$AuditLogTableFilterComposer f) f) {
    final $$AuditLogTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.auditLog,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AuditLogTableFilterComposer(
              $db: $db,
              $table: $db.auditLog,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> cashMovementsRefs(
      Expression<bool> Function($$CashMovementsTableFilterComposer f) f) {
    final $$CashMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cashMovements,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashMovementsTableFilterComposer(
              $db: $db,
              $table: $db.cashMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> refundsIssued(
      Expression<bool> Function($$RefundsTableFilterComposer f) f) {
    final $$RefundsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableFilterComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> refundsAuthorized(
      Expression<bool> Function($$RefundsTableFilterComposer f) f) {
    final $$RefundsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.supervisorId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableFilterComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ingredientPurchasesRefs(
      Expression<bool> Function($$IngredientPurchasesTableFilterComposer f) f) {
    final $$IngredientPurchasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredientPurchases,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientPurchasesTableFilterComposer(
              $db: $db,
              $table: $db.ingredientPurchases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EmployeesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pin => $composableBuilder(
      column: $table.pin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$EmployeesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeesTable> {
  $$EmployeesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get pin =>
      $composableBuilder(column: $table.pin, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> shiftsRefs<T extends Object>(
      Expression<T> Function($$ShiftsTableAnnotationComposer a) f) {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableAnnotationComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ordersRefs<T extends Object>(
      Expression<T> Function($$OrdersTableAnnotationComposer a) f) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
      Expression<T> Function($$ExpensesTableAnnotationComposer a) f) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.expenses,
        getReferencedColumn: (t) => t.createdById,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExpensesTableAnnotationComposer(
              $db: $db,
              $table: $db.expenses,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> auditLogRefs<T extends Object>(
      Expression<T> Function($$AuditLogTableAnnotationComposer a) f) {
    final $$AuditLogTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.auditLog,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AuditLogTableAnnotationComposer(
              $db: $db,
              $table: $db.auditLog,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> cashMovementsRefs<T extends Object>(
      Expression<T> Function($$CashMovementsTableAnnotationComposer a) f) {
    final $$CashMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cashMovements,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.cashMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> refundsIssued<T extends Object>(
      Expression<T> Function($$RefundsTableAnnotationComposer a) f) {
    final $$RefundsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.employeeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableAnnotationComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> refundsAuthorized<T extends Object>(
      Expression<T> Function($$RefundsTableAnnotationComposer a) f) {
    final $$RefundsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.supervisorId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableAnnotationComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ingredientPurchasesRefs<T extends Object>(
      Expression<T> Function($$IngredientPurchasesTableAnnotationComposer a)
          f) {
    final $$IngredientPurchasesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientPurchases,
            getReferencedColumn: (t) => t.employeeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientPurchasesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientPurchases,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$EmployeesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmployeesTable,
    Employee,
    $$EmployeesTableFilterComposer,
    $$EmployeesTableOrderingComposer,
    $$EmployeesTableAnnotationComposer,
    $$EmployeesTableCreateCompanionBuilder,
    $$EmployeesTableUpdateCompanionBuilder,
    (Employee, $$EmployeesTableReferences),
    Employee,
    PrefetchHooks Function(
        {bool shiftsRefs,
        bool ordersRefs,
        bool expensesRefs,
        bool auditLogRefs,
        bool cashMovementsRefs,
        bool refundsIssued,
        bool refundsAuthorized,
        bool ingredientPurchasesRefs})> {
  $$EmployeesTableTableManager(_$AppDatabase db, $EmployeesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> pin = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              EmployeesCompanion(
            id: id,
            name: name,
            pin: pin,
            role: role,
            active: active,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String pin,
            required String role,
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              EmployeesCompanion.insert(
            id: id,
            name: name,
            pin: pin,
            role: role,
            active: active,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$EmployeesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {shiftsRefs = false,
              ordersRefs = false,
              expensesRefs = false,
              auditLogRefs = false,
              cashMovementsRefs = false,
              refundsIssued = false,
              refundsAuthorized = false,
              ingredientPurchasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (shiftsRefs) db.shifts,
                if (ordersRefs) db.orders,
                if (expensesRefs) db.expenses,
                if (auditLogRefs) db.auditLog,
                if (cashMovementsRefs) db.cashMovements,
                if (refundsIssued) db.refunds,
                if (refundsAuthorized) db.refunds,
                if (ingredientPurchasesRefs) db.ingredientPurchases
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shiftsRefs)
                    await $_getPrefetchedData<Employee, $EmployeesTable, Shift>(
                        currentTable: table,
                        referencedTable:
                            $$EmployeesTableReferences._shiftsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .shiftsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (ordersRefs)
                    await $_getPrefetchedData<Employee, $EmployeesTable, Order>(
                        currentTable: table,
                        referencedTable:
                            $$EmployeesTableReferences._ordersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .ordersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (expensesRefs)
                    await $_getPrefetchedData<Employee, $EmployeesTable,
                            Expense>(
                        currentTable: table,
                        referencedTable:
                            $$EmployeesTableReferences._expensesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .expensesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.createdById == item.id),
                        typedResults: items),
                  if (auditLogRefs)
                    await $_getPrefetchedData<Employee, $EmployeesTable,
                            AuditLogData>(
                        currentTable: table,
                        referencedTable:
                            $$EmployeesTableReferences._auditLogRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .auditLogRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (cashMovementsRefs)
                    await $_getPrefetchedData<Employee, $EmployeesTable,
                            CashMovement>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._cashMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .cashMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (refundsIssued)
                    await $_getPrefetchedData<Employee, $EmployeesTable,
                            Refund>(
                        currentTable: table,
                        referencedTable:
                            $$EmployeesTableReferences._refundsIssuedTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .refundsIssued,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items),
                  if (refundsAuthorized)
                    await $_getPrefetchedData<Employee, $EmployeesTable,
                            Refund>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._refundsAuthorizedTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .refundsAuthorized,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.supervisorId == item.id),
                        typedResults: items),
                  if (ingredientPurchasesRefs)
                    await $_getPrefetchedData<Employee, $EmployeesTable,
                            IngredientPurchase>(
                        currentTable: table,
                        referencedTable: $$EmployeesTableReferences
                            ._ingredientPurchasesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EmployeesTableReferences(db, table, p0)
                                .ingredientPurchasesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.employeeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EmployeesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EmployeesTable,
    Employee,
    $$EmployeesTableFilterComposer,
    $$EmployeesTableOrderingComposer,
    $$EmployeesTableAnnotationComposer,
    $$EmployeesTableCreateCompanionBuilder,
    $$EmployeesTableUpdateCompanionBuilder,
    (Employee, $$EmployeesTableReferences),
    Employee,
    PrefetchHooks Function(
        {bool shiftsRefs,
        bool ordersRefs,
        bool expensesRefs,
        bool auditLogRefs,
        bool cashMovementsRefs,
        bool refundsIssued,
        bool refundsAuthorized,
        bool ingredientPurchasesRefs})>;
typedef $$ShiftsTableCreateCompanionBuilder = ShiftsCompanion Function({
  Value<int> id,
  required int employeeId,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<double> startingCash,
  Value<double?> endingCash,
  Value<double> totalSales,
  Value<String?> notes,
  Value<int?> zNumber,
  Value<DateTime?> deletedAt,
});
typedef $$ShiftsTableUpdateCompanionBuilder = ShiftsCompanion Function({
  Value<int> id,
  Value<int> employeeId,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<double> startingCash,
  Value<double?> endingCash,
  Value<double> totalSales,
  Value<String?> notes,
  Value<int?> zNumber,
  Value<DateTime?> deletedAt,
});

final class $$ShiftsTableReferences
    extends BaseReferences<_$AppDatabase, $ShiftsTable, Shift> {
  $$ShiftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) => db.employees
      .createAlias($_aliasNameGenerator(db.shifts.employeeId, db.employees.id));

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$OrdersTable, List<Order>> _ordersRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.orders,
          aliasName: $_aliasNameGenerator(db.shifts.id, db.orders.shiftId));

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.shiftId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PaymentsTable, List<Payment>> _paymentsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.payments,
          aliasName: $_aliasNameGenerator(db.shifts.id, db.payments.shiftId));

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager($_db, $_db.payments)
        .filter((f) => f.shiftId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CashMovementsTable, List<CashMovement>>
      _cashMovementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cashMovements,
              aliasName:
                  $_aliasNameGenerator(db.shifts.id, db.cashMovements.shiftId));

  $$CashMovementsTableProcessedTableManager get cashMovementsRefs {
    final manager = $$CashMovementsTableTableManager($_db, $_db.cashMovements)
        .filter((f) => f.shiftId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cashMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RefundsTable, List<Refund>> _refundsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.refunds,
          aliasName: $_aliasNameGenerator(db.shifts.id, db.refunds.shiftId));

  $$RefundsTableProcessedTableManager get refundsRefs {
    final manager = $$RefundsTableTableManager($_db, $_db.refunds)
        .filter((f) => f.shiftId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_refundsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ShiftsTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startingCash => $composableBuilder(
      column: $table.startingCash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get endingCash => $composableBuilder(
      column: $table.endingCash, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalSales => $composableBuilder(
      column: $table.totalSales, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get zNumber => $composableBuilder(
      column: $table.zNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> ordersRefs(
      Expression<bool> Function($$OrdersTableFilterComposer f) f) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.shiftId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> paymentsRefs(
      Expression<bool> Function($$PaymentsTableFilterComposer f) f) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payments,
        getReferencedColumn: (t) => t.shiftId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentsTableFilterComposer(
              $db: $db,
              $table: $db.payments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> cashMovementsRefs(
      Expression<bool> Function($$CashMovementsTableFilterComposer f) f) {
    final $$CashMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cashMovements,
        getReferencedColumn: (t) => t.shiftId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashMovementsTableFilterComposer(
              $db: $db,
              $table: $db.cashMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> refundsRefs(
      Expression<bool> Function($$RefundsTableFilterComposer f) f) {
    final $$RefundsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.shiftId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableFilterComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ShiftsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startingCash => $composableBuilder(
      column: $table.startingCash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get endingCash => $composableBuilder(
      column: $table.endingCash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalSales => $composableBuilder(
      column: $table.totalSales, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get zNumber => $composableBuilder(
      column: $table.zNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShiftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftsTable> {
  $$ShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get startingCash => $composableBuilder(
      column: $table.startingCash, builder: (column) => column);

  GeneratedColumn<double> get endingCash => $composableBuilder(
      column: $table.endingCash, builder: (column) => column);

  GeneratedColumn<double> get totalSales => $composableBuilder(
      column: $table.totalSales, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get zNumber =>
      $composableBuilder(column: $table.zNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> ordersRefs<T extends Object>(
      Expression<T> Function($$OrdersTableAnnotationComposer a) f) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.shiftId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> paymentsRefs<T extends Object>(
      Expression<T> Function($$PaymentsTableAnnotationComposer a) f) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payments,
        getReferencedColumn: (t) => t.shiftId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.payments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> cashMovementsRefs<T extends Object>(
      Expression<T> Function($$CashMovementsTableAnnotationComposer a) f) {
    final $$CashMovementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cashMovements,
        getReferencedColumn: (t) => t.shiftId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CashMovementsTableAnnotationComposer(
              $db: $db,
              $table: $db.cashMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> refundsRefs<T extends Object>(
      Expression<T> Function($$RefundsTableAnnotationComposer a) f) {
    final $$RefundsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.shiftId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableAnnotationComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ShiftsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShiftsTable,
    Shift,
    $$ShiftsTableFilterComposer,
    $$ShiftsTableOrderingComposer,
    $$ShiftsTableAnnotationComposer,
    $$ShiftsTableCreateCompanionBuilder,
    $$ShiftsTableUpdateCompanionBuilder,
    (Shift, $$ShiftsTableReferences),
    Shift,
    PrefetchHooks Function(
        {bool employeeId,
        bool ordersRefs,
        bool paymentsRefs,
        bool cashMovementsRefs,
        bool refundsRefs})> {
  $$ShiftsTableTableManager(_$AppDatabase db, $ShiftsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> employeeId = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> endedAt = const Value.absent(),
            Value<double> startingCash = const Value.absent(),
            Value<double?> endingCash = const Value.absent(),
            Value<double> totalSales = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int?> zNumber = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              ShiftsCompanion(
            id: id,
            employeeId: employeeId,
            startedAt: startedAt,
            endedAt: endedAt,
            startingCash: startingCash,
            endingCash: endingCash,
            totalSales: totalSales,
            notes: notes,
            zNumber: zNumber,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int employeeId,
            required DateTime startedAt,
            Value<DateTime?> endedAt = const Value.absent(),
            Value<double> startingCash = const Value.absent(),
            Value<double?> endingCash = const Value.absent(),
            Value<double> totalSales = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int?> zNumber = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              ShiftsCompanion.insert(
            id: id,
            employeeId: employeeId,
            startedAt: startedAt,
            endedAt: endedAt,
            startingCash: startingCash,
            endingCash: endingCash,
            totalSales: totalSales,
            notes: notes,
            zNumber: zNumber,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ShiftsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {employeeId = false,
              ordersRefs = false,
              paymentsRefs = false,
              cashMovementsRefs = false,
              refundsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ordersRefs) db.orders,
                if (paymentsRefs) db.payments,
                if (cashMovementsRefs) db.cashMovements,
                if (refundsRefs) db.refunds
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$ShiftsTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$ShiftsTableReferences._employeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ordersRefs)
                    await $_getPrefetchedData<Shift, $ShiftsTable, Order>(
                        currentTable: table,
                        referencedTable:
                            $$ShiftsTableReferences._ordersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ShiftsTableReferences(db, table, p0).ordersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.shiftId == item.id),
                        typedResults: items),
                  if (paymentsRefs)
                    await $_getPrefetchedData<Shift, $ShiftsTable, Payment>(
                        currentTable: table,
                        referencedTable:
                            $$ShiftsTableReferences._paymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ShiftsTableReferences(db, table, p0).paymentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.shiftId == item.id),
                        typedResults: items),
                  if (cashMovementsRefs)
                    await $_getPrefetchedData<Shift, $ShiftsTable,
                            CashMovement>(
                        currentTable: table,
                        referencedTable:
                            $$ShiftsTableReferences._cashMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ShiftsTableReferences(db, table, p0)
                                .cashMovementsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.shiftId == item.id),
                        typedResults: items),
                  if (refundsRefs)
                    await $_getPrefetchedData<Shift, $ShiftsTable, Refund>(
                        currentTable: table,
                        referencedTable:
                            $$ShiftsTableReferences._refundsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ShiftsTableReferences(db, table, p0).refundsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.shiftId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ShiftsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShiftsTable,
    Shift,
    $$ShiftsTableFilterComposer,
    $$ShiftsTableOrderingComposer,
    $$ShiftsTableAnnotationComposer,
    $$ShiftsTableCreateCompanionBuilder,
    $$ShiftsTableUpdateCompanionBuilder,
    (Shift, $$ShiftsTableReferences),
    Shift,
    PrefetchHooks Function(
        {bool employeeId,
        bool ordersRefs,
        bool paymentsRefs,
        bool cashMovementsRefs,
        bool refundsRefs})>;
typedef $$OrdersTableCreateCompanionBuilder = OrdersCompanion Function({
  Value<int> id,
  required String orderNumber,
  required String type,
  Value<int?> tableId,
  Value<String?> customerName,
  Value<int?> customerId,
  Value<String?> customerPhone,
  Value<String?> customerAddress,
  required int employeeId,
  Value<int?> shiftId,
  Value<String?> note,
  Value<String> status,
  Value<String> paymentStatus,
  Value<double> subtotal,
  Value<double> discountAmount,
  Value<double> taxAmount,
  Value<double> total,
  Value<String?> deliveryZone,
  Value<double> deliveryFee,
  Value<String?> deliveryPaymentMethod,
  Value<double?> deliveryCashAmount,
  Value<String?> cancelReason,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> completedAt,
  Value<DateTime?> deletedAt,
});
typedef $$OrdersTableUpdateCompanionBuilder = OrdersCompanion Function({
  Value<int> id,
  Value<String> orderNumber,
  Value<String> type,
  Value<int?> tableId,
  Value<String?> customerName,
  Value<int?> customerId,
  Value<String?> customerPhone,
  Value<String?> customerAddress,
  Value<int> employeeId,
  Value<int?> shiftId,
  Value<String?> note,
  Value<String> status,
  Value<String> paymentStatus,
  Value<double> subtotal,
  Value<double> discountAmount,
  Value<double> taxAmount,
  Value<double> total,
  Value<String?> deliveryZone,
  Value<double> deliveryFee,
  Value<String?> deliveryPaymentMethod,
  Value<double?> deliveryCashAmount,
  Value<String?> cancelReason,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> completedAt,
  Value<DateTime?> deletedAt,
});

final class $$OrdersTableReferences
    extends BaseReferences<_$AppDatabase, $OrdersTable, Order> {
  $$OrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TablesLayoutTable _tableIdTable(_$AppDatabase db) => db.tablesLayout
      .createAlias($_aliasNameGenerator(db.orders.tableId, db.tablesLayout.id));

  $$TablesLayoutTableProcessedTableManager? get tableId {
    final $_column = $_itemColumn<int>('table_id');
    if ($_column == null) return null;
    final manager = $$TablesLayoutTableTableManager($_db, $_db.tablesLayout)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tableIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CustomersTable _customerIdTable(_$AppDatabase db) => db.customers
      .createAlias($_aliasNameGenerator(db.orders.customerId, db.customers.id));

  $$CustomersTableProcessedTableManager? get customerId {
    final $_column = $_itemColumn<int>('customer_id');
    if ($_column == null) return null;
    final manager = $$CustomersTableTableManager($_db, $_db.customers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) => db.employees
      .createAlias($_aliasNameGenerator(db.orders.employeeId, db.employees.id));

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) => db.shifts
      .createAlias($_aliasNameGenerator(db.orders.shiftId, db.shifts.id));

  $$ShiftsTableProcessedTableManager? get shiftId {
    final $_column = $_itemColumn<int>('shift_id');
    if ($_column == null) return null;
    final manager = $$ShiftsTableTableManager($_db, $_db.shifts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$OrderItemsTable, List<OrderItem>>
      _orderItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.orderItems,
          aliasName: $_aliasNameGenerator(db.orders.id, db.orderItems.orderId));

  $$OrderItemsTableProcessedTableManager get orderItemsRefs {
    final manager = $$OrderItemsTableTableManager($_db, $_db.orderItems)
        .filter((f) => f.orderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PaymentsTable, List<Payment>> _paymentsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.payments,
          aliasName: $_aliasNameGenerator(db.orders.id, db.payments.orderId));

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager($_db, $_db.payments)
        .filter((f) => f.orderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$InventoryMovementsTable, List<InventoryMovement>>
      _inventoryMovementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.inventoryMovements,
              aliasName: $_aliasNameGenerator(
                  db.orders.id, db.inventoryMovements.orderId));

  $$InventoryMovementsTableProcessedTableManager get inventoryMovementsRefs {
    final manager =
        $$InventoryMovementsTableTableManager($_db, $_db.inventoryMovements)
            .filter((f) => f.orderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_inventoryMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RefundsTable, List<Refund>> _refundsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.refunds,
          aliasName: $_aliasNameGenerator(db.orders.id, db.refunds.orderId));

  $$RefundsTableProcessedTableManager get refundsRefs {
    final manager = $$RefundsTableTableManager($_db, $_db.refunds)
        .filter((f) => f.orderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_refundsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IngredientMovementsTable,
      List<IngredientMovement>> _ingredientMovementsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.ingredientMovements,
          aliasName: $_aliasNameGenerator(
              db.orders.id, db.ingredientMovements.orderId));

  $$IngredientMovementsTableProcessedTableManager get ingredientMovementsRefs {
    final manager =
        $$IngredientMovementsTableTableManager($_db, $_db.ingredientMovements)
            .filter((f) => f.orderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FiscalDocsTable, List<FiscalDoc>>
      _fiscalDocsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.fiscalDocs,
          aliasName: $_aliasNameGenerator(db.orders.id, db.fiscalDocs.orderId));

  $$FiscalDocsTableProcessedTableManager get fiscalDocsRefs {
    final manager = $$FiscalDocsTableTableManager($_db, $_db.fiscalDocs)
        .filter((f) => f.orderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fiscalDocsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderNumber => $composableBuilder(
      column: $table.orderNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerAddress => $composableBuilder(
      column: $table.customerAddress,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get taxAmount => $composableBuilder(
      column: $table.taxAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deliveryZone => $composableBuilder(
      column: $table.deliveryZone, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get deliveryFee => $composableBuilder(
      column: $table.deliveryFee, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deliveryPaymentMethod => $composableBuilder(
      column: $table.deliveryPaymentMethod,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get deliveryCashAmount => $composableBuilder(
      column: $table.deliveryCashAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cancelReason => $composableBuilder(
      column: $table.cancelReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$TablesLayoutTableFilterComposer get tableId {
    final $$TablesLayoutTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tableId,
        referencedTable: $db.tablesLayout,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TablesLayoutTableFilterComposer(
              $db: $db,
              $table: $db.tablesLayout,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableFilterComposer get customerId {
    final $$CustomersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableFilterComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableFilterComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> orderItemsRefs(
      Expression<bool> Function($$OrderItemsTableFilterComposer f) f) {
    final $$OrderItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableFilterComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> paymentsRefs(
      Expression<bool> Function($$PaymentsTableFilterComposer f) f) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payments,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentsTableFilterComposer(
              $db: $db,
              $table: $db.payments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> inventoryMovementsRefs(
      Expression<bool> Function($$InventoryMovementsTableFilterComposer f) f) {
    final $$InventoryMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.inventoryMovements,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$InventoryMovementsTableFilterComposer(
              $db: $db,
              $table: $db.inventoryMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> refundsRefs(
      Expression<bool> Function($$RefundsTableFilterComposer f) f) {
    final $$RefundsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableFilterComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ingredientMovementsRefs(
      Expression<bool> Function($$IngredientMovementsTableFilterComposer f) f) {
    final $$IngredientMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredientMovements,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientMovementsTableFilterComposer(
              $db: $db,
              $table: $db.ingredientMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> fiscalDocsRefs(
      Expression<bool> Function($$FiscalDocsTableFilterComposer f) f) {
    final $$FiscalDocsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fiscalDocs,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalDocsTableFilterComposer(
              $db: $db,
              $table: $db.fiscalDocs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderNumber => $composableBuilder(
      column: $table.orderNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerName => $composableBuilder(
      column: $table.customerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerAddress => $composableBuilder(
      column: $table.customerAddress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get taxAmount => $composableBuilder(
      column: $table.taxAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deliveryZone => $composableBuilder(
      column: $table.deliveryZone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get deliveryFee => $composableBuilder(
      column: $table.deliveryFee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deliveryPaymentMethod => $composableBuilder(
      column: $table.deliveryPaymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get deliveryCashAmount => $composableBuilder(
      column: $table.deliveryCashAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cancelReason => $composableBuilder(
      column: $table.cancelReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$TablesLayoutTableOrderingComposer get tableId {
    final $$TablesLayoutTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tableId,
        referencedTable: $db.tablesLayout,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TablesLayoutTableOrderingComposer(
              $db: $db,
              $table: $db.tablesLayout,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableOrderingComposer get customerId {
    final $$CustomersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableOrderingComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableOrderingComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderNumber => $composableBuilder(
      column: $table.orderNumber, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => column);

  GeneratedColumn<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone, builder: (column) => column);

  GeneratedColumn<String> get customerAddress => $composableBuilder(
      column: $table.customerAddress, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discountAmount => $composableBuilder(
      column: $table.discountAmount, builder: (column) => column);

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get deliveryZone => $composableBuilder(
      column: $table.deliveryZone, builder: (column) => column);

  GeneratedColumn<double> get deliveryFee => $composableBuilder(
      column: $table.deliveryFee, builder: (column) => column);

  GeneratedColumn<String> get deliveryPaymentMethod => $composableBuilder(
      column: $table.deliveryPaymentMethod, builder: (column) => column);

  GeneratedColumn<double> get deliveryCashAmount => $composableBuilder(
      column: $table.deliveryCashAmount, builder: (column) => column);

  GeneratedColumn<String> get cancelReason => $composableBuilder(
      column: $table.cancelReason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TablesLayoutTableAnnotationComposer get tableId {
    final $$TablesLayoutTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tableId,
        referencedTable: $db.tablesLayout,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TablesLayoutTableAnnotationComposer(
              $db: $db,
              $table: $db.tablesLayout,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomersTableAnnotationComposer get customerId {
    final $$CustomersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.customerId,
        referencedTable: $db.customers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CustomersTableAnnotationComposer(
              $db: $db,
              $table: $db.customers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableAnnotationComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> orderItemsRefs<T extends Object>(
      Expression<T> Function($$OrderItemsTableAnnotationComposer a) f) {
    final $$OrderItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> paymentsRefs<T extends Object>(
      Expression<T> Function($$PaymentsTableAnnotationComposer a) f) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.payments,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.payments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> inventoryMovementsRefs<T extends Object>(
      Expression<T> Function($$InventoryMovementsTableAnnotationComposer a) f) {
    final $$InventoryMovementsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.inventoryMovements,
            getReferencedColumn: (t) => t.orderId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InventoryMovementsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.inventoryMovements,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> refundsRefs<T extends Object>(
      Expression<T> Function($$RefundsTableAnnotationComposer a) f) {
    final $$RefundsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableAnnotationComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ingredientMovementsRefs<T extends Object>(
      Expression<T> Function($$IngredientMovementsTableAnnotationComposer a)
          f) {
    final $$IngredientMovementsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientMovements,
            getReferencedColumn: (t) => t.orderId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientMovementsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientMovements,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> fiscalDocsRefs<T extends Object>(
      Expression<T> Function($$FiscalDocsTableAnnotationComposer a) f) {
    final $$FiscalDocsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fiscalDocs,
        getReferencedColumn: (t) => t.orderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalDocsTableAnnotationComposer(
              $db: $db,
              $table: $db.fiscalDocs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrdersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, $$OrdersTableReferences),
    Order,
    PrefetchHooks Function(
        {bool tableId,
        bool customerId,
        bool employeeId,
        bool shiftId,
        bool orderItemsRefs,
        bool paymentsRefs,
        bool inventoryMovementsRefs,
        bool refundsRefs,
        bool ingredientMovementsRefs,
        bool fiscalDocsRefs})> {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> orderNumber = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int?> tableId = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<int?> customerId = const Value.absent(),
            Value<String?> customerPhone = const Value.absent(),
            Value<String?> customerAddress = const Value.absent(),
            Value<int> employeeId = const Value.absent(),
            Value<int?> shiftId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> discountAmount = const Value.absent(),
            Value<double> taxAmount = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<String?> deliveryZone = const Value.absent(),
            Value<double> deliveryFee = const Value.absent(),
            Value<String?> deliveryPaymentMethod = const Value.absent(),
            Value<double?> deliveryCashAmount = const Value.absent(),
            Value<String?> cancelReason = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              OrdersCompanion(
            id: id,
            orderNumber: orderNumber,
            type: type,
            tableId: tableId,
            customerName: customerName,
            customerId: customerId,
            customerPhone: customerPhone,
            customerAddress: customerAddress,
            employeeId: employeeId,
            shiftId: shiftId,
            note: note,
            status: status,
            paymentStatus: paymentStatus,
            subtotal: subtotal,
            discountAmount: discountAmount,
            taxAmount: taxAmount,
            total: total,
            deliveryZone: deliveryZone,
            deliveryFee: deliveryFee,
            deliveryPaymentMethod: deliveryPaymentMethod,
            deliveryCashAmount: deliveryCashAmount,
            cancelReason: cancelReason,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            deletedAt: deletedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String orderNumber,
            required String type,
            Value<int?> tableId = const Value.absent(),
            Value<String?> customerName = const Value.absent(),
            Value<int?> customerId = const Value.absent(),
            Value<String?> customerPhone = const Value.absent(),
            Value<String?> customerAddress = const Value.absent(),
            required int employeeId,
            Value<int?> shiftId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> discountAmount = const Value.absent(),
            Value<double> taxAmount = const Value.absent(),
            Value<double> total = const Value.absent(),
            Value<String?> deliveryZone = const Value.absent(),
            Value<double> deliveryFee = const Value.absent(),
            Value<String?> deliveryPaymentMethod = const Value.absent(),
            Value<double?> deliveryCashAmount = const Value.absent(),
            Value<String?> cancelReason = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
          }) =>
              OrdersCompanion.insert(
            id: id,
            orderNumber: orderNumber,
            type: type,
            tableId: tableId,
            customerName: customerName,
            customerId: customerId,
            customerPhone: customerPhone,
            customerAddress: customerAddress,
            employeeId: employeeId,
            shiftId: shiftId,
            note: note,
            status: status,
            paymentStatus: paymentStatus,
            subtotal: subtotal,
            discountAmount: discountAmount,
            taxAmount: taxAmount,
            total: total,
            deliveryZone: deliveryZone,
            deliveryFee: deliveryFee,
            deliveryPaymentMethod: deliveryPaymentMethod,
            deliveryCashAmount: deliveryCashAmount,
            cancelReason: cancelReason,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            deletedAt: deletedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$OrdersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {tableId = false,
              customerId = false,
              employeeId = false,
              shiftId = false,
              orderItemsRefs = false,
              paymentsRefs = false,
              inventoryMovementsRefs = false,
              refundsRefs = false,
              ingredientMovementsRefs = false,
              fiscalDocsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (orderItemsRefs) db.orderItems,
                if (paymentsRefs) db.payments,
                if (inventoryMovementsRefs) db.inventoryMovements,
                if (refundsRefs) db.refunds,
                if (ingredientMovementsRefs) db.ingredientMovements,
                if (fiscalDocsRefs) db.fiscalDocs
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (tableId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tableId,
                    referencedTable: $$OrdersTableReferences._tableIdTable(db),
                    referencedColumn:
                        $$OrdersTableReferences._tableIdTable(db).id,
                  ) as T;
                }
                if (customerId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.customerId,
                    referencedTable:
                        $$OrdersTableReferences._customerIdTable(db),
                    referencedColumn:
                        $$OrdersTableReferences._customerIdTable(db).id,
                  ) as T;
                }
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$OrdersTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$OrdersTableReferences._employeeIdTable(db).id,
                  ) as T;
                }
                if (shiftId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.shiftId,
                    referencedTable: $$OrdersTableReferences._shiftIdTable(db),
                    referencedColumn:
                        $$OrdersTableReferences._shiftIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (orderItemsRefs)
                    await $_getPrefetchedData<Order, $OrdersTable, OrderItem>(
                        currentTable: table,
                        referencedTable:
                            $$OrdersTableReferences._orderItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrdersTableReferences(db, table, p0)
                                .orderItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orderId == item.id),
                        typedResults: items),
                  if (paymentsRefs)
                    await $_getPrefetchedData<Order, $OrdersTable, Payment>(
                        currentTable: table,
                        referencedTable:
                            $$OrdersTableReferences._paymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrdersTableReferences(db, table, p0).paymentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orderId == item.id),
                        typedResults: items),
                  if (inventoryMovementsRefs)
                    await $_getPrefetchedData<Order, $OrdersTable,
                            InventoryMovement>(
                        currentTable: table,
                        referencedTable: $$OrdersTableReferences
                            ._inventoryMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrdersTableReferences(db, table, p0)
                                .inventoryMovementsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orderId == item.id),
                        typedResults: items),
                  if (refundsRefs)
                    await $_getPrefetchedData<Order, $OrdersTable, Refund>(
                        currentTable: table,
                        referencedTable:
                            $$OrdersTableReferences._refundsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrdersTableReferences(db, table, p0).refundsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orderId == item.id),
                        typedResults: items),
                  if (ingredientMovementsRefs)
                    await $_getPrefetchedData<Order, $OrdersTable,
                            IngredientMovement>(
                        currentTable: table,
                        referencedTable: $$OrdersTableReferences
                            ._ingredientMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrdersTableReferences(db, table, p0)
                                .ingredientMovementsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orderId == item.id),
                        typedResults: items),
                  if (fiscalDocsRefs)
                    await $_getPrefetchedData<Order, $OrdersTable, FiscalDoc>(
                        currentTable: table,
                        referencedTable:
                            $$OrdersTableReferences._fiscalDocsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrdersTableReferences(db, table, p0)
                                .fiscalDocsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.orderId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$OrdersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrdersTable,
    Order,
    $$OrdersTableFilterComposer,
    $$OrdersTableOrderingComposer,
    $$OrdersTableAnnotationComposer,
    $$OrdersTableCreateCompanionBuilder,
    $$OrdersTableUpdateCompanionBuilder,
    (Order, $$OrdersTableReferences),
    Order,
    PrefetchHooks Function(
        {bool tableId,
        bool customerId,
        bool employeeId,
        bool shiftId,
        bool orderItemsRefs,
        bool paymentsRefs,
        bool inventoryMovementsRefs,
        bool refundsRefs,
        bool ingredientMovementsRefs,
        bool fiscalDocsRefs})>;
typedef $$OrderItemsTableCreateCompanionBuilder = OrderItemsCompanion Function({
  Value<int> id,
  required int orderId,
  required int productId,
  required String productName,
  required int quantity,
  required double unitPrice,
  Value<String?> modifiersJson,
  Value<String?> itemNote,
  Value<String> itemStatus,
});
typedef $$OrderItemsTableUpdateCompanionBuilder = OrderItemsCompanion Function({
  Value<int> id,
  Value<int> orderId,
  Value<int> productId,
  Value<String> productName,
  Value<int> quantity,
  Value<double> unitPrice,
  Value<String?> modifiersJson,
  Value<String?> itemNote,
  Value<String> itemStatus,
});

final class $$OrderItemsTableReferences
    extends BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItem> {
  $$OrderItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders
      .createAlias($_aliasNameGenerator(db.orderItems.orderId, db.orders.id));

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<int>('order_id')!;

    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.orderItems.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RefundsTable, List<Refund>> _refundsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.refunds,
          aliasName:
              $_aliasNameGenerator(db.orderItems.id, db.refunds.orderItemId));

  $$RefundsTableProcessedTableManager get refundsRefs {
    final manager = $$RefundsTableTableManager($_db, $_db.refunds)
        .filter((f) => f.orderItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_refundsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$OrderItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modifiersJson => $composableBuilder(
      column: $table.modifiersJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemNote => $composableBuilder(
      column: $table.itemNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemStatus => $composableBuilder(
      column: $table.itemStatus, builder: (column) => ColumnFilters(column));

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> refundsRefs(
      Expression<bool> Function($$RefundsTableFilterComposer f) f) {
    final $$RefundsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.orderItemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableFilterComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrderItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modifiersJson => $composableBuilder(
      column: $table.modifiersJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemNote => $composableBuilder(
      column: $table.itemNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemStatus => $composableBuilder(
      column: $table.itemStatus, builder: (column) => ColumnOrderings(column));

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableOrderingComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$OrderItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get modifiersJson => $composableBuilder(
      column: $table.modifiersJson, builder: (column) => column);

  GeneratedColumn<String> get itemNote =>
      $composableBuilder(column: $table.itemNote, builder: (column) => column);

  GeneratedColumn<String> get itemStatus => $composableBuilder(
      column: $table.itemStatus, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> refundsRefs<T extends Object>(
      Expression<T> Function($$RefundsTableAnnotationComposer a) f) {
    final $$RefundsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.refunds,
        getReferencedColumn: (t) => t.orderItemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RefundsTableAnnotationComposer(
              $db: $db,
              $table: $db.refunds,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$OrderItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrderItemsTable,
    OrderItem,
    $$OrderItemsTableFilterComposer,
    $$OrderItemsTableOrderingComposer,
    $$OrderItemsTableAnnotationComposer,
    $$OrderItemsTableCreateCompanionBuilder,
    $$OrderItemsTableUpdateCompanionBuilder,
    (OrderItem, $$OrderItemsTableReferences),
    OrderItem,
    PrefetchHooks Function({bool orderId, bool productId, bool refundsRefs})> {
  $$OrderItemsTableTableManager(_$AppDatabase db, $OrderItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> orderId = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<double> unitPrice = const Value.absent(),
            Value<String?> modifiersJson = const Value.absent(),
            Value<String?> itemNote = const Value.absent(),
            Value<String> itemStatus = const Value.absent(),
          }) =>
              OrderItemsCompanion(
            id: id,
            orderId: orderId,
            productId: productId,
            productName: productName,
            quantity: quantity,
            unitPrice: unitPrice,
            modifiersJson: modifiersJson,
            itemNote: itemNote,
            itemStatus: itemStatus,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int orderId,
            required int productId,
            required String productName,
            required int quantity,
            required double unitPrice,
            Value<String?> modifiersJson = const Value.absent(),
            Value<String?> itemNote = const Value.absent(),
            Value<String> itemStatus = const Value.absent(),
          }) =>
              OrderItemsCompanion.insert(
            id: id,
            orderId: orderId,
            productId: productId,
            productName: productName,
            quantity: quantity,
            unitPrice: unitPrice,
            modifiersJson: modifiersJson,
            itemNote: itemNote,
            itemStatus: itemStatus,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$OrderItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {orderId = false, productId = false, refundsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (refundsRefs) db.refunds],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (orderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderId,
                    referencedTable:
                        $$OrderItemsTableReferences._orderIdTable(db),
                    referencedColumn:
                        $$OrderItemsTableReferences._orderIdTable(db).id,
                  ) as T;
                }
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$OrderItemsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$OrderItemsTableReferences._productIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (refundsRefs)
                    await $_getPrefetchedData<OrderItem, $OrderItemsTable,
                            Refund>(
                        currentTable: table,
                        referencedTable:
                            $$OrderItemsTableReferences._refundsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$OrderItemsTableReferences(db, table, p0)
                                .refundsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.orderItemId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$OrderItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OrderItemsTable,
    OrderItem,
    $$OrderItemsTableFilterComposer,
    $$OrderItemsTableOrderingComposer,
    $$OrderItemsTableAnnotationComposer,
    $$OrderItemsTableCreateCompanionBuilder,
    $$OrderItemsTableUpdateCompanionBuilder,
    (OrderItem, $$OrderItemsTableReferences),
    OrderItem,
    PrefetchHooks Function({bool orderId, bool productId, bool refundsRefs})>;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  required int orderId,
  Value<int?> shiftId,
  required String method,
  required double amountTendered,
  Value<double> changeGiven,
  Value<String?> reference,
  Value<double> tipAmount,
  Value<DateTime> createdAt,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  Value<int> orderId,
  Value<int?> shiftId,
  Value<String> method,
  Value<double> amountTendered,
  Value<double> changeGiven,
  Value<String?> reference,
  Value<double> tipAmount,
  Value<DateTime> createdAt,
});

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, Payment> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders
      .createAlias($_aliasNameGenerator(db.payments.orderId, db.orders.id));

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<int>('order_id')!;

    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) => db.shifts
      .createAlias($_aliasNameGenerator(db.payments.shiftId, db.shifts.id));

  $$ShiftsTableProcessedTableManager? get shiftId {
    final $_column = $_itemColumn<int>('shift_id');
    if ($_column == null) return null;
    final manager = $$ShiftsTableTableManager($_db, $_db.shifts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amountTendered => $composableBuilder(
      column: $table.amountTendered,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get changeGiven => $composableBuilder(
      column: $table.changeGiven, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reference => $composableBuilder(
      column: $table.reference, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tipAmount => $composableBuilder(
      column: $table.tipAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableFilterComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amountTendered => $composableBuilder(
      column: $table.amountTendered,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get changeGiven => $composableBuilder(
      column: $table.changeGiven, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reference => $composableBuilder(
      column: $table.reference, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tipAmount => $composableBuilder(
      column: $table.tipAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableOrderingComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableOrderingComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<double> get amountTendered => $composableBuilder(
      column: $table.amountTendered, builder: (column) => column);

  GeneratedColumn<double> get changeGiven => $composableBuilder(
      column: $table.changeGiven, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<double> get tipAmount =>
      $composableBuilder(column: $table.tipAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableAnnotationComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, $$PaymentsTableReferences),
    Payment,
    PrefetchHooks Function({bool orderId, bool shiftId})> {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> orderId = const Value.absent(),
            Value<int?> shiftId = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<double> amountTendered = const Value.absent(),
            Value<double> changeGiven = const Value.absent(),
            Value<String?> reference = const Value.absent(),
            Value<double> tipAmount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PaymentsCompanion(
            id: id,
            orderId: orderId,
            shiftId: shiftId,
            method: method,
            amountTendered: amountTendered,
            changeGiven: changeGiven,
            reference: reference,
            tipAmount: tipAmount,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int orderId,
            Value<int?> shiftId = const Value.absent(),
            required String method,
            required double amountTendered,
            Value<double> changeGiven = const Value.absent(),
            Value<String?> reference = const Value.absent(),
            Value<double> tipAmount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PaymentsCompanion.insert(
            id: id,
            orderId: orderId,
            shiftId: shiftId,
            method: method,
            amountTendered: amountTendered,
            changeGiven: changeGiven,
            reference: reference,
            tipAmount: tipAmount,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PaymentsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({orderId = false, shiftId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (orderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderId,
                    referencedTable:
                        $$PaymentsTableReferences._orderIdTable(db),
                    referencedColumn:
                        $$PaymentsTableReferences._orderIdTable(db).id,
                  ) as T;
                }
                if (shiftId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.shiftId,
                    referencedTable:
                        $$PaymentsTableReferences._shiftIdTable(db),
                    referencedColumn:
                        $$PaymentsTableReferences._shiftIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PaymentsTable,
    Payment,
    $$PaymentsTableFilterComposer,
    $$PaymentsTableOrderingComposer,
    $$PaymentsTableAnnotationComposer,
    $$PaymentsTableCreateCompanionBuilder,
    $$PaymentsTableUpdateCompanionBuilder,
    (Payment, $$PaymentsTableReferences),
    Payment,
    PrefetchHooks Function({bool orderId, bool shiftId})>;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  required String category,
  required String description,
  required double amount,
  required DateTime date,
  Value<int?> createdById,
  Value<DateTime> createdAt,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  Value<String> category,
  Value<String> description,
  Value<double> amount,
  Value<DateTime> date,
  Value<int?> createdById,
  Value<DateTime> createdAt,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _createdByIdTable(_$AppDatabase db) =>
      db.employees.createAlias(
          $_aliasNameGenerator(db.expenses.createdById, db.employees.id));

  $$EmployeesTableProcessedTableManager? get createdById {
    final $_column = $_itemColumn<int>('created_by_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get createdById {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdById,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get createdById {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdById,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get createdById {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.createdById,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExpensesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, $$ExpensesTableReferences),
    Expense,
    PrefetchHooks Function({bool createdById})> {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int?> createdById = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExpensesCompanion(
            id: id,
            category: category,
            description: description,
            amount: amount,
            date: date,
            createdById: createdById,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String category,
            required String description,
            required double amount,
            required DateTime date,
            Value<int?> createdById = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExpensesCompanion.insert(
            id: id,
            category: category,
            description: description,
            amount: amount,
            date: date,
            createdById: createdById,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ExpensesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({createdById = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (createdById) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.createdById,
                    referencedTable:
                        $$ExpensesTableReferences._createdByIdTable(db),
                    referencedColumn:
                        $$ExpensesTableReferences._createdByIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ExpensesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExpensesTable,
    Expense,
    $$ExpensesTableFilterComposer,
    $$ExpensesTableOrderingComposer,
    $$ExpensesTableAnnotationComposer,
    $$ExpensesTableCreateCompanionBuilder,
    $$ExpensesTableUpdateCompanionBuilder,
    (Expense, $$ExpensesTableReferences),
    Expense,
    PrefetchHooks Function({bool createdById})>;
typedef $$InventoryMovementsTableCreateCompanionBuilder
    = InventoryMovementsCompanion Function({
  Value<int> id,
  required int productId,
  required int delta,
  required String reason,
  Value<String?> note,
  Value<int?> orderId,
  Value<DateTime> createdAt,
});
typedef $$InventoryMovementsTableUpdateCompanionBuilder
    = InventoryMovementsCompanion Function({
  Value<int> id,
  Value<int> productId,
  Value<int> delta,
  Value<String> reason,
  Value<String?> note,
  Value<int?> orderId,
  Value<DateTime> createdAt,
});

final class $$InventoryMovementsTableReferences extends BaseReferences<
    _$AppDatabase, $InventoryMovementsTable, InventoryMovement> {
  $$InventoryMovementsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias($_aliasNameGenerator(
          db.inventoryMovements.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders.createAlias(
      $_aliasNameGenerator(db.inventoryMovements.orderId, db.orders.id));

  $$OrdersTableProcessedTableManager? get orderId {
    final $_column = $_itemColumn<int>('order_id');
    if ($_column == null) return null;
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$InventoryMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryMovementsTable> {
  $$InventoryMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get delta => $composableBuilder(
      column: $table.delta, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InventoryMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryMovementsTable> {
  $$InventoryMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get delta => $composableBuilder(
      column: $table.delta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableOrderingComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InventoryMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryMovementsTable> {
  $$InventoryMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$InventoryMovementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryMovementsTable,
    InventoryMovement,
    $$InventoryMovementsTableFilterComposer,
    $$InventoryMovementsTableOrderingComposer,
    $$InventoryMovementsTableAnnotationComposer,
    $$InventoryMovementsTableCreateCompanionBuilder,
    $$InventoryMovementsTableUpdateCompanionBuilder,
    (InventoryMovement, $$InventoryMovementsTableReferences),
    InventoryMovement,
    PrefetchHooks Function({bool productId, bool orderId})> {
  $$InventoryMovementsTableTableManager(
      _$AppDatabase db, $InventoryMovementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryMovementsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<int> delta = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int?> orderId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              InventoryMovementsCompanion(
            id: id,
            productId: productId,
            delta: delta,
            reason: reason,
            note: note,
            orderId: orderId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int productId,
            required int delta,
            required String reason,
            Value<String?> note = const Value.absent(),
            Value<int?> orderId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              InventoryMovementsCompanion.insert(
            id: id,
            productId: productId,
            delta: delta,
            reason: reason,
            note: note,
            orderId: orderId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$InventoryMovementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productId = false, orderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$InventoryMovementsTableReferences._productIdTable(db),
                    referencedColumn: $$InventoryMovementsTableReferences
                        ._productIdTable(db)
                        .id,
                  ) as T;
                }
                if (orderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderId,
                    referencedTable:
                        $$InventoryMovementsTableReferences._orderIdTable(db),
                    referencedColumn: $$InventoryMovementsTableReferences
                        ._orderIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$InventoryMovementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventoryMovementsTable,
    InventoryMovement,
    $$InventoryMovementsTableFilterComposer,
    $$InventoryMovementsTableOrderingComposer,
    $$InventoryMovementsTableAnnotationComposer,
    $$InventoryMovementsTableCreateCompanionBuilder,
    $$InventoryMovementsTableUpdateCompanionBuilder,
    (InventoryMovement, $$InventoryMovementsTableReferences),
    InventoryMovement,
    PrefetchHooks Function({bool productId, bool orderId})>;
typedef $$AuditLogTableCreateCompanionBuilder = AuditLogCompanion Function({
  Value<int> id,
  Value<DateTime> ts,
  Value<int?> employeeId,
  required String action,
  Value<String?> entity,
  Value<int?> entityId,
  Value<String?> detailJson,
});
typedef $$AuditLogTableUpdateCompanionBuilder = AuditLogCompanion Function({
  Value<int> id,
  Value<DateTime> ts,
  Value<int?> employeeId,
  Value<String> action,
  Value<String?> entity,
  Value<int?> entityId,
  Value<String?> detailJson,
});

final class $$AuditLogTableReferences
    extends BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogData> {
  $$AuditLogTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias(
          $_aliasNameGenerator(db.auditLog.employeeId, db.employees.id));

  $$EmployeesTableProcessedTableManager? get employeeId {
    final $_column = $_itemColumn<int>('employee_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get ts => $composableBuilder(
      column: $table.ts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get detailJson => $composableBuilder(
      column: $table.detailJson, builder: (column) => ColumnFilters(column));

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get ts => $composableBuilder(
      column: $table.ts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get detailJson => $composableBuilder(
      column: $table.detailJson, builder: (column) => ColumnOrderings(column));

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<int> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get detailJson => $composableBuilder(
      column: $table.detailJson, builder: (column) => column);

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AuditLogTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AuditLogTable,
    AuditLogData,
    $$AuditLogTableFilterComposer,
    $$AuditLogTableOrderingComposer,
    $$AuditLogTableAnnotationComposer,
    $$AuditLogTableCreateCompanionBuilder,
    $$AuditLogTableUpdateCompanionBuilder,
    (AuditLogData, $$AuditLogTableReferences),
    AuditLogData,
    PrefetchHooks Function({bool employeeId})> {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> ts = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String?> entity = const Value.absent(),
            Value<int?> entityId = const Value.absent(),
            Value<String?> detailJson = const Value.absent(),
          }) =>
              AuditLogCompanion(
            id: id,
            ts: ts,
            employeeId: employeeId,
            action: action,
            entity: entity,
            entityId: entityId,
            detailJson: detailJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> ts = const Value.absent(),
            Value<int?> employeeId = const Value.absent(),
            required String action,
            Value<String?> entity = const Value.absent(),
            Value<int?> entityId = const Value.absent(),
            Value<String?> detailJson = const Value.absent(),
          }) =>
              AuditLogCompanion.insert(
            id: id,
            ts: ts,
            employeeId: employeeId,
            action: action,
            entity: entity,
            entityId: entityId,
            detailJson: detailJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AuditLogTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$AuditLogTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$AuditLogTableReferences._employeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AuditLogTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AuditLogTable,
    AuditLogData,
    $$AuditLogTableFilterComposer,
    $$AuditLogTableOrderingComposer,
    $$AuditLogTableAnnotationComposer,
    $$AuditLogTableCreateCompanionBuilder,
    $$AuditLogTableUpdateCompanionBuilder,
    (AuditLogData, $$AuditLogTableReferences),
    AuditLogData,
    PrefetchHooks Function({bool employeeId})>;
typedef $$CashMovementsTableCreateCompanionBuilder = CashMovementsCompanion
    Function({
  Value<int> id,
  required int shiftId,
  required int employeeId,
  required String type,
  required double amount,
  Value<String?> reason,
  Value<DateTime> ts,
});
typedef $$CashMovementsTableUpdateCompanionBuilder = CashMovementsCompanion
    Function({
  Value<int> id,
  Value<int> shiftId,
  Value<int> employeeId,
  Value<String> type,
  Value<double> amount,
  Value<String?> reason,
  Value<DateTime> ts,
});

final class $$CashMovementsTableReferences
    extends BaseReferences<_$AppDatabase, $CashMovementsTable, CashMovement> {
  $$CashMovementsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) => db.shifts.createAlias(
      $_aliasNameGenerator(db.cashMovements.shiftId, db.shifts.id));

  $$ShiftsTableProcessedTableManager get shiftId {
    final $_column = $_itemColumn<int>('shift_id')!;

    final manager = $$ShiftsTableTableManager($_db, $_db.shifts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias(
          $_aliasNameGenerator(db.cashMovements.employeeId, db.employees.id));

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CashMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get ts => $composableBuilder(
      column: $table.ts, builder: (column) => ColumnFilters(column));

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableFilterComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CashMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get ts => $composableBuilder(
      column: $table.ts, builder: (column) => ColumnOrderings(column));

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableOrderingComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CashMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableAnnotationComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CashMovementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CashMovementsTable,
    CashMovement,
    $$CashMovementsTableFilterComposer,
    $$CashMovementsTableOrderingComposer,
    $$CashMovementsTableAnnotationComposer,
    $$CashMovementsTableCreateCompanionBuilder,
    $$CashMovementsTableUpdateCompanionBuilder,
    (CashMovement, $$CashMovementsTableReferences),
    CashMovement,
    PrefetchHooks Function({bool shiftId, bool employeeId})> {
  $$CashMovementsTableTableManager(_$AppDatabase db, $CashMovementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> shiftId = const Value.absent(),
            Value<int> employeeId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<DateTime> ts = const Value.absent(),
          }) =>
              CashMovementsCompanion(
            id: id,
            shiftId: shiftId,
            employeeId: employeeId,
            type: type,
            amount: amount,
            reason: reason,
            ts: ts,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int shiftId,
            required int employeeId,
            required String type,
            required double amount,
            Value<String?> reason = const Value.absent(),
            Value<DateTime> ts = const Value.absent(),
          }) =>
              CashMovementsCompanion.insert(
            id: id,
            shiftId: shiftId,
            employeeId: employeeId,
            type: type,
            amount: amount,
            reason: reason,
            ts: ts,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CashMovementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({shiftId = false, employeeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (shiftId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.shiftId,
                    referencedTable:
                        $$CashMovementsTableReferences._shiftIdTable(db),
                    referencedColumn:
                        $$CashMovementsTableReferences._shiftIdTable(db).id,
                  ) as T;
                }
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$CashMovementsTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$CashMovementsTableReferences._employeeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CashMovementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CashMovementsTable,
    CashMovement,
    $$CashMovementsTableFilterComposer,
    $$CashMovementsTableOrderingComposer,
    $$CashMovementsTableAnnotationComposer,
    $$CashMovementsTableCreateCompanionBuilder,
    $$CashMovementsTableUpdateCompanionBuilder,
    (CashMovement, $$CashMovementsTableReferences),
    CashMovement,
    PrefetchHooks Function({bool shiftId, bool employeeId})>;
typedef $$RefundsTableCreateCompanionBuilder = RefundsCompanion Function({
  Value<int> id,
  required int orderId,
  Value<int?> orderItemId,
  Value<int?> shiftId,
  required double amount,
  Value<String?> reason,
  Value<bool> restocked,
  required int employeeId,
  Value<int?> supervisorId,
  Value<DateTime> ts,
});
typedef $$RefundsTableUpdateCompanionBuilder = RefundsCompanion Function({
  Value<int> id,
  Value<int> orderId,
  Value<int?> orderItemId,
  Value<int?> shiftId,
  Value<double> amount,
  Value<String?> reason,
  Value<bool> restocked,
  Value<int> employeeId,
  Value<int?> supervisorId,
  Value<DateTime> ts,
});

final class $$RefundsTableReferences
    extends BaseReferences<_$AppDatabase, $RefundsTable, Refund> {
  $$RefundsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders
      .createAlias($_aliasNameGenerator(db.refunds.orderId, db.orders.id));

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<int>('order_id')!;

    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $OrderItemsTable _orderItemIdTable(_$AppDatabase db) =>
      db.orderItems.createAlias(
          $_aliasNameGenerator(db.refunds.orderItemId, db.orderItems.id));

  $$OrderItemsTableProcessedTableManager? get orderItemId {
    final $_column = $_itemColumn<int>('order_item_id');
    if ($_column == null) return null;
    final manager = $$OrderItemsTableTableManager($_db, $_db.orderItems)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ShiftsTable _shiftIdTable(_$AppDatabase db) => db.shifts
      .createAlias($_aliasNameGenerator(db.refunds.shiftId, db.shifts.id));

  $$ShiftsTableProcessedTableManager? get shiftId {
    final $_column = $_itemColumn<int>('shift_id');
    if ($_column == null) return null;
    final manager = $$ShiftsTableTableManager($_db, $_db.shifts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias(
          $_aliasNameGenerator(db.refunds.employeeId, db.employees.id));

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _supervisorIdTable(_$AppDatabase db) =>
      db.employees.createAlias(
          $_aliasNameGenerator(db.refunds.supervisorId, db.employees.id));

  $$EmployeesTableProcessedTableManager? get supervisorId {
    final $_column = $_itemColumn<int>('supervisor_id');
    if ($_column == null) return null;
    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supervisorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RefundsTableFilterComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get restocked => $composableBuilder(
      column: $table.restocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get ts => $composableBuilder(
      column: $table.ts, builder: (column) => ColumnFilters(column));

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrderItemsTableFilterComposer get orderItemId {
    final $$OrderItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderItemId,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableFilterComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShiftsTableFilterComposer get shiftId {
    final $$ShiftsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableFilterComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get supervisorId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supervisorId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RefundsTableOrderingComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get restocked => $composableBuilder(
      column: $table.restocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get ts => $composableBuilder(
      column: $table.ts, builder: (column) => ColumnOrderings(column));

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableOrderingComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrderItemsTableOrderingComposer get orderItemId {
    final $$OrderItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderItemId,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableOrderingComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShiftsTableOrderingComposer get shiftId {
    final $$ShiftsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableOrderingComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get supervisorId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supervisorId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RefundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<bool> get restocked =>
      $composableBuilder(column: $table.restocked, builder: (column) => column);

  GeneratedColumn<DateTime> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrderItemsTableAnnotationComposer get orderItemId {
    final $$OrderItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderItemId,
        referencedTable: $db.orderItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrderItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.orderItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ShiftsTableAnnotationComposer get shiftId {
    final $$ShiftsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shiftId,
        referencedTable: $db.shifts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShiftsTableAnnotationComposer(
              $db: $db,
              $table: $db.shifts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get supervisorId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supervisorId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RefundsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RefundsTable,
    Refund,
    $$RefundsTableFilterComposer,
    $$RefundsTableOrderingComposer,
    $$RefundsTableAnnotationComposer,
    $$RefundsTableCreateCompanionBuilder,
    $$RefundsTableUpdateCompanionBuilder,
    (Refund, $$RefundsTableReferences),
    Refund,
    PrefetchHooks Function(
        {bool orderId,
        bool orderItemId,
        bool shiftId,
        bool employeeId,
        bool supervisorId})> {
  $$RefundsTableTableManager(_$AppDatabase db, $RefundsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RefundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> orderId = const Value.absent(),
            Value<int?> orderItemId = const Value.absent(),
            Value<int?> shiftId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<bool> restocked = const Value.absent(),
            Value<int> employeeId = const Value.absent(),
            Value<int?> supervisorId = const Value.absent(),
            Value<DateTime> ts = const Value.absent(),
          }) =>
              RefundsCompanion(
            id: id,
            orderId: orderId,
            orderItemId: orderItemId,
            shiftId: shiftId,
            amount: amount,
            reason: reason,
            restocked: restocked,
            employeeId: employeeId,
            supervisorId: supervisorId,
            ts: ts,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int orderId,
            Value<int?> orderItemId = const Value.absent(),
            Value<int?> shiftId = const Value.absent(),
            required double amount,
            Value<String?> reason = const Value.absent(),
            Value<bool> restocked = const Value.absent(),
            required int employeeId,
            Value<int?> supervisorId = const Value.absent(),
            Value<DateTime> ts = const Value.absent(),
          }) =>
              RefundsCompanion.insert(
            id: id,
            orderId: orderId,
            orderItemId: orderItemId,
            shiftId: shiftId,
            amount: amount,
            reason: reason,
            restocked: restocked,
            employeeId: employeeId,
            supervisorId: supervisorId,
            ts: ts,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RefundsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {orderId = false,
              orderItemId = false,
              shiftId = false,
              employeeId = false,
              supervisorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (orderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderId,
                    referencedTable: $$RefundsTableReferences._orderIdTable(db),
                    referencedColumn:
                        $$RefundsTableReferences._orderIdTable(db).id,
                  ) as T;
                }
                if (orderItemId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderItemId,
                    referencedTable:
                        $$RefundsTableReferences._orderItemIdTable(db),
                    referencedColumn:
                        $$RefundsTableReferences._orderItemIdTable(db).id,
                  ) as T;
                }
                if (shiftId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.shiftId,
                    referencedTable: $$RefundsTableReferences._shiftIdTable(db),
                    referencedColumn:
                        $$RefundsTableReferences._shiftIdTable(db).id,
                  ) as T;
                }
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable:
                        $$RefundsTableReferences._employeeIdTable(db),
                    referencedColumn:
                        $$RefundsTableReferences._employeeIdTable(db).id,
                  ) as T;
                }
                if (supervisorId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.supervisorId,
                    referencedTable:
                        $$RefundsTableReferences._supervisorIdTable(db),
                    referencedColumn:
                        $$RefundsTableReferences._supervisorIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RefundsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RefundsTable,
    Refund,
    $$RefundsTableFilterComposer,
    $$RefundsTableOrderingComposer,
    $$RefundsTableAnnotationComposer,
    $$RefundsTableCreateCompanionBuilder,
    $$RefundsTableUpdateCompanionBuilder,
    (Refund, $$RefundsTableReferences),
    Refund,
    PrefetchHooks Function(
        {bool orderId,
        bool orderItemId,
        bool shiftId,
        bool employeeId,
        bool supervisorId})>;
typedef $$SuppliersTableCreateCompanionBuilder = SuppliersCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> contactName,
  Value<String?> phone,
  Value<String?> note,
  Value<bool> active,
  Value<DateTime> createdAt,
});
typedef $$SuppliersTableUpdateCompanionBuilder = SuppliersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> contactName,
  Value<String?> phone,
  Value<String?> note,
  Value<bool> active,
  Value<DateTime> createdAt,
});

final class $$SuppliersTableReferences
    extends BaseReferences<_$AppDatabase, $SuppliersTable, Supplier> {
  $$SuppliersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IngredientPurchasesTable,
      List<IngredientPurchase>> _ingredientPurchasesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.ingredientPurchases,
          aliasName: $_aliasNameGenerator(
              db.suppliers.id, db.ingredientPurchases.supplierId));

  $$IngredientPurchasesTableProcessedTableManager get ingredientPurchasesRefs {
    final manager =
        $$IngredientPurchasesTableTableManager($_db, $_db.ingredientPurchases)
            .filter((f) => f.supplierId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientPurchasesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SuppliersTableFilterComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactName => $composableBuilder(
      column: $table.contactName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> ingredientPurchasesRefs(
      Expression<bool> Function($$IngredientPurchasesTableFilterComposer f) f) {
    final $$IngredientPurchasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredientPurchases,
        getReferencedColumn: (t) => t.supplierId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientPurchasesTableFilterComposer(
              $db: $db,
              $table: $db.ingredientPurchases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SuppliersTableOrderingComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactName => $composableBuilder(
      column: $table.contactName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SuppliersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get contactName => $composableBuilder(
      column: $table.contactName, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> ingredientPurchasesRefs<T extends Object>(
      Expression<T> Function($$IngredientPurchasesTableAnnotationComposer a)
          f) {
    final $$IngredientPurchasesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientPurchases,
            getReferencedColumn: (t) => t.supplierId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientPurchasesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientPurchases,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SuppliersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SuppliersTable,
    Supplier,
    $$SuppliersTableFilterComposer,
    $$SuppliersTableOrderingComposer,
    $$SuppliersTableAnnotationComposer,
    $$SuppliersTableCreateCompanionBuilder,
    $$SuppliersTableUpdateCompanionBuilder,
    (Supplier, $$SuppliersTableReferences),
    Supplier,
    PrefetchHooks Function({bool ingredientPurchasesRefs})> {
  $$SuppliersTableTableManager(_$AppDatabase db, $SuppliersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuppliersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuppliersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuppliersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> contactName = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SuppliersCompanion(
            id: id,
            name: name,
            contactName: contactName,
            phone: phone,
            note: note,
            active: active,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> contactName = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SuppliersCompanion.insert(
            id: id,
            name: name,
            contactName: contactName,
            phone: phone,
            note: note,
            active: active,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SuppliersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({ingredientPurchasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ingredientPurchasesRefs) db.ingredientPurchases
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientPurchasesRefs)
                    await $_getPrefetchedData<Supplier, $SuppliersTable,
                            IngredientPurchase>(
                        currentTable: table,
                        referencedTable: $$SuppliersTableReferences
                            ._ingredientPurchasesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SuppliersTableReferences(db, table, p0)
                                .ingredientPurchasesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.supplierId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SuppliersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SuppliersTable,
    Supplier,
    $$SuppliersTableFilterComposer,
    $$SuppliersTableOrderingComposer,
    $$SuppliersTableAnnotationComposer,
    $$SuppliersTableCreateCompanionBuilder,
    $$SuppliersTableUpdateCompanionBuilder,
    (Supplier, $$SuppliersTableReferences),
    Supplier,
    PrefetchHooks Function({bool ingredientPurchasesRefs})>;
typedef $$IngredientsTableCreateCompanionBuilder = IngredientsCompanion
    Function({
  Value<int> id,
  required String name,
  required String unit,
  Value<double> stockQuantity,
  Value<double> minStock,
  Value<double?> lastUnitCost,
  Value<bool> active,
  Value<DateTime> createdAt,
});
typedef $$IngredientsTableUpdateCompanionBuilder = IngredientsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String> unit,
  Value<double> stockQuantity,
  Value<double> minStock,
  Value<double?> lastUnitCost,
  Value<bool> active,
  Value<DateTime> createdAt,
});

final class $$IngredientsTableReferences
    extends BaseReferences<_$AppDatabase, $IngredientsTable, Ingredient> {
  $$IngredientsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IngredientMovementsTable,
      List<IngredientMovement>> _ingredientMovementsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.ingredientMovements,
          aliasName: $_aliasNameGenerator(
              db.ingredients.id, db.ingredientMovements.ingredientId));

  $$IngredientMovementsTableProcessedTableManager get ingredientMovementsRefs {
    final manager = $$IngredientMovementsTableTableManager(
            $_db, $_db.ingredientMovements)
        .filter((f) => f.ingredientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IngredientPurchaseItemsTable,
      List<IngredientPurchaseItem>> _ingredientPurchaseItemsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.ingredientPurchaseItems,
          aliasName: $_aliasNameGenerator(
              db.ingredients.id, db.ingredientPurchaseItems.ingredientId));

  $$IngredientPurchaseItemsTableProcessedTableManager
      get ingredientPurchaseItemsRefs {
    final manager = $$IngredientPurchaseItemsTableTableManager(
            $_db, $_db.ingredientPurchaseItems)
        .filter((f) => f.ingredientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientPurchaseItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecipeItemsTable, List<RecipeItem>>
      _recipeItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recipeItems,
              aliasName: $_aliasNameGenerator(
                  db.ingredients.id, db.recipeItems.ingredientId));

  $$RecipeItemsTableProcessedTableManager get recipeItemsRefs {
    final manager = $$RecipeItemsTableTableManager($_db, $_db.recipeItems)
        .filter((f) => f.ingredientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recipeItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$IngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minStock => $composableBuilder(
      column: $table.minStock, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lastUnitCost => $composableBuilder(
      column: $table.lastUnitCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> ingredientMovementsRefs(
      Expression<bool> Function($$IngredientMovementsTableFilterComposer f) f) {
    final $$IngredientMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredientMovements,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientMovementsTableFilterComposer(
              $db: $db,
              $table: $db.ingredientMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ingredientPurchaseItemsRefs(
      Expression<bool> Function($$IngredientPurchaseItemsTableFilterComposer f)
          f) {
    final $$IngredientPurchaseItemsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientPurchaseItems,
            getReferencedColumn: (t) => t.ingredientId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientPurchaseItemsTableFilterComposer(
                  $db: $db,
                  $table: $db.ingredientPurchaseItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> recipeItemsRefs(
      Expression<bool> Function($$RecipeItemsTableFilterComposer f) f) {
    final $$RecipeItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeItems,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeItemsTableFilterComposer(
              $db: $db,
              $table: $db.recipeItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minStock => $composableBuilder(
      column: $table.minStock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lastUnitCost => $composableBuilder(
      column: $table.lastUnitCost,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$IngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientsTable> {
  $$IngredientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity, builder: (column) => column);

  GeneratedColumn<double> get minStock =>
      $composableBuilder(column: $table.minStock, builder: (column) => column);

  GeneratedColumn<double> get lastUnitCost => $composableBuilder(
      column: $table.lastUnitCost, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> ingredientMovementsRefs<T extends Object>(
      Expression<T> Function($$IngredientMovementsTableAnnotationComposer a)
          f) {
    final $$IngredientMovementsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientMovements,
            getReferencedColumn: (t) => t.ingredientId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientMovementsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientMovements,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> ingredientPurchaseItemsRefs<T extends Object>(
      Expression<T> Function($$IngredientPurchaseItemsTableAnnotationComposer a)
          f) {
    final $$IngredientPurchaseItemsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientPurchaseItems,
            getReferencedColumn: (t) => t.ingredientId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientPurchaseItemsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientPurchaseItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> recipeItemsRefs<T extends Object>(
      Expression<T> Function($$RecipeItemsTableAnnotationComposer a) f) {
    final $$RecipeItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeItems,
        getReferencedColumn: (t) => t.ingredientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.recipeItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$IngredientsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IngredientsTable,
    Ingredient,
    $$IngredientsTableFilterComposer,
    $$IngredientsTableOrderingComposer,
    $$IngredientsTableAnnotationComposer,
    $$IngredientsTableCreateCompanionBuilder,
    $$IngredientsTableUpdateCompanionBuilder,
    (Ingredient, $$IngredientsTableReferences),
    Ingredient,
    PrefetchHooks Function(
        {bool ingredientMovementsRefs,
        bool ingredientPurchaseItemsRefs,
        bool recipeItemsRefs})> {
  $$IngredientsTableTableManager(_$AppDatabase db, $IngredientsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double> stockQuantity = const Value.absent(),
            Value<double> minStock = const Value.absent(),
            Value<double?> lastUnitCost = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              IngredientsCompanion(
            id: id,
            name: name,
            unit: unit,
            stockQuantity: stockQuantity,
            minStock: minStock,
            lastUnitCost: lastUnitCost,
            active: active,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String unit,
            Value<double> stockQuantity = const Value.absent(),
            Value<double> minStock = const Value.absent(),
            Value<double?> lastUnitCost = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              IngredientsCompanion.insert(
            id: id,
            name: name,
            unit: unit,
            stockQuantity: stockQuantity,
            minStock: minStock,
            lastUnitCost: lastUnitCost,
            active: active,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IngredientsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {ingredientMovementsRefs = false,
              ingredientPurchaseItemsRefs = false,
              recipeItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ingredientMovementsRefs) db.ingredientMovements,
                if (ingredientPurchaseItemsRefs) db.ingredientPurchaseItems,
                if (recipeItemsRefs) db.recipeItems
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientMovementsRefs)
                    await $_getPrefetchedData<Ingredient, $IngredientsTable, IngredientMovement>(
                        currentTable: table,
                        referencedTable: $$IngredientsTableReferences
                            ._ingredientMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientsTableReferences(db, table, p0)
                                .ingredientMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ingredientId == item.id),
                        typedResults: items),
                  if (ingredientPurchaseItemsRefs)
                    await $_getPrefetchedData<Ingredient, $IngredientsTable,
                            IngredientPurchaseItem>(
                        currentTable: table,
                        referencedTable: $$IngredientsTableReferences
                            ._ingredientPurchaseItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientsTableReferences(db, table, p0)
                                .ingredientPurchaseItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ingredientId == item.id),
                        typedResults: items),
                  if (recipeItemsRefs)
                    await $_getPrefetchedData<Ingredient, $IngredientsTable,
                            RecipeItem>(
                        currentTable: table,
                        referencedTable: $$IngredientsTableReferences
                            ._recipeItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientsTableReferences(db, table, p0)
                                .recipeItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.ingredientId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$IngredientsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IngredientsTable,
    Ingredient,
    $$IngredientsTableFilterComposer,
    $$IngredientsTableOrderingComposer,
    $$IngredientsTableAnnotationComposer,
    $$IngredientsTableCreateCompanionBuilder,
    $$IngredientsTableUpdateCompanionBuilder,
    (Ingredient, $$IngredientsTableReferences),
    Ingredient,
    PrefetchHooks Function(
        {bool ingredientMovementsRefs,
        bool ingredientPurchaseItemsRefs,
        bool recipeItemsRefs})>;
typedef $$IngredientPurchasesTableCreateCompanionBuilder
    = IngredientPurchasesCompanion Function({
  Value<int> id,
  Value<int?> supplierId,
  required int employeeId,
  Value<double> totalCost,
  Value<String?> note,
  Value<DateTime> createdAt,
});
typedef $$IngredientPurchasesTableUpdateCompanionBuilder
    = IngredientPurchasesCompanion Function({
  Value<int> id,
  Value<int?> supplierId,
  Value<int> employeeId,
  Value<double> totalCost,
  Value<String?> note,
  Value<DateTime> createdAt,
});

final class $$IngredientPurchasesTableReferences extends BaseReferences<
    _$AppDatabase, $IngredientPurchasesTable, IngredientPurchase> {
  $$IngredientPurchasesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SuppliersTable _supplierIdTable(_$AppDatabase db) =>
      db.suppliers.createAlias($_aliasNameGenerator(
          db.ingredientPurchases.supplierId, db.suppliers.id));

  $$SuppliersTableProcessedTableManager? get supplierId {
    final $_column = $_itemColumn<int>('supplier_id');
    if ($_column == null) return null;
    final manager = $$SuppliersTableTableManager($_db, $_db.suppliers)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supplierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EmployeesTable _employeeIdTable(_$AppDatabase db) =>
      db.employees.createAlias($_aliasNameGenerator(
          db.ingredientPurchases.employeeId, db.employees.id));

  $$EmployeesTableProcessedTableManager get employeeId {
    final $_column = $_itemColumn<int>('employee_id')!;

    final manager = $$EmployeesTableTableManager($_db, $_db.employees)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employeeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$IngredientMovementsTable,
      List<IngredientMovement>> _ingredientMovementsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.ingredientMovements,
          aliasName: $_aliasNameGenerator(
              db.ingredientPurchases.id, db.ingredientMovements.purchaseId));

  $$IngredientMovementsTableProcessedTableManager get ingredientMovementsRefs {
    final manager =
        $$IngredientMovementsTableTableManager($_db, $_db.ingredientMovements)
            .filter((f) => f.purchaseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientMovementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$IngredientPurchaseItemsTable,
      List<IngredientPurchaseItem>> _ingredientPurchaseItemsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.ingredientPurchaseItems,
          aliasName: $_aliasNameGenerator(db.ingredientPurchases.id,
              db.ingredientPurchaseItems.purchaseId));

  $$IngredientPurchaseItemsTableProcessedTableManager
      get ingredientPurchaseItemsRefs {
    final manager = $$IngredientPurchaseItemsTableTableManager(
            $_db, $_db.ingredientPurchaseItems)
        .filter((f) => f.purchaseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ingredientPurchaseItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$IngredientPurchasesTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientPurchasesTable> {
  $$IngredientPurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalCost => $composableBuilder(
      column: $table.totalCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SuppliersTableFilterComposer get supplierId {
    final $$SuppliersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supplierId,
        referencedTable: $db.suppliers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SuppliersTableFilterComposer(
              $db: $db,
              $table: $db.suppliers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableFilterComposer get employeeId {
    final $$EmployeesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableFilterComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> ingredientMovementsRefs(
      Expression<bool> Function($$IngredientMovementsTableFilterComposer f) f) {
    final $$IngredientMovementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.ingredientMovements,
        getReferencedColumn: (t) => t.purchaseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientMovementsTableFilterComposer(
              $db: $db,
              $table: $db.ingredientMovements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ingredientPurchaseItemsRefs(
      Expression<bool> Function($$IngredientPurchaseItemsTableFilterComposer f)
          f) {
    final $$IngredientPurchaseItemsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientPurchaseItems,
            getReferencedColumn: (t) => t.purchaseId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientPurchaseItemsTableFilterComposer(
                  $db: $db,
                  $table: $db.ingredientPurchaseItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$IngredientPurchasesTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientPurchasesTable> {
  $$IngredientPurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalCost => $composableBuilder(
      column: $table.totalCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SuppliersTableOrderingComposer get supplierId {
    final $$SuppliersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supplierId,
        referencedTable: $db.suppliers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SuppliersTableOrderingComposer(
              $db: $db,
              $table: $db.suppliers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableOrderingComposer get employeeId {
    final $$EmployeesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableOrderingComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientPurchasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientPurchasesTable> {
  $$IngredientPurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get totalCost =>
      $composableBuilder(column: $table.totalCost, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SuppliersTableAnnotationComposer get supplierId {
    final $$SuppliersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.supplierId,
        referencedTable: $db.suppliers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SuppliersTableAnnotationComposer(
              $db: $db,
              $table: $db.suppliers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EmployeesTableAnnotationComposer get employeeId {
    final $$EmployeesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.employeeId,
        referencedTable: $db.employees,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EmployeesTableAnnotationComposer(
              $db: $db,
              $table: $db.employees,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> ingredientMovementsRefs<T extends Object>(
      Expression<T> Function($$IngredientMovementsTableAnnotationComposer a)
          f) {
    final $$IngredientMovementsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientMovements,
            getReferencedColumn: (t) => t.purchaseId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientMovementsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientMovements,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> ingredientPurchaseItemsRefs<T extends Object>(
      Expression<T> Function($$IngredientPurchaseItemsTableAnnotationComposer a)
          f) {
    final $$IngredientPurchaseItemsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.ingredientPurchaseItems,
            getReferencedColumn: (t) => t.purchaseId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientPurchaseItemsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientPurchaseItems,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$IngredientPurchasesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IngredientPurchasesTable,
    IngredientPurchase,
    $$IngredientPurchasesTableFilterComposer,
    $$IngredientPurchasesTableOrderingComposer,
    $$IngredientPurchasesTableAnnotationComposer,
    $$IngredientPurchasesTableCreateCompanionBuilder,
    $$IngredientPurchasesTableUpdateCompanionBuilder,
    (IngredientPurchase, $$IngredientPurchasesTableReferences),
    IngredientPurchase,
    PrefetchHooks Function(
        {bool supplierId,
        bool employeeId,
        bool ingredientMovementsRefs,
        bool ingredientPurchaseItemsRefs})> {
  $$IngredientPurchasesTableTableManager(
      _$AppDatabase db, $IngredientPurchasesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientPurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientPurchasesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientPurchasesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> supplierId = const Value.absent(),
            Value<int> employeeId = const Value.absent(),
            Value<double> totalCost = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              IngredientPurchasesCompanion(
            id: id,
            supplierId: supplierId,
            employeeId: employeeId,
            totalCost: totalCost,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> supplierId = const Value.absent(),
            required int employeeId,
            Value<double> totalCost = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              IngredientPurchasesCompanion.insert(
            id: id,
            supplierId: supplierId,
            employeeId: employeeId,
            totalCost: totalCost,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IngredientPurchasesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {supplierId = false,
              employeeId = false,
              ingredientMovementsRefs = false,
              ingredientPurchaseItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (ingredientMovementsRefs) db.ingredientMovements,
                if (ingredientPurchaseItemsRefs) db.ingredientPurchaseItems
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (supplierId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.supplierId,
                    referencedTable: $$IngredientPurchasesTableReferences
                        ._supplierIdTable(db),
                    referencedColumn: $$IngredientPurchasesTableReferences
                        ._supplierIdTable(db)
                        .id,
                  ) as T;
                }
                if (employeeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.employeeId,
                    referencedTable: $$IngredientPurchasesTableReferences
                        ._employeeIdTable(db),
                    referencedColumn: $$IngredientPurchasesTableReferences
                        ._employeeIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ingredientMovementsRefs)
                    await $_getPrefetchedData<IngredientPurchase,
                            $IngredientPurchasesTable, IngredientMovement>(
                        currentTable: table,
                        referencedTable: $$IngredientPurchasesTableReferences
                            ._ingredientMovementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientPurchasesTableReferences(db, table, p0)
                                .ingredientMovementsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.purchaseId == item.id),
                        typedResults: items),
                  if (ingredientPurchaseItemsRefs)
                    await $_getPrefetchedData<IngredientPurchase,
                            $IngredientPurchasesTable, IngredientPurchaseItem>(
                        currentTable: table,
                        referencedTable: $$IngredientPurchasesTableReferences
                            ._ingredientPurchaseItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$IngredientPurchasesTableReferences(db, table, p0)
                                .ingredientPurchaseItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.purchaseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$IngredientPurchasesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IngredientPurchasesTable,
    IngredientPurchase,
    $$IngredientPurchasesTableFilterComposer,
    $$IngredientPurchasesTableOrderingComposer,
    $$IngredientPurchasesTableAnnotationComposer,
    $$IngredientPurchasesTableCreateCompanionBuilder,
    $$IngredientPurchasesTableUpdateCompanionBuilder,
    (IngredientPurchase, $$IngredientPurchasesTableReferences),
    IngredientPurchase,
    PrefetchHooks Function(
        {bool supplierId,
        bool employeeId,
        bool ingredientMovementsRefs,
        bool ingredientPurchaseItemsRefs})>;
typedef $$IngredientMovementsTableCreateCompanionBuilder
    = IngredientMovementsCompanion Function({
  Value<int> id,
  required int ingredientId,
  required double delta,
  required String reason,
  Value<String?> note,
  Value<int?> orderId,
  Value<int?> purchaseId,
  Value<DateTime> createdAt,
});
typedef $$IngredientMovementsTableUpdateCompanionBuilder
    = IngredientMovementsCompanion Function({
  Value<int> id,
  Value<int> ingredientId,
  Value<double> delta,
  Value<String> reason,
  Value<String?> note,
  Value<int?> orderId,
  Value<int?> purchaseId,
  Value<DateTime> createdAt,
});

final class $$IngredientMovementsTableReferences extends BaseReferences<
    _$AppDatabase, $IngredientMovementsTable, IngredientMovement> {
  $$IngredientMovementsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $IngredientsTable _ingredientIdTable(_$AppDatabase db) =>
      db.ingredients.createAlias($_aliasNameGenerator(
          db.ingredientMovements.ingredientId, db.ingredients.id));

  $$IngredientsTableProcessedTableManager get ingredientId {
    final $_column = $_itemColumn<int>('ingredient_id')!;

    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders.createAlias(
      $_aliasNameGenerator(db.ingredientMovements.orderId, db.orders.id));

  $$OrdersTableProcessedTableManager? get orderId {
    final $_column = $_itemColumn<int>('order_id');
    if ($_column == null) return null;
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $IngredientPurchasesTable _purchaseIdTable(_$AppDatabase db) =>
      db.ingredientPurchases.createAlias($_aliasNameGenerator(
          db.ingredientMovements.purchaseId, db.ingredientPurchases.id));

  $$IngredientPurchasesTableProcessedTableManager? get purchaseId {
    final $_column = $_itemColumn<int>('purchase_id');
    if ($_column == null) return null;
    final manager =
        $$IngredientPurchasesTableTableManager($_db, $_db.ingredientPurchases)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_purchaseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IngredientMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientMovementsTable> {
  $$IngredientMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get delta => $composableBuilder(
      column: $table.delta, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientPurchasesTableFilterComposer get purchaseId {
    final $$IngredientPurchasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.purchaseId,
        referencedTable: $db.ingredientPurchases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientPurchasesTableFilterComposer(
              $db: $db,
              $table: $db.ingredientPurchases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientMovementsTable> {
  $$IngredientMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get delta => $composableBuilder(
      column: $table.delta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableOrderingComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableOrderingComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientPurchasesTableOrderingComposer get purchaseId {
    final $$IngredientPurchasesTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.purchaseId,
            referencedTable: $db.ingredientPurchases,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientPurchasesTableOrderingComposer(
                  $db: $db,
                  $table: $db.ingredientPurchases,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$IngredientMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientMovementsTable> {
  $$IngredientMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientPurchasesTableAnnotationComposer get purchaseId {
    final $$IngredientPurchasesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.purchaseId,
            referencedTable: $db.ingredientPurchases,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientPurchasesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientPurchases,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$IngredientMovementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IngredientMovementsTable,
    IngredientMovement,
    $$IngredientMovementsTableFilterComposer,
    $$IngredientMovementsTableOrderingComposer,
    $$IngredientMovementsTableAnnotationComposer,
    $$IngredientMovementsTableCreateCompanionBuilder,
    $$IngredientMovementsTableUpdateCompanionBuilder,
    (IngredientMovement, $$IngredientMovementsTableReferences),
    IngredientMovement,
    PrefetchHooks Function(
        {bool ingredientId, bool orderId, bool purchaseId})> {
  $$IngredientMovementsTableTableManager(
      _$AppDatabase db, $IngredientMovementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientMovementsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientMovementsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> ingredientId = const Value.absent(),
            Value<double> delta = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int?> orderId = const Value.absent(),
            Value<int?> purchaseId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              IngredientMovementsCompanion(
            id: id,
            ingredientId: ingredientId,
            delta: delta,
            reason: reason,
            note: note,
            orderId: orderId,
            purchaseId: purchaseId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int ingredientId,
            required double delta,
            required String reason,
            Value<String?> note = const Value.absent(),
            Value<int?> orderId = const Value.absent(),
            Value<int?> purchaseId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              IngredientMovementsCompanion.insert(
            id: id,
            ingredientId: ingredientId,
            delta: delta,
            reason: reason,
            note: note,
            orderId: orderId,
            purchaseId: purchaseId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IngredientMovementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {ingredientId = false, orderId = false, purchaseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (ingredientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientId,
                    referencedTable: $$IngredientMovementsTableReferences
                        ._ingredientIdTable(db),
                    referencedColumn: $$IngredientMovementsTableReferences
                        ._ingredientIdTable(db)
                        .id,
                  ) as T;
                }
                if (orderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderId,
                    referencedTable:
                        $$IngredientMovementsTableReferences._orderIdTable(db),
                    referencedColumn: $$IngredientMovementsTableReferences
                        ._orderIdTable(db)
                        .id,
                  ) as T;
                }
                if (purchaseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.purchaseId,
                    referencedTable: $$IngredientMovementsTableReferences
                        ._purchaseIdTable(db),
                    referencedColumn: $$IngredientMovementsTableReferences
                        ._purchaseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IngredientMovementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IngredientMovementsTable,
    IngredientMovement,
    $$IngredientMovementsTableFilterComposer,
    $$IngredientMovementsTableOrderingComposer,
    $$IngredientMovementsTableAnnotationComposer,
    $$IngredientMovementsTableCreateCompanionBuilder,
    $$IngredientMovementsTableUpdateCompanionBuilder,
    (IngredientMovement, $$IngredientMovementsTableReferences),
    IngredientMovement,
    PrefetchHooks Function({bool ingredientId, bool orderId, bool purchaseId})>;
typedef $$IngredientPurchaseItemsTableCreateCompanionBuilder
    = IngredientPurchaseItemsCompanion Function({
  Value<int> id,
  required int purchaseId,
  required int ingredientId,
  required double quantity,
  required double unitCost,
});
typedef $$IngredientPurchaseItemsTableUpdateCompanionBuilder
    = IngredientPurchaseItemsCompanion Function({
  Value<int> id,
  Value<int> purchaseId,
  Value<int> ingredientId,
  Value<double> quantity,
  Value<double> unitCost,
});

final class $$IngredientPurchaseItemsTableReferences extends BaseReferences<
    _$AppDatabase, $IngredientPurchaseItemsTable, IngredientPurchaseItem> {
  $$IngredientPurchaseItemsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $IngredientPurchasesTable _purchaseIdTable(_$AppDatabase db) =>
      db.ingredientPurchases.createAlias($_aliasNameGenerator(
          db.ingredientPurchaseItems.purchaseId, db.ingredientPurchases.id));

  $$IngredientPurchasesTableProcessedTableManager get purchaseId {
    final $_column = $_itemColumn<int>('purchase_id')!;

    final manager =
        $$IngredientPurchasesTableTableManager($_db, $_db.ingredientPurchases)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_purchaseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $IngredientsTable _ingredientIdTable(_$AppDatabase db) =>
      db.ingredients.createAlias($_aliasNameGenerator(
          db.ingredientPurchaseItems.ingredientId, db.ingredients.id));

  $$IngredientsTableProcessedTableManager get ingredientId {
    final $_column = $_itemColumn<int>('ingredient_id')!;

    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IngredientPurchaseItemsTableFilterComposer
    extends Composer<_$AppDatabase, $IngredientPurchaseItemsTable> {
  $$IngredientPurchaseItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitCost => $composableBuilder(
      column: $table.unitCost, builder: (column) => ColumnFilters(column));

  $$IngredientPurchasesTableFilterComposer get purchaseId {
    final $$IngredientPurchasesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.purchaseId,
        referencedTable: $db.ingredientPurchases,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientPurchasesTableFilterComposer(
              $db: $db,
              $table: $db.ingredientPurchases,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientPurchaseItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $IngredientPurchaseItemsTable> {
  $$IngredientPurchaseItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitCost => $composableBuilder(
      column: $table.unitCost, builder: (column) => ColumnOrderings(column));

  $$IngredientPurchasesTableOrderingComposer get purchaseId {
    final $$IngredientPurchasesTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.purchaseId,
            referencedTable: $db.ingredientPurchases,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientPurchasesTableOrderingComposer(
                  $db: $db,
                  $table: $db.ingredientPurchases,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableOrderingComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientPurchaseItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IngredientPurchaseItemsTable> {
  $$IngredientPurchaseItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  $$IngredientPurchasesTableAnnotationComposer get purchaseId {
    final $$IngredientPurchasesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.purchaseId,
            referencedTable: $db.ingredientPurchases,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IngredientPurchasesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.ingredientPurchases,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IngredientPurchaseItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IngredientPurchaseItemsTable,
    IngredientPurchaseItem,
    $$IngredientPurchaseItemsTableFilterComposer,
    $$IngredientPurchaseItemsTableOrderingComposer,
    $$IngredientPurchaseItemsTableAnnotationComposer,
    $$IngredientPurchaseItemsTableCreateCompanionBuilder,
    $$IngredientPurchaseItemsTableUpdateCompanionBuilder,
    (IngredientPurchaseItem, $$IngredientPurchaseItemsTableReferences),
    IngredientPurchaseItem,
    PrefetchHooks Function({bool purchaseId, bool ingredientId})> {
  $$IngredientPurchaseItemsTableTableManager(
      _$AppDatabase db, $IngredientPurchaseItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IngredientPurchaseItemsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$IngredientPurchaseItemsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IngredientPurchaseItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> purchaseId = const Value.absent(),
            Value<int> ingredientId = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> unitCost = const Value.absent(),
          }) =>
              IngredientPurchaseItemsCompanion(
            id: id,
            purchaseId: purchaseId,
            ingredientId: ingredientId,
            quantity: quantity,
            unitCost: unitCost,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int purchaseId,
            required int ingredientId,
            required double quantity,
            required double unitCost,
          }) =>
              IngredientPurchaseItemsCompanion.insert(
            id: id,
            purchaseId: purchaseId,
            ingredientId: ingredientId,
            quantity: quantity,
            unitCost: unitCost,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IngredientPurchaseItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({purchaseId = false, ingredientId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (purchaseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.purchaseId,
                    referencedTable: $$IngredientPurchaseItemsTableReferences
                        ._purchaseIdTable(db),
                    referencedColumn: $$IngredientPurchaseItemsTableReferences
                        ._purchaseIdTable(db)
                        .id,
                  ) as T;
                }
                if (ingredientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientId,
                    referencedTable: $$IngredientPurchaseItemsTableReferences
                        ._ingredientIdTable(db),
                    referencedColumn: $$IngredientPurchaseItemsTableReferences
                        ._ingredientIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IngredientPurchaseItemsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $IngredientPurchaseItemsTable,
        IngredientPurchaseItem,
        $$IngredientPurchaseItemsTableFilterComposer,
        $$IngredientPurchaseItemsTableOrderingComposer,
        $$IngredientPurchaseItemsTableAnnotationComposer,
        $$IngredientPurchaseItemsTableCreateCompanionBuilder,
        $$IngredientPurchaseItemsTableUpdateCompanionBuilder,
        (IngredientPurchaseItem, $$IngredientPurchaseItemsTableReferences),
        IngredientPurchaseItem,
        PrefetchHooks Function({bool purchaseId, bool ingredientId})>;
typedef $$RecipeItemsTableCreateCompanionBuilder = RecipeItemsCompanion
    Function({
  Value<int> id,
  required int productId,
  required int ingredientId,
  required double quantity,
});
typedef $$RecipeItemsTableUpdateCompanionBuilder = RecipeItemsCompanion
    Function({
  Value<int> id,
  Value<int> productId,
  Value<int> ingredientId,
  Value<double> quantity,
});

final class $$RecipeItemsTableReferences
    extends BaseReferences<_$AppDatabase, $RecipeItemsTable, RecipeItem> {
  $$RecipeItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
          $_aliasNameGenerator(db.recipeItems.productId, db.products.id));

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<int>('product_id')!;

    final manager = $$ProductsTableTableManager($_db, $_db.products)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $IngredientsTable _ingredientIdTable(_$AppDatabase db) =>
      db.ingredients.createAlias(
          $_aliasNameGenerator(db.recipeItems.ingredientId, db.ingredients.id));

  $$IngredientsTableProcessedTableManager get ingredientId {
    final $_column = $_itemColumn<int>('ingredient_id')!;

    final manager = $$IngredientsTableTableManager($_db, $_db.ingredients)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ingredientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecipeItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeItemsTable> {
  $$RecipeItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableFilterComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableFilterComposer get ingredientId {
    final $$IngredientsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableFilterComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeItemsTable> {
  $$RecipeItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableOrderingComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableOrderingComposer get ingredientId {
    final $$IngredientsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableOrderingComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeItemsTable> {
  $$RecipeItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.productId,
        referencedTable: $db.products,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductsTableAnnotationComposer(
              $db: $db,
              $table: $db.products,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$IngredientsTableAnnotationComposer get ingredientId {
    final $$IngredientsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.ingredientId,
        referencedTable: $db.ingredients,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IngredientsTableAnnotationComposer(
              $db: $db,
              $table: $db.ingredients,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipeItemsTable,
    RecipeItem,
    $$RecipeItemsTableFilterComposer,
    $$RecipeItemsTableOrderingComposer,
    $$RecipeItemsTableAnnotationComposer,
    $$RecipeItemsTableCreateCompanionBuilder,
    $$RecipeItemsTableUpdateCompanionBuilder,
    (RecipeItem, $$RecipeItemsTableReferences),
    RecipeItem,
    PrefetchHooks Function({bool productId, bool ingredientId})> {
  $$RecipeItemsTableTableManager(_$AppDatabase db, $RecipeItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> productId = const Value.absent(),
            Value<int> ingredientId = const Value.absent(),
            Value<double> quantity = const Value.absent(),
          }) =>
              RecipeItemsCompanion(
            id: id,
            productId: productId,
            ingredientId: ingredientId,
            quantity: quantity,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int productId,
            required int ingredientId,
            required double quantity,
          }) =>
              RecipeItemsCompanion.insert(
            id: id,
            productId: productId,
            ingredientId: ingredientId,
            quantity: quantity,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RecipeItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({productId = false, ingredientId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (productId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.productId,
                    referencedTable:
                        $$RecipeItemsTableReferences._productIdTable(db),
                    referencedColumn:
                        $$RecipeItemsTableReferences._productIdTable(db).id,
                  ) as T;
                }
                if (ingredientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.ingredientId,
                    referencedTable:
                        $$RecipeItemsTableReferences._ingredientIdTable(db),
                    referencedColumn:
                        $$RecipeItemsTableReferences._ingredientIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RecipeItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipeItemsTable,
    RecipeItem,
    $$RecipeItemsTableFilterComposer,
    $$RecipeItemsTableOrderingComposer,
    $$RecipeItemsTableAnnotationComposer,
    $$RecipeItemsTableCreateCompanionBuilder,
    $$RecipeItemsTableUpdateCompanionBuilder,
    (RecipeItem, $$RecipeItemsTableReferences),
    RecipeItem,
    PrefetchHooks Function({bool productId, bool ingredientId})>;
typedef $$DeliveryZonesTableCreateCompanionBuilder = DeliveryZonesCompanion
    Function({
  Value<int> id,
  required String name,
  Value<double> fee,
  Value<bool> active,
});
typedef $$DeliveryZonesTableUpdateCompanionBuilder = DeliveryZonesCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<double> fee,
  Value<bool> active,
});

class $$DeliveryZonesTableFilterComposer
    extends Composer<_$AppDatabase, $DeliveryZonesTable> {
  $$DeliveryZonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fee => $composableBuilder(
      column: $table.fee, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));
}

class $$DeliveryZonesTableOrderingComposer
    extends Composer<_$AppDatabase, $DeliveryZonesTable> {
  $$DeliveryZonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fee => $composableBuilder(
      column: $table.fee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));
}

class $$DeliveryZonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeliveryZonesTable> {
  $$DeliveryZonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get fee =>
      $composableBuilder(column: $table.fee, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$DeliveryZonesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeliveryZonesTable,
    DeliveryZone,
    $$DeliveryZonesTableFilterComposer,
    $$DeliveryZonesTableOrderingComposer,
    $$DeliveryZonesTableAnnotationComposer,
    $$DeliveryZonesTableCreateCompanionBuilder,
    $$DeliveryZonesTableUpdateCompanionBuilder,
    (
      DeliveryZone,
      BaseReferences<_$AppDatabase, $DeliveryZonesTable, DeliveryZone>
    ),
    DeliveryZone,
    PrefetchHooks Function()> {
  $$DeliveryZonesTableTableManager(_$AppDatabase db, $DeliveryZonesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeliveryZonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeliveryZonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeliveryZonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> fee = const Value.absent(),
            Value<bool> active = const Value.absent(),
          }) =>
              DeliveryZonesCompanion(
            id: id,
            name: name,
            fee: fee,
            active: active,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<double> fee = const Value.absent(),
            Value<bool> active = const Value.absent(),
          }) =>
              DeliveryZonesCompanion.insert(
            id: id,
            name: name,
            fee: fee,
            active: active,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DeliveryZonesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DeliveryZonesTable,
    DeliveryZone,
    $$DeliveryZonesTableFilterComposer,
    $$DeliveryZonesTableOrderingComposer,
    $$DeliveryZonesTableAnnotationComposer,
    $$DeliveryZonesTableCreateCompanionBuilder,
    $$DeliveryZonesTableUpdateCompanionBuilder,
    (
      DeliveryZone,
      BaseReferences<_$AppDatabase, $DeliveryZonesTable, DeliveryZone>
    ),
    DeliveryZone,
    PrefetchHooks Function()>;
typedef $$FiscalDocsTableCreateCompanionBuilder = FiscalDocsCompanion Function({
  Value<int> id,
  Value<int?> orderId,
  Value<String?> receptorRfc,
  Value<String?> receptorRazonSocial,
  Value<String?> receptorCpFiscal,
  Value<String?> receptorRegimen,
  Value<String?> receptorUsoCfdi,
  required String tipo,
  Value<String> estado,
  Value<String?> periodoRef,
  Value<DateTime?> exportedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$FiscalDocsTableUpdateCompanionBuilder = FiscalDocsCompanion Function({
  Value<int> id,
  Value<int?> orderId,
  Value<String?> receptorRfc,
  Value<String?> receptorRazonSocial,
  Value<String?> receptorCpFiscal,
  Value<String?> receptorRegimen,
  Value<String?> receptorUsoCfdi,
  Value<String> tipo,
  Value<String> estado,
  Value<String?> periodoRef,
  Value<DateTime?> exportedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$FiscalDocsTableReferences
    extends BaseReferences<_$AppDatabase, $FiscalDocsTable, FiscalDoc> {
  $$FiscalDocsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) => db.orders
      .createAlias($_aliasNameGenerator(db.fiscalDocs.orderId, db.orders.id));

  $$OrdersTableProcessedTableManager? get orderId {
    final $_column = $_itemColumn<int>('order_id');
    if ($_column == null) return null;
    final manager = $$OrdersTableTableManager($_db, $_db.orders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$FiscalDocItemsTable, List<FiscalDocItem>>
      _fiscalDocItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.fiscalDocItems,
              aliasName: $_aliasNameGenerator(
                  db.fiscalDocs.id, db.fiscalDocItems.fiscalDocId));

  $$FiscalDocItemsTableProcessedTableManager get fiscalDocItemsRefs {
    final manager = $$FiscalDocItemsTableTableManager($_db, $_db.fiscalDocItems)
        .filter((f) => f.fiscalDocId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fiscalDocItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FiscalDocsTableFilterComposer
    extends Composer<_$AppDatabase, $FiscalDocsTable> {
  $$FiscalDocsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receptorRfc => $composableBuilder(
      column: $table.receptorRfc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receptorRazonSocial => $composableBuilder(
      column: $table.receptorRazonSocial,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receptorCpFiscal => $composableBuilder(
      column: $table.receptorCpFiscal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receptorRegimen => $composableBuilder(
      column: $table.receptorRegimen,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receptorUsoCfdi => $composableBuilder(
      column: $table.receptorUsoCfdi,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get estado => $composableBuilder(
      column: $table.estado, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get periodoRef => $composableBuilder(
      column: $table.periodoRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get exportedAt => $composableBuilder(
      column: $table.exportedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableFilterComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> fiscalDocItemsRefs(
      Expression<bool> Function($$FiscalDocItemsTableFilterComposer f) f) {
    final $$FiscalDocItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fiscalDocItems,
        getReferencedColumn: (t) => t.fiscalDocId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalDocItemsTableFilterComposer(
              $db: $db,
              $table: $db.fiscalDocItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FiscalDocsTableOrderingComposer
    extends Composer<_$AppDatabase, $FiscalDocsTable> {
  $$FiscalDocsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receptorRfc => $composableBuilder(
      column: $table.receptorRfc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receptorRazonSocial => $composableBuilder(
      column: $table.receptorRazonSocial,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receptorCpFiscal => $composableBuilder(
      column: $table.receptorCpFiscal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receptorRegimen => $composableBuilder(
      column: $table.receptorRegimen,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receptorUsoCfdi => $composableBuilder(
      column: $table.receptorUsoCfdi,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get estado => $composableBuilder(
      column: $table.estado, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get periodoRef => $composableBuilder(
      column: $table.periodoRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get exportedAt => $composableBuilder(
      column: $table.exportedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableOrderingComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FiscalDocsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FiscalDocsTable> {
  $$FiscalDocsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get receptorRfc => $composableBuilder(
      column: $table.receptorRfc, builder: (column) => column);

  GeneratedColumn<String> get receptorRazonSocial => $composableBuilder(
      column: $table.receptorRazonSocial, builder: (column) => column);

  GeneratedColumn<String> get receptorCpFiscal => $composableBuilder(
      column: $table.receptorCpFiscal, builder: (column) => column);

  GeneratedColumn<String> get receptorRegimen => $composableBuilder(
      column: $table.receptorRegimen, builder: (column) => column);

  GeneratedColumn<String> get receptorUsoCfdi => $composableBuilder(
      column: $table.receptorUsoCfdi, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get periodoRef => $composableBuilder(
      column: $table.periodoRef, builder: (column) => column);

  GeneratedColumn<DateTime> get exportedAt => $composableBuilder(
      column: $table.exportedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.orderId,
        referencedTable: $db.orders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$OrdersTableAnnotationComposer(
              $db: $db,
              $table: $db.orders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> fiscalDocItemsRefs<T extends Object>(
      Expression<T> Function($$FiscalDocItemsTableAnnotationComposer a) f) {
    final $$FiscalDocItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.fiscalDocItems,
        getReferencedColumn: (t) => t.fiscalDocId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalDocItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.fiscalDocItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FiscalDocsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FiscalDocsTable,
    FiscalDoc,
    $$FiscalDocsTableFilterComposer,
    $$FiscalDocsTableOrderingComposer,
    $$FiscalDocsTableAnnotationComposer,
    $$FiscalDocsTableCreateCompanionBuilder,
    $$FiscalDocsTableUpdateCompanionBuilder,
    (FiscalDoc, $$FiscalDocsTableReferences),
    FiscalDoc,
    PrefetchHooks Function({bool orderId, bool fiscalDocItemsRefs})> {
  $$FiscalDocsTableTableManager(_$AppDatabase db, $FiscalDocsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FiscalDocsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FiscalDocsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FiscalDocsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> orderId = const Value.absent(),
            Value<String?> receptorRfc = const Value.absent(),
            Value<String?> receptorRazonSocial = const Value.absent(),
            Value<String?> receptorCpFiscal = const Value.absent(),
            Value<String?> receptorRegimen = const Value.absent(),
            Value<String?> receptorUsoCfdi = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<String> estado = const Value.absent(),
            Value<String?> periodoRef = const Value.absent(),
            Value<DateTime?> exportedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FiscalDocsCompanion(
            id: id,
            orderId: orderId,
            receptorRfc: receptorRfc,
            receptorRazonSocial: receptorRazonSocial,
            receptorCpFiscal: receptorCpFiscal,
            receptorRegimen: receptorRegimen,
            receptorUsoCfdi: receptorUsoCfdi,
            tipo: tipo,
            estado: estado,
            periodoRef: periodoRef,
            exportedAt: exportedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> orderId = const Value.absent(),
            Value<String?> receptorRfc = const Value.absent(),
            Value<String?> receptorRazonSocial = const Value.absent(),
            Value<String?> receptorCpFiscal = const Value.absent(),
            Value<String?> receptorRegimen = const Value.absent(),
            Value<String?> receptorUsoCfdi = const Value.absent(),
            required String tipo,
            Value<String> estado = const Value.absent(),
            Value<String?> periodoRef = const Value.absent(),
            Value<DateTime?> exportedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FiscalDocsCompanion.insert(
            id: id,
            orderId: orderId,
            receptorRfc: receptorRfc,
            receptorRazonSocial: receptorRazonSocial,
            receptorCpFiscal: receptorCpFiscal,
            receptorRegimen: receptorRegimen,
            receptorUsoCfdi: receptorUsoCfdi,
            tipo: tipo,
            estado: estado,
            periodoRef: periodoRef,
            exportedAt: exportedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FiscalDocsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {orderId = false, fiscalDocItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (fiscalDocItemsRefs) db.fiscalDocItems
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (orderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.orderId,
                    referencedTable:
                        $$FiscalDocsTableReferences._orderIdTable(db),
                    referencedColumn:
                        $$FiscalDocsTableReferences._orderIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fiscalDocItemsRefs)
                    await $_getPrefetchedData<FiscalDoc, $FiscalDocsTable,
                            FiscalDocItem>(
                        currentTable: table,
                        referencedTable: $$FiscalDocsTableReferences
                            ._fiscalDocItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FiscalDocsTableReferences(db, table, p0)
                                .fiscalDocItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.fiscalDocId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FiscalDocsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FiscalDocsTable,
    FiscalDoc,
    $$FiscalDocsTableFilterComposer,
    $$FiscalDocsTableOrderingComposer,
    $$FiscalDocsTableAnnotationComposer,
    $$FiscalDocsTableCreateCompanionBuilder,
    $$FiscalDocsTableUpdateCompanionBuilder,
    (FiscalDoc, $$FiscalDocsTableReferences),
    FiscalDoc,
    PrefetchHooks Function({bool orderId, bool fiscalDocItemsRefs})>;
typedef $$FiscalDocItemsTableCreateCompanionBuilder = FiscalDocItemsCompanion
    Function({
  Value<int> id,
  required int fiscalDocId,
  Value<String?> claveProdServ,
  Value<String?> claveUnidad,
  required String descripcion,
  required double cantidad,
  required double valorUnitario,
  required double importe,
  Value<double> descuento,
  Value<String?> objetoImp,
  required double base,
  Value<double> tasaIva,
  Value<double> importeIva,
});
typedef $$FiscalDocItemsTableUpdateCompanionBuilder = FiscalDocItemsCompanion
    Function({
  Value<int> id,
  Value<int> fiscalDocId,
  Value<String?> claveProdServ,
  Value<String?> claveUnidad,
  Value<String> descripcion,
  Value<double> cantidad,
  Value<double> valorUnitario,
  Value<double> importe,
  Value<double> descuento,
  Value<String?> objetoImp,
  Value<double> base,
  Value<double> tasaIva,
  Value<double> importeIva,
});

final class $$FiscalDocItemsTableReferences
    extends BaseReferences<_$AppDatabase, $FiscalDocItemsTable, FiscalDocItem> {
  $$FiscalDocItemsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FiscalDocsTable _fiscalDocIdTable(_$AppDatabase db) =>
      db.fiscalDocs.createAlias($_aliasNameGenerator(
          db.fiscalDocItems.fiscalDocId, db.fiscalDocs.id));

  $$FiscalDocsTableProcessedTableManager get fiscalDocId {
    final $_column = $_itemColumn<int>('fiscal_doc_id')!;

    final manager = $$FiscalDocsTableTableManager($_db, $_db.fiscalDocs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fiscalDocIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FiscalDocItemsTableFilterComposer
    extends Composer<_$AppDatabase, $FiscalDocItemsTable> {
  $$FiscalDocItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get claveProdServ => $composableBuilder(
      column: $table.claveProdServ, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get claveUnidad => $composableBuilder(
      column: $table.claveUnidad, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cantidad => $composableBuilder(
      column: $table.cantidad, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valorUnitario => $composableBuilder(
      column: $table.valorUnitario, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get importe => $composableBuilder(
      column: $table.importe, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get descuento => $composableBuilder(
      column: $table.descuento, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get objetoImp => $composableBuilder(
      column: $table.objetoImp, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get base => $composableBuilder(
      column: $table.base, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tasaIva => $composableBuilder(
      column: $table.tasaIva, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get importeIva => $composableBuilder(
      column: $table.importeIva, builder: (column) => ColumnFilters(column));

  $$FiscalDocsTableFilterComposer get fiscalDocId {
    final $$FiscalDocsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalDocId,
        referencedTable: $db.fiscalDocs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalDocsTableFilterComposer(
              $db: $db,
              $table: $db.fiscalDocs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FiscalDocItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $FiscalDocItemsTable> {
  $$FiscalDocItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get claveProdServ => $composableBuilder(
      column: $table.claveProdServ,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get claveUnidad => $composableBuilder(
      column: $table.claveUnidad, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cantidad => $composableBuilder(
      column: $table.cantidad, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valorUnitario => $composableBuilder(
      column: $table.valorUnitario,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get importe => $composableBuilder(
      column: $table.importe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get descuento => $composableBuilder(
      column: $table.descuento, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get objetoImp => $composableBuilder(
      column: $table.objetoImp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get base => $composableBuilder(
      column: $table.base, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tasaIva => $composableBuilder(
      column: $table.tasaIva, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get importeIva => $composableBuilder(
      column: $table.importeIva, builder: (column) => ColumnOrderings(column));

  $$FiscalDocsTableOrderingComposer get fiscalDocId {
    final $$FiscalDocsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalDocId,
        referencedTable: $db.fiscalDocs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalDocsTableOrderingComposer(
              $db: $db,
              $table: $db.fiscalDocs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FiscalDocItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FiscalDocItemsTable> {
  $$FiscalDocItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get claveProdServ => $composableBuilder(
      column: $table.claveProdServ, builder: (column) => column);

  GeneratedColumn<String> get claveUnidad => $composableBuilder(
      column: $table.claveUnidad, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => column);

  GeneratedColumn<double> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<double> get valorUnitario => $composableBuilder(
      column: $table.valorUnitario, builder: (column) => column);

  GeneratedColumn<double> get importe =>
      $composableBuilder(column: $table.importe, builder: (column) => column);

  GeneratedColumn<double> get descuento =>
      $composableBuilder(column: $table.descuento, builder: (column) => column);

  GeneratedColumn<String> get objetoImp =>
      $composableBuilder(column: $table.objetoImp, builder: (column) => column);

  GeneratedColumn<double> get base =>
      $composableBuilder(column: $table.base, builder: (column) => column);

  GeneratedColumn<double> get tasaIva =>
      $composableBuilder(column: $table.tasaIva, builder: (column) => column);

  GeneratedColumn<double> get importeIva => $composableBuilder(
      column: $table.importeIva, builder: (column) => column);

  $$FiscalDocsTableAnnotationComposer get fiscalDocId {
    final $$FiscalDocsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fiscalDocId,
        referencedTable: $db.fiscalDocs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FiscalDocsTableAnnotationComposer(
              $db: $db,
              $table: $db.fiscalDocs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FiscalDocItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FiscalDocItemsTable,
    FiscalDocItem,
    $$FiscalDocItemsTableFilterComposer,
    $$FiscalDocItemsTableOrderingComposer,
    $$FiscalDocItemsTableAnnotationComposer,
    $$FiscalDocItemsTableCreateCompanionBuilder,
    $$FiscalDocItemsTableUpdateCompanionBuilder,
    (FiscalDocItem, $$FiscalDocItemsTableReferences),
    FiscalDocItem,
    PrefetchHooks Function({bool fiscalDocId})> {
  $$FiscalDocItemsTableTableManager(
      _$AppDatabase db, $FiscalDocItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FiscalDocItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FiscalDocItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FiscalDocItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> fiscalDocId = const Value.absent(),
            Value<String?> claveProdServ = const Value.absent(),
            Value<String?> claveUnidad = const Value.absent(),
            Value<String> descripcion = const Value.absent(),
            Value<double> cantidad = const Value.absent(),
            Value<double> valorUnitario = const Value.absent(),
            Value<double> importe = const Value.absent(),
            Value<double> descuento = const Value.absent(),
            Value<String?> objetoImp = const Value.absent(),
            Value<double> base = const Value.absent(),
            Value<double> tasaIva = const Value.absent(),
            Value<double> importeIva = const Value.absent(),
          }) =>
              FiscalDocItemsCompanion(
            id: id,
            fiscalDocId: fiscalDocId,
            claveProdServ: claveProdServ,
            claveUnidad: claveUnidad,
            descripcion: descripcion,
            cantidad: cantidad,
            valorUnitario: valorUnitario,
            importe: importe,
            descuento: descuento,
            objetoImp: objetoImp,
            base: base,
            tasaIva: tasaIva,
            importeIva: importeIva,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int fiscalDocId,
            Value<String?> claveProdServ = const Value.absent(),
            Value<String?> claveUnidad = const Value.absent(),
            required String descripcion,
            required double cantidad,
            required double valorUnitario,
            required double importe,
            Value<double> descuento = const Value.absent(),
            Value<String?> objetoImp = const Value.absent(),
            required double base,
            Value<double> tasaIva = const Value.absent(),
            Value<double> importeIva = const Value.absent(),
          }) =>
              FiscalDocItemsCompanion.insert(
            id: id,
            fiscalDocId: fiscalDocId,
            claveProdServ: claveProdServ,
            claveUnidad: claveUnidad,
            descripcion: descripcion,
            cantidad: cantidad,
            valorUnitario: valorUnitario,
            importe: importe,
            descuento: descuento,
            objetoImp: objetoImp,
            base: base,
            tasaIva: tasaIva,
            importeIva: importeIva,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FiscalDocItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({fiscalDocId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fiscalDocId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fiscalDocId,
                    referencedTable:
                        $$FiscalDocItemsTableReferences._fiscalDocIdTable(db),
                    referencedColumn: $$FiscalDocItemsTableReferences
                        ._fiscalDocIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FiscalDocItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FiscalDocItemsTable,
    FiscalDocItem,
    $$FiscalDocItemsTableFilterComposer,
    $$FiscalDocItemsTableOrderingComposer,
    $$FiscalDocItemsTableAnnotationComposer,
    $$FiscalDocItemsTableCreateCompanionBuilder,
    $$FiscalDocItemsTableUpdateCompanionBuilder,
    (FiscalDocItem, $$FiscalDocItemsTableReferences),
    FiscalDocItem,
    PrefetchHooks Function({bool fiscalDocId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ModifiersTableTableManager get modifiers =>
      $$ModifiersTableTableManager(_db, _db.modifiers);
  $$DiscountsTableTableManager get discounts =>
      $$DiscountsTableTableManager(_db, _db.discounts);
  $$TablesLayoutTableTableManager get tablesLayout =>
      $$TablesLayoutTableTableManager(_db, _db.tablesLayout);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db, _db.employees);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db, _db.shifts);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db, _db.orderItems);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$InventoryMovementsTableTableManager get inventoryMovements =>
      $$InventoryMovementsTableTableManager(_db, _db.inventoryMovements);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$CashMovementsTableTableManager get cashMovements =>
      $$CashMovementsTableTableManager(_db, _db.cashMovements);
  $$RefundsTableTableManager get refunds =>
      $$RefundsTableTableManager(_db, _db.refunds);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db, _db.suppliers);
  $$IngredientsTableTableManager get ingredients =>
      $$IngredientsTableTableManager(_db, _db.ingredients);
  $$IngredientPurchasesTableTableManager get ingredientPurchases =>
      $$IngredientPurchasesTableTableManager(_db, _db.ingredientPurchases);
  $$IngredientMovementsTableTableManager get ingredientMovements =>
      $$IngredientMovementsTableTableManager(_db, _db.ingredientMovements);
  $$IngredientPurchaseItemsTableTableManager get ingredientPurchaseItems =>
      $$IngredientPurchaseItemsTableTableManager(
          _db, _db.ingredientPurchaseItems);
  $$RecipeItemsTableTableManager get recipeItems =>
      $$RecipeItemsTableTableManager(_db, _db.recipeItems);
  $$DeliveryZonesTableTableManager get deliveryZones =>
      $$DeliveryZonesTableTableManager(_db, _db.deliveryZones);
  $$FiscalDocsTableTableManager get fiscalDocs =>
      $$FiscalDocsTableTableManager(_db, _db.fiscalDocs);
  $$FiscalDocItemsTableTableManager get fiscalDocItems =>
      $$FiscalDocItemsTableTableManager(_db, _db.fiscalDocItems);
}
