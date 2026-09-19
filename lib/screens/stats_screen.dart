import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../services/stats_provider.dart';
import '../services/stats_service.dart';

// 图表颜色
const _chartColors = [
  Color(0xFFFF6B6B),
  Color(0xFF4ECDC4),
  Color(0xFFFFE66D),
  Color(0xFF95E1D3),
  Color(0xFFF38181),
  Color(0xFFAA96DA),
  Color(0xFFFCBAD3),
  Color(0xFFA8D8EA),
];

/// 底部弹层展示记录明细
void _showRecordSheet(
  BuildContext context, {
  required String title,
  required List<Record> records,
}) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final total = records.fold<double>(0, (sum, r) => sum + r.price);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(title, style: Theme.of(ctx).textTheme.titleMedium),
                  const Spacer(),
                  Text('${records.length} 单 · ￥${total.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('该范围没有记录'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: records.length,
                  itemBuilder: (ctx, index) {
                    final record = records[index];
                    final dish = record.dishName;
                    return ListTile(
                      dense: true,
                      title: Text(
                        dish != null && dish.isNotEmpty ? dish : record.shopName,
                      ),
                      subtitle: Text(
                        '${record.shopName} · '
                        '${DateFormat('MM/dd HH:mm').format(record.mealTime)}',
                      ),
                      trailing: Text('￥${record.price.toStringAsFixed(1)}'),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// 下钻：按标签查看记录
Future<void> _openTagRecords(
  BuildContext context,
  WidgetRef ref,
  TagDistribution distribution,
  int days,
) async {
  final records =
      await ref.read(statsServiceProvider).getRecordsByTag(distribution.tagId, days);
  if (!context.mounted) return;
  _showRecordSheet(
    context,
    title: '${distribution.tagName} · 最近$days天',
    records: records,
  );
}

/// 下钻：按日期查看记录
Future<void> _openDayRecords(
  BuildContext context,
  WidgetRef ref,
  DateTime day,
) async {
  final end = day.add(const Duration(days: 1));
  final records = await ref.read(statsServiceProvider).getRecordsInRange(day, end);
  if (!context.mounted) return;
  _showRecordSheet(
    context,
    title: DateFormat('yyyy/MM/dd').format(day),
    records: records,
  );
}

/// 下钻：按时间桶查看记录
Future<void> _openBucketRecords(
  BuildContext context,
  WidgetRef ref,
  FrequencyBucket bucket,
) async {
  final records = await ref
      .read(statsServiceProvider)
      .getRecordsInRange(bucket.start, bucket.end);
  if (!context.mounted) return;
  _showRecordSheet(
    context,
    title: '${DateFormat('MM/dd').format(bucket.start)} 起',
    records: records,
  );
}

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _selectedDays = 7;

  @override
  Widget build(BuildContext context) {
    // 监听记录变更：新增或删除记录后各图表自动重新取数
    ref.watch(statsRevisionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          // 时间维度切换
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7天')),
              ButtonSegment(value: 30, label: Text('30天')),
            ],
            selected: {_selectedDays},
            onSelectionChanged: (values) {
              setState(() => _selectedDays = values.first);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 摘要卡片
            _SummaryCard(days: _selectedDays),
            const SizedBox(height: 16),
            // 标签分布饼图
            _TagDistributionChart(days: _selectedDays),
            const SizedBox(height: 16),
            // 消费趋势折线图
            _SpendingTrendChart(days: _selectedDays),
            const SizedBox(height: 16),
            // 点餐频次柱状图
            _FrequencyChart(days: _selectedDays),
          ],
        ),
      ),
    );
  }
}

/// 摘要卡片
class _SummaryCard extends ConsumerWidget {
  final int days;

