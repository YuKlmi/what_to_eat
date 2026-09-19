import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import 'backup_service.dart';
import 'preference_service.dart';
import 'recommendation_service.dart';

/// 偏好分析服务 Provider
final preferenceServiceProvider = Provider<PreferenceService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PreferenceService(db);
});

/// 推荐引擎 Provider
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final preferenceService = ref.watch(preferenceServiceProvider);
  return RecommendationService(db, preferenceService);
});

/// 备份与恢复服务 Provider
final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupService(db);
});