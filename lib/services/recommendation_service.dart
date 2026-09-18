import 'dart:math';
import '../database/app_database.dart';
import 'preference_service.dart';

/// 推荐结果
class Recommendation {
  final Tag tag;
  final String reason;

  const Recommendation({required this.tag, required this.reason});
}

/// 推荐引擎
class RecommendationService {
  final AppDatabase _db;
  final PreferenceService _preferenceService;
  final _random = Random();

  RecommendationService(this._db, this._preferenceService);

  /// 生成推荐
  ///
  /// [excludeTagIds] 排除的标签ID列表
  Future<Recommendation?> recommend({List<int> excludeTagIds = const []}) async {
    final analysis = await _preferenceService.analyze();
    final allTags = await _db.tagDao.getAllTags();

    if (allTags.isEmpty) return null;

    // 获取昨天吃过的标签，避免重复
    final yesterdayRecords = await _db.recordDao.getRecentRecords(1);
    final yesterdayTagIds = <int>{};
    for (final record in yesterdayRecords) {
      yesterdayTagIds.addAll(_parseTagIds(record.tagIds));
    }

    // 合并排除列表
    final allExcluded = {...excludeTagIds, ...yesterdayTagIds};

    // 构建候选标签池
    final candidates = <Tag>[];
    final weights = <double>[];

    for (final tag in allTags) {
      if (allExcluded.contains(tag.id)) continue;

      double weight = 1.0;

      // 如果是近期少吃但长期喜欢的标签，增加权重
      if (analysis.underrepresentedTags.any((t) => t.id == tag.id)) {
        weight = 3.0;
      } else {
        // 根据近期频率反向加权（近期少吃权重更高）
        final recentFreq = analysis.recentFrequencies
            .where((f) => f.tag.id == tag.id)
            .toList();
        if (recentFreq.isNotEmpty) {
          weight = max(0.5, 1.0 - recentFreq.first.ratio);
        }
      }

      candidates.add(tag);
      weights.add(weight);
    }

    if (candidates.isEmpty) return null;

    // 加权随机选择
    final tag = _weightedRandom(candidates, weights);

    // 生成推荐理由
    final reason = _generateReason(tag, analysis);

    return Recommendation(tag: tag, reason: reason);
  }

  /// 加权随机选择
  Tag _weightedRandom(List<Tag> candidates, List<double> weights) {
    final totalWeight = weights.fold(0.0, (a, b) => a + b);
    var randomValue = _random.nextDouble() * totalWeight;

    for (var i = 0; i < candidates.length; i++) {
      randomValue -= weights[i];
      if (randomValue <= 0) return candidates[i];
    }

    return candidates.last;
  }

  /// 生成推荐理由
  String _generateReason(Tag tag, PreferenceAnalysis analysis) {
    if (analysis.underrepresentedTags.any((t) => t.id == tag.id)) {
      return '好久没吃${tag.name}了，来一份吧！';
    }

    final recentFreq = analysis.recentFrequencies
        .where((f) => f.tag.id == tag.id)
        .toList();
    if (recentFreq.isEmpty) {
      return '换换口味，试试${tag.name}？';
    }

    return '推荐${tag.name}！';
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