import '../database/app_database.dart';

/// 统计数据服务
class StatsService {
  final AppDatabase _db;

  StatsService(this._db);

  /// 获取指定天数内的每日消费（按日期升序）
  Future<List<DailySpending>> getDailySpending(int days) async {
    final records = await _db.recordDao.getRecentRecords(days);
    final dailyTotals = <DateTime, double>{};

    for (final record in records) {
      final day = DateTime(
        record.mealTime.year,
        record.mealTime.month,
        record.mealTime.day,
      );
      dailyTotals[day] = (dailyTotals[day] ?? 0) + record.price;
    }

    final sortedDays = dailyTotals.keys.toList()..sort();
    return sortedDays
        .map((day) => DailySpending(day: day, amount: dailyTotals[day]!))
        .toList();
  }

  /// 获取点餐频次（不超过7天按日聚合，超过7天按自然周聚合）
  Future<List<FrequencyBucket>> getFrequencyStats(int days) async {
    final records = await _db.recordDao.getRecentRecords(days);
    final counts = <DateTime, int>{};

    for (final record in records) {
      final start = _bucketStart(record.mealTime, days);
      counts[start] = (counts[start] ?? 0) + 1;
    }

    final sortedStarts = counts.keys.toList()..sort();
    return sortedStarts
        .map((start) => FrequencyBucket(
              start: start,
              end: _bucketEnd(start, days),
              count: counts[start]!,
            ))
        .toList();
  }

  /// 获取标签分布统计
  Future<List<TagDistribution>> getTagDistribution(int days) async {
    final records = await _db.recordDao.getRecentRecords(days);
    final allTags = await _db.tagDao.getAllTags();
    final tagMap = {for (var t in allTags) t.id: t};

    // 统计标签出现次数
    final counts = <int, int>{};
    for (final record in records) {
      final tagIds = _parseTagIds(record.tagIds);
      for (final id in tagIds) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }

    // 转换为分布数据
    final total = counts.values.fold(0, (a, b) => a + b);
    final distributions = <TagDistribution>[];

    for (final entry in counts.entries) {
      final tag = tagMap[entry.key];
      if (tag != null) {
        distributions.add(TagDistribution(
          tagId: tag.id,
          tagName: tag.name,
          count: entry.value,
          ratio: total > 0 ? entry.value / total : 0,
        ));
      }
    }

    distributions.sort((a, b) => b.count.compareTo(a.count));
    return distributions;
  }

  /// 获取指定标签在时间范围内的记录
  Future<List<Record>> getRecordsByTag(int tagId, int days) async {
    final records = await _db.recordDao.getRecentRecords(days);
    return records
        .where((r) => _parseTagIds(r.tagIds).contains(tagId))
        .toList();
  }

  /// 获取指定时间区间内的记录（含起点，不含终点）
  Future<List<Record>> getRecordsInRange(DateTime start, DateTime end) async {
    final records = await _db.recordDao.getAllRecords();
    return records
        .where((r) => !r.mealTime.isBefore(start) && r.mealTime.isBefore(end))
        .toList();
  }

  /// 获取总消费和总记录数
  Future<StatsSummary> getSummary(int days) async {
    final records = await _db.recordDao.getRecentRecords(days);
    final totalSpent = records.fold(0.0, (sum, r) => sum + r.price);
    return StatsSummary(
      totalRecords: records.length,
      totalSpent: totalSpent,
      avgPerMeal: records.isNotEmpty ? totalSpent / records.length : 0,
    );
  }

  /// 时间桶起点：不超过7天按天，超过7天按自然周（周一为起点）
  DateTime _bucketStart(DateTime time, int days) {
    final date = DateTime(time.year, time.month, time.day);
    if (days <= 7) return date;
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// 时间桶终点（不含）
  DateTime _bucketEnd(DateTime start, int days) {
    return start.add(Duration(days: days <= 7 ? 1 : 7));
  }

  List<int> _parseTagIds(String tagIdsJson) {
    try {
      final cleaned = tagIdsJson.replaceAll('[', '').replaceAll(']', '');
      if (cleaned.trim().isEmpty) return [];
      return cleaned
          .split(',')
          .where((s) => s.trim().isNotEmpty)
          .map((s) => int.parse(s.trim()))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// 每日消费
class DailySpending {
  final DateTime day;
  final double amount;

  const DailySpending({required this.day, required this.amount});
}

/// 标签分布
class TagDistribution {
  final int tagId;
  final String tagName;
  final int count;
  final double ratio;

  const TagDistribution({
    required this.tagId,
    required this.tagName,
    required this.count,
    required this.ratio,
  });
}

/// 点餐频次时间桶
class FrequencyBucket {
  final DateTime start;
  final DateTime end;
  final int count;

  const FrequencyBucket({
    required this.start,
    required this.end,
    required this.count,
  });
}

/// 统计摘要
class StatsSummary {
  final int totalRecords;
  final double totalSpent;
  final double avgPerMeal;

  const StatsSummary({
    required this.totalRecords,
    required this.totalSpent,
    required this.avgPerMeal,
  });
}
