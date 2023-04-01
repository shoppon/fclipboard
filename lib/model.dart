class Category {
  Category({
    required this.name,
    required this.icon,
  });

  final String name;
  final String icon;

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
    this.category = 'default',
    this.icon = 'assets/icons/clipboard.png',
  });

  final String category;
  final String title;
  final String subtitle;
  final String icon;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'category': category,
    };
  }
}
