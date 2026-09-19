import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  /// 获取所有预算
  Future<List<Budget>> getAllBudgets() =>
      (select(budgets)..orderBy([(b) => OrderingTerm.desc(b.month)])).get();

  /// 监听所有预算变化
  Stream<List<Budget>> watchAllBudgets() =>
      (select(budgets)..orderBy([(b) => OrderingTerm.desc(b.month)])).watch();

  /// 获取指定月份的预算
  Future<Budget?> getBudgetByMonth(String month) =>
      (select(budgets)..where((b) => b.month.equals(month))).getSingleOrNull();

  /// 监听指定月份的预算
  Stream<Budget?> watchBudgetByMonth(String month) =>
      (select(budgets)..where((b) => b.month.equals(month))).watchSingleOrNull();

  /// 插入或更新预算
  Future<void> upsertBudget(String month, double amount) async {
    final existing = await getBudgetByMonth(month);
    if (existing != null) {
      await updateBudget(
        BudgetsCompanion(
          id: Value(existing.id),
          amount: Value(amount),
        ),
      );
    } else {
      await insertBudget(
        BudgetsCompanion(
          month: Value(month),
          amount: Value(amount),
        ),
      );
    }
  }

  /// 插入预算
  Future<int> insertBudget(BudgetsCompanion entry) =>
      into(budgets).insert(entry);

  /// 更新预算
  Future<bool> updateBudget(BudgetsCompanion entry) =>
      update(budgets).replace(entry);

  /// 删除预算
  Future<int> deleteBudget(int id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();

  /// 用给定数据替换全部预算（传空列表即清空）
  Future<void> replaceAll(List<BudgetsCompanion> entries) async {
    await transaction(() async {
      await delete(budgets).go();
      if (entries.isNotEmpty) {
        await batch((b) => b.insertAll(budgets, entries));
      }
    });
  }
}