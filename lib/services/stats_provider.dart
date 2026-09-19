import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'stats_service.dart';

final statsServiceProvider = Provider<StatsService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StatsService(db);
});

/// 记录数据变更信号：记录新增或删除后触发，使统计图表重新取数
final statsRevisionProvider = StreamProvider.autoDispose<List<Record>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.recordDao.watchAllRecords();
});
