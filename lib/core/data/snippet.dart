class Snippet {
  const Snippet({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    required this.createdAt,
    required this.version,
    this.parameters = const [],
    this.tagId,
    this.deletedAt,
    this.conflictOf,
    this.tags = const [],
    this.source,
    this.pinned = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final List<String> tags;
  final String? tagId;
  final String? source;
  final bool pinned;
  final DateTime? deletedAt;
  final String? conflictOf;
  final List<EntryParameter> parameters;

  Snippet copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? updatedAt,
    DateTime? createdAt,
    int? version,
    List<EntryParameter>? parameters,
    String? tagId,
    List<String>? tags,
    String? source,
    bool? pinned,
    DateTime? deletedAt,
    String? conflictOf,
  }) {
    return Snippet(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      parameters: parameters ?? this.parameters,
      tagId: tagId ?? this.tagId,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      pinned: pinned ?? this.pinned,
      deletedAt: deletedAt ?? this.deletedAt,
      conflictOf: conflictOf ?? this.conflictOf,
    );
  }
}

class EntryParameter {
  const EntryParameter({
    this.name = '',
    this.description,
    this.initial,
    this.required = false,
  });

  final String name;
  final String? description;
  final String? initial;
  final bool required;

  EntryParameter copyWith({
    String? name,
    String? description,
    String? initial,
    bool? required,
  }) {
    return EntryParameter(
      name: name ?? this.name,
      description: description ?? this.description,
      initial: initial ?? this.initial,
      required: required ?? this.required,
    );
  }

  factory EntryParameter.fromJson(Map<String, dynamic> json) {
    return EntryParameter(
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      initial: json['initial'] as String?,
      required: json['required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'initial': initial,
        'required': required,
      };
}
