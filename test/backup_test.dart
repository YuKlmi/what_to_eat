import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:wte/database/app_database.dart';
import 'package:wte/services/backup_service.dart';

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

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('wte_backup_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  /// 写一个临时备份文件，返回路径
  Future<String> writeBackup(String content) async {
    final file = File('${tempDir.path}${Platform.pathSeparator}backup.json');
    await file.writeAsString(content);
    return file.path;
  }

  String fullBackupJson({int formatVersion = 1}) {
    final stamp = DateTime(2026, 9, 19, 12).toIso8601String();
    return jsonEncode({
      'formatVersion': formatVersion,
      'exportedAt': stamp,
      'tags': [
        {
          'id': 1,
          'name': '辣',
          'dimension': 0,
          'isSystem': true,
          'createdAt': stamp,
        },
      ],
      'records': [
        {
          'id': 1,
          'shopName': '麦当劳',
          'price': 35.0,
          'tagIds': '[1]',
          'dishName': '巨无霸',
          'note': null,
          'mealTime': stamp,
          'createdAt': stamp,
        },
      ],
      'shops': [
        {
          'id': 1,
          'name': '麦当劳',
          'isFavorite': true,
          'tagIds': '[]',
          'createdAt': stamp,
        },
      ],
      'budgets': [
        {
          'id': 1,
          'month': '2026-09',
          'amount': 1000.0,
          'createdAt': stamp,
        },
      ],
    });
  }

  test('restoreFromFile 可完整恢复备份中的四类数据', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final service = BackupService(db);

    final path = await writeBackup(fullBackupJson());
    final result = await service.restoreFromFile(path);

    expect(result.success, isTrue);
    expect((await db.tagDao.getAllTags()).single.name, '辣');
    expect((await db.recordDao.getAllRecords()).single.dishName, '巨无霸');
    expect((await db.shopDao.getFavoriteShops()).single.name, '麦当劳');
    expect((await db.budgetDao.getBudgetByMonth('2026-09'))?.amount, 1000.0);
  });

  test('备份版本不兼容时拒绝恢复，且不改动现有数据', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final service = BackupService(db);

    await db.tagDao.insertTag(
      TagsCompanion.insert(name: '原有标签', dimension: 0),
    );

    final path = await writeBackup(fullBackupJson(formatVersion: 999));
    final result = await service.restoreFromFile(path);

    expect(result.success, isFalse);
    expect(result.message, contains('版本不兼容'));
    expect((await db.tagDao.getAllTags()).single.name, '原有标签');
  });

  test('备份内容不是有效 JSON 时返回友好错误', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final service = BackupService(db);

    final path = await writeBackup('这不是 JSON');
    final result = await service.restoreFromFile(path);

    expect(result.success, isFalse);
    expect(result.message, contains('JSON'));
  });

  test('clearAll 清空全部表', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final service = BackupService(db);

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

    await service.clearAll();

    expect(await db.tagDao.getAllTags(), isEmpty);
    expect(await db.recordDao.getAllRecords(), isEmpty);
    expect(await db.shopDao.getAllShops(), isEmpty);
    expect(await db.budgetDao.getAllBudgets(), isEmpty);
  });
}