  const _SummaryCard({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsService = ref.watch(statsServiceProvider);

    return FutureBuilder<StatsSummary>(
      future: statsService.getSummary(days),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: SizedBox(height: 100));
        }
        final summary = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: '记录数',
                  value: '${summary.totalRecords}',
                  icon: Icons.receipt_long,
                ),
                _StatItem(
                  label: '总消费',
                  value: '￥${summary.totalSpent.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                ),
                _StatItem(
                  label: '均单价',
                  value: '￥${summary.avgPerMeal.toStringAsFixed(1)}',
                  icon: Icons.calculate,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// 标签分布饼图（点击扇区下钻）
class _TagDistributionChart extends ConsumerWidget {
  final int days;

  const _TagDistributionChart({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsService = ref.watch(statsServiceProvider);

    return FutureBuilder<List<TagDistribution>>(
      future: statsService.getTagDistribution(days),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            child: SizedBox(height: 200, child: Center(child: Text('暂无数据'))),
          );
        }
        final distributions = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('口味偏好', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                if (!event.isInterestedForInteractions) return;
                                final section = response?.touchedSection;
                                if (section == null) return;
                                final index = section.touchedSectionIndex;
                                if (index < 0 || index >= distributions.length) {
                                  return;
                                }
                                _openTagRecords(
                                  context,
                                  ref,
                                  distributions[index],
                                  days,
                                );
                              },
                            ),
                            sections: distributions.asMap().entries.map((entry) {
                              return PieChartSectionData(
                                value: entry.value.count.toDouble(),
                                title:
                                    '${(entry.value.ratio * 100).toStringAsFixed(0)}%',
                                color: _chartColors[
                                    entry.key % _chartColors.length],
                                radius: 60,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 图例
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: distributions
                            .take(5)
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  color: _chartColors[
                                      entry.key % _chartColors.length],
                                ),
                                const SizedBox(width: 4),
                                Text(entry.value.tagName),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 消费趋势折线图（点击数据点下钻）
class _SpendingTrendChart extends ConsumerWidget {
  final int days;

  const _SpendingTrendChart({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsService = ref.watch(statsServiceProvider);

    return FutureBuilder<List<DailySpending>>(
      future: statsService.getDailySpending(days),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            child: SizedBox(height: 200, child: Center(child: Text('暂无数据'))),
          );
        }
        final spending = snapshot.data!;
        final maxY =
            spending.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('消费趋势', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      lineTouchData: LineTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions) return;
                          final spots = response?.lineBarSpots;
                          if (spots == null || spots.isEmpty) return;
                          final index = spots.first.spotIndex;
                          if (index < 0 || index >= spending.length) return;
                          _openDayRecords(context, ref, spending[index].day);
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= spending.length) {
                                return const Text('');
                              }
                              return Text(
                                DateFormat('M/d').format(spending[index].day),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spending.asMap().entries.map((entry) {
                            return FlSpot(
                                entry.key.toDouble(), entry.value.amount);
                          }).toList(),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                          ),
                        ),
                      ],
                      minY: 0,
                      maxY: maxY * 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 点餐频次柱状图（7天按日 / 30天按周，点击柱下钻）
class _FrequencyChart extends ConsumerWidget {
  final int days;

  const _FrequencyChart({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsService = ref.watch(statsServiceProvider);

    return FutureBuilder<List<FrequencyBucket>>(
      future: statsService.getFrequencyStats(days),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            child: SizedBox(height: 200, child: Center(child: Text('暂无数据'))),
          );
        }
        final buckets = snapshot.data!;
        final maxCount =
            buckets.map((e) => e.count).reduce((a, b) => a > b ? a : b);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '点餐频次（${days <= 7 ? '按日' : '按周'}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxCount * 1.2,
                      barTouchData: BarTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions) return;
                          final index = response?.spot?.touchedBarGroupIndex;
                          if (index == null ||
                              index < 0 ||
                              index >= buckets.length) {
                            return;
                          }
                          _openBucketRecords(context, ref, buckets[index]);
                        },
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 32),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= buckets.length) {
                                return const Text('');
                              }
                              return Text(
                                DateFormat('M/d').format(buckets[index].start),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: buckets.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.count.toDouble(),
                              color: Theme.of(context).colorScheme.primary,
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
