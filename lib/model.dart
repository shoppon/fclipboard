import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

class Category {
  Category({
    required this.name,
    required this.icon,
    this.id = 0,
    this.uuid = '',
    this.isPrivate = false,
  });

  String uuid;
  final int id;
  String name;
  String icon;
  bool isPrivate;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uuid': uuid,
      'name': name,
      'icon': icon,
      'is_private': isPrivate ? 1 : 0,
    };
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }
}

@JsonSerializable(explicitToJson: true)
class Param {
  int id;
  String name;
  String initial;
  String current;
  int entryId;
  bool required = false;
  String description = '';

  Param({
    this.id = 0,
    this.name = '',
    this.initial = '',
    this.current = '',
    this.entryId = 0,
    this.required = false,
    this.description = '',
  });

  Map<String, dynamic> toMap(int entryId) {
    final map = {
      'name': name,
      'initial': initial,
      'entry_id': entryId,
      'required': required ? 1 : 0,
      'description': description,
    };
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }

  factory Param.fromJson(Map<String, dynamic> json) => _$ParamFromJson(json);

  Map<String, dynamic> toJson() => _$ParamToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Entry {
  Entry({
    required this.title,
    required this.subtitle,
    required this.categoryId,
    required this.counter,
    this.version = 0,
    this.id = 0,
    this.uuid = '',
    this.icon = '',
    this.categoryName = '',
    this.parameters = const [],
  });

  int id;
  int categoryId;
  String uuid;
  final String categoryName;
  String title;
  String subtitle;
  final String icon;
  final int counter;
  int version;
  List<Param> parameters;

  Map<String, dynamic> toMap() {
    final map = {
      'uuid': uuid,
      'title': title,
      'subtitle': subtitle,
      'counter': counter,
      'version': version,
      'category_id': categoryId,
    };
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }

  static Entry empty() {
    return Entry(
      categoryId: 0,
      title: '',
      uuid: '',
      subtitle: '',
      counter: 0,
      version: 0,
      parameters: [],
    );
  }

  factory Entry.fromJson(Map<String, dynamic> json) => _$EntryFromJson(json);

  Map<String, dynamic> toJson() => _$EntryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Book {
  int id;
  String uuid;
  String title;
  String author;

  Book({
    this.id = 0,
    this.uuid = '',
    this.title = '',
    this.author = '',
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'uuid': uuid,
      'title': title,
      'author': author,
    };
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  Map<String, dynamic> toJson() => _$BookToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Annotation {
  int id;
  String uuid;
  String bookId;
  String location;
  String selected;
  String highlight;
  int color;
  double createdAt;
  Book? book;

  Annotation({
    this.id = 0,
    this.uuid = '',
    this.bookId = '',
    this.location = '',
    this.selected = '',
    this.highlight = '',
    this.color = 0,
    this.createdAt = 0.0,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'uuid': uuid,
      'book_id': bookId,
      'location': location,
      'selected': selected,
      'highlight': highlight,
      'color': color,
      'created_at': createdAt,
    };
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }

  factory Annotation.fromJson(Map<String, dynamic> json) =>
      _$AnnotationFromJson(json);

  Map<String, dynamic> toJson() => _$AnnotationToJson(this);
}
