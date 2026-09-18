import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import 'stats_service.dart';

final statsServiceProvider = Provider<StatsService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StatsService(db);
});