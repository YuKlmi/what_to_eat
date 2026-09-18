import 'package:drift/drift.dart';

/// 标签表
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get dimension => integer()(); // 0=taste, 1=type, 2=cuisine
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 外卖记录表
class Records extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shopName => text().withLength(min: 1, max: 100)();
  RealColumn get price => real()();
  TextColumn get tagIds => text().withDefault(const Constant('[]'))(); // JSON 数组
  TextColumn get dishName => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get mealTime => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 店铺表
class Shops extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get tagIds => text().withDefault(const Constant('[]'))(); // JSON 数组
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 预算表
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get month => text().withLength(min: 7, max: 7)(); // YYYY-MM
  RealColumn get amount => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}