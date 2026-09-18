/// 外卖记录模型
class MealRecord {
  final int id;
  final String shopName;
  final double price;
  final List<int> tagIds;
  final String? dishName;
  final String? note;
  final DateTime mealTime;
  final DateTime createdAt;

  const MealRecord({
    required this.id,
    required this.shopName,
    required this.price,
    required this.tagIds,
    this.dishName,
    this.note,
    required this.mealTime,
    required this.createdAt,
  });

  MealRecord copyWith({
    int? id,
    String? shopName,
    double? price,
    List<int>? tagIds,
    String? dishName,
    String? note,
    DateTime? mealTime,
    DateTime? createdAt,
  }) {
    return MealRecord(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      price: price ?? this.price,
      tagIds: tagIds ?? this.tagIds,
      dishName: dishName ?? this.dishName,
      note: note ?? this.note,
      mealTime: mealTime ?? this.mealTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}