/// 店铺模型（收藏用）
class Shop {
  final int id;
  final String name;
  final bool isFavorite;
  final List<int> tagIds;
  final DateTime createdAt;

  const Shop({
    required this.id,
    required this.name,
    this.isFavorite = false,
    required this.tagIds,
    required this.createdAt,
  });

  Shop copyWith({
    int? id,
    String? name,
    bool? isFavorite,
    List<int>? tagIds,
    DateTime? createdAt,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
      tagIds: tagIds ?? this.tagIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}