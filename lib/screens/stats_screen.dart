import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
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

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _selectedDays = 7;

  @override
  Widget build(BuildContext context) {
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

/// 标签分布饼图
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
                            sections: distributions.asMap().entries.map((entry) {
                              return PieChartSectionData(
                                value: entry.value.count.toDouble(),
                                title: '${(entry.value.ratio * 100).toStringAsFixed(0)}%',
                                color: _chartColors[entry.key % _chartColors.length],
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
                        children: distributions.take(5).toList().asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  color: _chartColors[entry.key % _chartColors.length],
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

/// 消费趋势折线图
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
        final maxY = spending.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

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
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < spending.length) {
                                return Text(
                                  spending[index].date,
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spending.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.amount);
                          }).toList(),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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