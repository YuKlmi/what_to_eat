import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:wte/database/app_database.dart';

void main() {
  setUpAll(() {
    // flutter test 运行在宿主平台，Windows 上显式指向系统自带的 sqlite3
    if (Platform.isWindows) {
      open.overrideFor(
        OperatingSystem.windows,
        () => DynamicLibrary.open('winsqlite3.dll'),
      );
    }
  });

  test('新建数据库使用当前 schema 版本，且四张表均可读写', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 1);

    await db.tagDao.insertTag(
      TagsCompanion.insert(name: '辣', dimension: 0),
    );
    await db.recordDao.insertRecord(
      RecordsCompanion.insert(
        shopName: '麦当劳',
        price: 35.0,
        mealTime: DateTime(2026, 9, 19, 12),
      ),
    );
    await db.shopDao.favoriteShop('麦当劳');
    await db.budgetDao.upsertBudget('2026-09', 1000.0);

    expect((await db.tagDao.getAllTags()).length, 1);
    expect((await db.recordDao.getAllRecords()).length, 1);
    expect((await db.shopDao.getFavoriteShops()).length, 1);
    expect((await db.budgetDao.getBudgetByMonth('2026-09'))?.amount, 1000.0);
  });

  test('迁移步骤按版本登记：已登记版本可执行，未登记版本抛错', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final migrator = db.createMigrator();

    // v1 为初始版本，无迁移动作
    await applyMigrationStep(migrator, 1);

    // 未登记的版本必须显式报错，避免静默跳级导致数据损坏
    await expectLater(
      applyMigrationStep(migrator, 999),
      throwsA(isA<StateError>()),
    );
  });

  test('replaceAll 可清空数据，并可回写指定内容', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.tagDao.insertTag(
      TagsCompanion.insert(name: '辣', dimension: 0),
    );
    await db.tagDao.replaceAll(const []);
    expect(await db.tagDao.getAllTags(), isEmpty);

    await db.tagDao.replaceAll([
      TagsCompanion.insert(name: '清淡', dimension: 0),
    ]);
    final tags = await db.tagDao.getAllTags();
    expect(tags.length, 1);
    expect(tags.single.name, '清淡');
  });
}
