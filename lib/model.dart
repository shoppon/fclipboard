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
    required this.counter,
    this.icon = '',
  });

  final int categoryId;
  final String title;
  final String subtitle;
  final String icon;
  final int counter;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'counter': counter,
      'category_id': categoryId,
    };
  }
}
