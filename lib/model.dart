class Category {
  Category({
    required this.name,
    required this.icon,
    this.id = 0,
  });

  final String name;
  final String icon;
  final int id;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
    };
  }
}

class Entry {
  Entry({
    required this.title,
    required this.subtitle,
    required this.categoryId,
    this.icon = '',
  });

  final int categoryId;
  final String title;
  final String subtitle;
  final String icon;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'category_id': categoryId,
    };
  }
}
