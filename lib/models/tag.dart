/// 标签维度枚举
enum TagDimension {
  taste, // 口味
  type, // 类型
  cuisine, // 菜系
}

/// 美食标签模型
class Tag {
  final int id;
  final String name;
  final TagDimension dimension;
  final bool isSystem;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    required this.dimension,
    this.isSystem = false,
    required this.createdAt,
  });

  Tag copyWith({
    int? id,
    String? name,
    TagDimension? dimension,
    bool? isSystem,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      dimension: dimension ?? this.dimension,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}