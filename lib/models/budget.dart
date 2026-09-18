/// 月度预算模型
class Budget {
  final int id;
  final String month; // 格式: YYYY-MM
  final double amount;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.month,
    required this.amount,
    required this.createdAt,
  });

  Budget copyWith({
    int? id,
    String? month,
    double? amount,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}