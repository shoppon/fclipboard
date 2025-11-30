class Category {
  const Category({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.color,
    this.version = 1,
  });

  final String id;
  final String name;
  final String? color;
  final DateTime updatedAt;
  final int version;

  Category copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? updatedAt,
    int? version,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
