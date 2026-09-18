import '../database/app_database.dart';

/// 标签频率统计
class TagFrequency {
  final Tag tag;
  final int count;
  final double ratio;

  const TagFrequency({
    required this.tag,
    required this.count,
    required this.ratio,
  });
}

/// 偏好分析结果
class PreferenceAnalysis {
  final List<TagFrequency> recentFrequencies; // 近7天
  final List<TagFrequency> longTermFrequencies; // 近30天
  final List<Tag> underrepresentedTags; // 近期少吃但长期喜欢

  const PreferenceAnalysis({
    required this.recentFrequencies,
    required this.longTermFrequencies,
    required this.underrepresentedTags,
  });
}

/// 偏好分析服务
class PreferenceService {
  final AppDatabase _db;

  PreferenceService(this._db);

  /// 分析用户偏好
  Future<PreferenceAnalysis> analyze() async {
    final recentRecords = await _db.recordDao.getRecentRecords(7);
    final longTermRecords = await _db.recordDao.getRecentRecords(30);
    final allTags = await _db.tagDao.getAllTags();

    // 统计近期标签频率
    final recentTagCounts = _countTagIds(recentRecords);
    final recentTotal = recentTagCounts.values.fold(0, (a, b) => a + b);

    // 统计长期标签频率
    final longTermTagCounts = _countTagIds(longTermRecords);
    final longTermTotal = longTermTagCounts.values.fold(0, (a, b) => a + b);

    // 构建频率列表
    final recentFrequencies = _buildFrequencies(
      allTags, recentTagCounts, recentTotal,
    );
    final longTermFrequencies = _buildFrequencies(
      allTags, longTermTagCounts, longTermTotal,
    );

    // 找出近期少吃但长期喜欢的标签
    final underrepresented = _findUnderrepresented(
      allTags, recentTagCounts, longTermTagCounts,
    );

    return PreferenceAnalysis(
      recentFrequencies: recentFrequencies,
      longTermFrequencies: longTermFrequencies,
      underrepresentedTags: underrepresented,
    );
  }

  /// 统计记录中标签出现次数
  Map<int, int> _countTagIds(List<Record> records) {
    final counts = <int, int>{};
    for (final record in records) {
      final tagIds = _parseTagIds(record.tagIds);
      for (final id in tagIds) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// 解析 tagIds JSON 字符串
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

  /// 构建频率列表
  List<TagFrequency> _buildFrequencies(
    List<Tag> allTags,
    Map<int, int> counts,
    int total,
  ) {
    final frequencies = <TagFrequency>[];
    for (final tag in allTags) {
      final count = counts[tag.id] ?? 0;
      if (count > 0) {
        frequencies.add(TagFrequency(
          tag: tag,
          count: count,
          ratio: total > 0 ? count / total : 0,
        ));
      }
    }
    frequencies.sort((a, b) => b.count.compareTo(a.count));
    return frequencies;
  }

  /// 找出近期少吃但长期喜欢的标签
  List<Tag> _findUnderrepresented(
    List<Tag> allTags,
    Map<int, int> recentCounts,
    Map<int, int> longTermCounts,
  ) {
    final result = <Tag>[];
    for (final tag in allTags) {
      final recentCount = recentCounts[tag.id] ?? 0;
      final longTermCount = longTermCounts[tag.id] ?? 0;
      // 长期有记录但近期没有或很少
      if (longTermCount >= 2 && recentCount == 0) {
        result.add(tag);
      }
    }
    return result;
  }
}