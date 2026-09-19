import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';

/// 备份文件格式版本
const int backupFormatVersion = 1;

/// 备份文件信息
class BackupFileInfo {
  final String path;
  final String name;
  final DateTime modifiedAt;
  final int sizeBytes;

  const BackupFileInfo({
    required this.path,
    required this.name,
    required this.modifiedAt,
    required this.sizeBytes,
  });
}

/// 恢复结果
class RestoreResult {
  final bool success;
  final String message;

  const RestoreResult({required this.success, required this.message});
}

/// 数据备份与恢复服务
///
/// 备份文件保存在应用文档目录下的 `backups/` 子目录中。
/// 注意：该目录属于应用私有空间，卸载应用会一并删除；
/// 若需把备份带离设备，后续可接入系统分享。
class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// 备份目录：<应用文档目录>/backups
  Future<Directory> _backupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 备份目录的完整路径
  Future<String> backupDirectoryPath() async {
    final dir = await _backupDir();
    return dir.path;
  }

  /// 导出全部数据为 JSON 文件，返回文件路径
  Future<String> exportToFile() async {
    final payload = <String, dynamic>{
      'formatVersion': backupFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tags': (await _db.tagDao.getAllTags()).map(_tagToJson).toList(),
      'records':
          (await _db.recordDao.getAllRecords()).map(_recordToJson).toList(),
      'shops': (await _db.shopDao.getAllShops()).map(_shopToJson).toList(),
      'budgets': (await _db.budgetDao.getAllBudgets()).map(_budgetToJson).toList(),
    };

    final dir = await _backupDir();
    final file = File(p.join(dir.path, 'wte_backup_${_timestamp()}.json'));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file.path;
  }

  /// 列出备份目录下的备份文件（按修改时间倒序）
  Future<List<BackupFileInfo>> listBackups() async {
    final dir = await _backupDir();
    final infos = <BackupFileInfo>[];

    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith('wte_backup_') || !name.endsWith('.json')) continue;

      final stat = await entity.stat();
      infos.add(BackupFileInfo(
        path: entity.path,
        name: name,
        modifiedAt: stat.modified,
        sizeBytes: stat.size,
      ));
    }

    infos.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return infos;
  }

  /// 从备份文件恢复数据（会覆盖现有数据）
  Future<RestoreResult> restoreFromFile(String path) async {
    final String raw;
    try {
      raw = await File(path).readAsString();
    } catch (_) {
      return const RestoreResult(success: false, message: '无法读取备份文件');
    }

    final Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const RestoreResult(success: false, message: '备份文件结构无效');
      }
      data = decoded;
    } catch (_) {
      return const RestoreResult(success: false, message: '备份文件不是有效的 JSON');
    }

    final version = data['formatVersion'];
    if (version != backupFormatVersion) {
      return RestoreResult(
        success: false,
        message: '备份版本不兼容（文件 v$version，当前仅支持 v$backupFormatVersion）',
      );
    }

    try {
      await _db.transaction(() async {
        await _db.tagDao.replaceAll(_tagsFromJson(data['tags']));
        await _db.recordDao.replaceAll(_recordsFromJson(data['records']));
        await _db.shopDao.replaceAll(_shopsFromJson(data['shops']));
        await _db.budgetDao.replaceAll(_budgetsFromJson(data['budgets']));
      });
    } catch (e) {
      return RestoreResult(success: false, message: '恢复失败：$e');
    }

    return const RestoreResult(success: true, message: '数据已恢复');
  }

  /// 清空全部数据
  Future<void> clearAll() async {
    await _db.transaction(() async {
      await _db.tagDao.replaceAll(const []);
      await _db.recordDao.replaceAll(const []);
      await _db.shopDao.replaceAll(const []);
      await _db.budgetDao.replaceAll(const []);
    });
  }

  Map<String, dynamic> _tagToJson(Tag tag) => {
        'id': tag.id,
        'name': tag.name,
        'dimension': tag.dimension,
        'isSystem': tag.isSystem,
        'createdAt': tag.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _recordToJson(Record record) => {
        'id': record.id,
        'shopName': record.shopName,
        'price': record.price,
        'tagIds': record.tagIds,
        'dishName': record.dishName,
        'note': record.note,
        'mealTime': record.mealTime.toIso8601String(),
        'createdAt': record.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _shopToJson(Shop shop) => {
        'id': shop.id,
        'name': shop.name,
        'isFavorite': shop.isFavorite,
        'tagIds': shop.tagIds,
        'createdAt': shop.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _budgetToJson(Budget budget) => {
        'id': budget.id,
        'month': budget.month,
        'amount': budget.amount,
        'createdAt': budget.createdAt.toIso8601String(),
      };

  List<TagsCompanion> _tagsFromJson(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) {
      final map = e as Map<String, dynamic>;
      return TagsCompanion(
        id: Value(map['id'] as int),
        name: Value(map['name'] as String),
        dimension: Value(map['dimension'] as int),
        isSystem: Value(map['isSystem'] as bool),
        createdAt: Value(DateTime.parse(map['createdAt'] as String)),
      );
    }).toList();
  }

  List<RecordsCompanion> _recordsFromJson(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) {
      final map = e as Map<String, dynamic>;
      return RecordsCompanion(
        id: Value(map['id'] as int),
        shopName: Value(map['shopName'] as String),
        price: Value((map['price'] as num).toDouble()),
        tagIds: Value(map['tagIds'] as String),
        dishName: Value(map['dishName'] as String?),
        note: Value(map['note'] as String?),
        mealTime: Value(DateTime.parse(map['mealTime'] as String)),
        createdAt: Value(DateTime.parse(map['createdAt'] as String)),
      );
    }).toList();
  }

  List<ShopsCompanion> _shopsFromJson(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) {
      final map = e as Map<String, dynamic>;
      return ShopsCompanion(
        id: Value(map['id'] as int),
        name: Value(map['name'] as String),
        isFavorite: Value(map['isFavorite'] as bool),
        tagIds: Value(map['tagIds'] as String),
        createdAt: Value(DateTime.parse(map['createdAt'] as String)),
      );
    }).toList();
  }

  List<BudgetsCompanion> _budgetsFromJson(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) {
      final map = e as Map<String, dynamic>;
      return BudgetsCompanion(
        id: Value(map['id'] as int),
        month: Value(map['month'] as String),
        amount: Value((map['amount'] as num).toDouble()),
        createdAt: Value(DateTime.parse(map['createdAt'] as String)),
      );
    }).toList();
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
