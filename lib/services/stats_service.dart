import '../database/app_database.dart';

/// 统计数据服务
class StatsService {
  final AppDatabase _db;

  StatsService(this._db);

  /// 获取指定天数内的每日消费
  Future<List<DailySpending>> getDailySpending(int days) async {
    final records = await _db.recordDao.getRecentRecords(days);
    final dailyMap = <String, double>{};

    for (final record in records) {
      final key = '${record.mealTime.month}/${record.mealTime.day}';
      dailyMap[key] = (dailyMap[key] ?? 0) + record.price;
    }

    return dailyMap.entries
        .map((e) => DailySpending(date: e.key, amount: e.value))
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
          tagName: tag.name,
          count: entry.value,
          ratio: total > 0 ? entry.value / total : 0,
        ));
      }
    }

    distributions.sort((a, b) => b.count.compareTo(a.count));
    return distributions;
  }

  /// 获取每周点餐频次
  Future<List<WeeklyFrequency>> getWeeklyFrequency(int weeks) async {
    final days = weeks * 7;
    final records = await _db.recordDao.getRecentRecords(days);
    final weekMap = <int, int>{};

    for (final record in records) {
      final weekNum = _getWeekNumber(record.mealTime);
      weekMap[weekNum] = (weekMap[weekNum] ?? 0) + 1;
    }

    return weekMap.entries
        .map((e) => WeeklyFrequency(week: '第${e.key}周', count: e.value))
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

  int _getWeekNumber(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final daysDiff = date.difference(firstDay).inDays;
    return (daysDiff / 7).ceil();
  }
}

/// 每日消费
class DailySpending {
  final String date;
  final double amount;

  const DailySpending({required this.date, required this.amount});
}

/// 标签分布
class TagDistribution {
  final String tagName;
  final int count;
  final double ratio;

  const TagDistribution({
    required this.tagName,
    required this.count,
    required this.ratio,
  });
}

/// 每周频次
class WeeklyFrequency {
  final String week;
  final int count;

  const WeeklyFrequency({required this.week, required this.count});
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