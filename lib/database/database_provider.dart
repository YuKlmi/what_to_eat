import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'seed_data.dart';

/// 数据库实例 Provider（全局单例）
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// 数据库初始化完成 Provider
final databaseReadyProvider = FutureProvider<bool>((ref) async {
  final db = ref.read(appDatabaseProvider);
  // 导入预设标签
  await seedPresetTags(db);
  return true;
});