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
    this.parameters = const [],
  });

  final int categoryId;
  final String title;
  final String subtitle;
  final String icon;
  final int counter;
  final List<Param> parameters;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'counter': counter,
      'category_id': categoryId,
    };
  }
}

class Param {
  int id;
  String name;
  String initial;
  int entryId;

  Param({
    this.id = -1,
    this.name = '',
    this.initial = '',
    this.entryId = 0,
  });

  Map<String, dynamic> toMap(int entryId) {
    return {
      'name': name,
      'initial': initial,
      'entry_id': entryId,
    };
  }
}
