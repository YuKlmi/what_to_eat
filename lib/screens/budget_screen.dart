import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../database/database_provider.dart';
import '../database/app_database.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _budgetController = TextEditingController();
  final String _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final db = ref.read(appDatabaseProvider);
    final budget = await db.budgetDao.getBudgetByMonth(_currentMonth);
    if (budget != null && mounted) {
      _budgetController.text = budget.amount.toString();
    }
  }

  Future<void> _saveBudget() async {
    final amount = double.tryParse(_budgetController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的预算金额')),
      );
      return;
    }

    final db = ref.read(appDatabaseProvider);
    await db.budgetDao.upsertBudget(_currentMonth, amount);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预算已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('预算管理'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
          // 当前月份预算设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_currentMonth 月预算',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '预算金额',
                            prefixText: '￥ ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: _saveBudget,
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 消费进度
          StreamBuilder<Budget?>(
            stream: db.budgetDao.watchBudgetByMonth(_currentMonth),
            builder: (context, budgetSnapshot) {
              if (!budgetSnapshot.hasData || budgetSnapshot.data == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('请先设置本月预算'),
                  ),
                );
              }

              final budget = budgetSnapshot.data!;
              return FutureBuilder<double>(
                future: db.recordDao.getTotalSpentByMonth(_currentMonth),
                builder: (context, spentSnapshot) {
                  final spent = spentSnapshot.data ?? 0;
                  final progress = budget.amount > 0
                      ? (spent / budget.amount).clamp(0.0, 1.0)
                      : 0.0;
                  final isOverBudget = spent > budget.amount;
                  final isWarning = spent > budget.amount * 0.8;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '消费进度',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (isOverBudget)
                                const Chip(
                                  label: Text('超支',
                                      style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                )
                              else if (isWarning)
                                const Chip(
                                  label: Text('即将超支',
                                      style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.orange,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 20,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget
                                  ? Colors.red
                                  : isWarning
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('已消费: ￥${spent.toStringAsFixed(0)}'),
                              Text('预算: ￥${budget.amount.toStringAsFixed(0)}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '剩余: ￥${(budget.amount - spent).toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isOverBudget ? Colors.red : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // 历史预算对比
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '历史预算',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Budget>>(
                    future: db.budgetDao.getAllBudgets(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('暂无历史预算');
                      }
                      final budgets = snapshot.data!;
                      return Column(
                        children: budgets.map((budget) {
                          return ListTile(
                            title: Text(budget.month),
                            trailing: Text(
                              '￥${budget.amount.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }
}