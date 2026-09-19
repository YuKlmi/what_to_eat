import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'record_dao.g.dart';

@DriftAccessor(tables: [Records])
class RecordDao extends DatabaseAccessor<AppDatabase> with _$RecordDaoMixin {
  RecordDao(super.db);

  /// 获取所有记录（按时间倒序）
  Future<List<Record>> getAllRecords() =>
      (select(records)..orderBy([(r) => OrderingTerm.desc(r.mealTime)])).get();

  /// 监听所有记录变化
  Stream<List<Record>> watchAllRecords() =>
      (select(records)..orderBy([(r) => OrderingTerm.desc(r.mealTime)])).watch();

  /// 获取指定时间范围内的记录
  Future<List<Record>> getRecordsByDateRange(DateTime start, DateTime end) =>
      (select(records)
            ..where((r) => r.mealTime.isBetweenValues(start, end))
            ..orderBy([(r) => OrderingTerm.desc(r.mealTime)]))
          .get();

  /// 获取最近 N 天的记录
  Future<List<Record>> getRecentRecords(int days) {
    final start = DateTime.now().subtract(Duration(days: days));
    return getRecordsByDateRange(start, DateTime.now());
  }

  /// 监听最近 N 天的记录
  Stream<List<Record>> watchRecentRecords(int days) {
    final start = DateTime.now().subtract(Duration(days: days));
    return (select(records)
          ..where((r) => r.mealTime.isBiggerOrEqualValue(start))
          ..orderBy([(r) => OrderingTerm.desc(r.mealTime)]))
        .watch();
  }

  /// 根据 ID 获取记录
  Future<Record?> getRecordById(int id) =>
      (select(records)..where((r) => r.id.equals(id))).getSingleOrNull();

  /// 插入记录
  Future<int> insertRecord(RecordsCompanion entry) =>
      into(records).insert(entry);

  /// 更新记录
  Future<bool> updateRecord(RecordsCompanion entry) =>
      update(records).replace(entry);

  /// 删除记录
  Future<int> deleteRecord(int id) =>
      (delete(records)..where((r) => r.id.equals(id))).go();

  /// 获取指定月份的记录（用于预算统计）
  Future<List<Record>> getRecordsByMonth(String month) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);
    final start = DateTime(year, monthNum, 1);
    final end = DateTime(year, monthNum + 1, 0, 23, 59, 59);
    return getRecordsByDateRange(start, end);
  }

  /// 统计指定月份的总消费
  Future<double> getTotalSpentByMonth(String month) async {
    final records = await getRecordsByMonth(month);
    return records.fold<double>(0, (sum, r) => sum + r.price);
  }

  /// 用给定数据替换全部记录（传空列表即清空）
  Future<void> replaceAll(List<RecordsCompanion> entries) async {
    await transaction(() async {
      await delete(records).go();
      if (entries.isNotEmpty) {
        await batch((b) => b.insertAll(records, entries));
      }
    });
  }
}