import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'daos/tag_dao.dart';
import 'daos/record_dao.dart';
import 'daos/shop_dao.dart';
import 'daos/budget_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Tags, Records, Shops, Budgets],
  daos: [TagDao, RecordDao, ShopDao, BudgetDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 供测试注入自定义执行器（例如内存数据库）
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // 逐级迁移，不允许跳级
          for (var version = from + 1; version <= to; version++) {
            await applyMigrationStep(m, version);
          }
        },
      );
}

/// 按 schema 版本号执行迁移步骤。
///
/// 修改表结构时：把 [AppDatabase.schemaVersion] 加 1，并在此新增对应 case。
/// 未登记的版本会抛 [StateError]，避免静默跳级导致数据损坏。
Future<void> applyMigrationStep(Migrator m, int version) async {
  switch (version) {
    case 1:
      // 初始版本，无迁移动作
      break;
    default:
      throw StateError('缺少 schema 版本 $version 的迁移步骤');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wte.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
