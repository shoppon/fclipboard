// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Param _$ParamFromJson(Map<String, dynamic> json) => Param(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initial: json['initial'] as String? ?? '',
      current: json['current'] as String? ?? '',
      entryId: json['entryId'] as int? ?? 0,
      required: json['required'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );

Map<String, dynamic> _$ParamToJson(Param instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'initial': instance.initial,
      'current': instance.current,
      'entryId': instance.entryId,
      'required': instance.required,
      'description': instance.description,
    };

Entry _$EntryFromJson(Map<String, dynamic> json) => Entry(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      categoryId: json['categoryId'] as int,
      counter: json['counter'] as int,
      version: json['version'] as int? ?? 0,
      id: json['id'] as int? ?? 0,
      uuid: json['uuid'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      parameters: (json['parameters'] as List<dynamic>?)
              ?.map((e) => Param.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$EntryToJson(Entry instance) => <String, dynamic>{
      'id': instance.id,
      'categoryId': instance.categoryId,
      'uuid': instance.uuid,
      'categoryName': instance.categoryName,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'icon': instance.icon,
      'counter': instance.counter,
      'version': instance.version,
      'parameters': instance.parameters.map((e) => e.toJson()).toList(),
    };

Book _$BookFromJson(Map<String, dynamic> json) => Book(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'title': instance.title,
      'author': instance.author,
    };

Annotation _$AnnotationFromJson(Map<String, dynamic> json) => Annotation(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      location: json['location'] as String? ?? '',
      selected: json['selected'] as String? ?? '',
      highlight: json['highlight'] as String? ?? '',
      color: json['color'] as int? ?? 0,
      createdAt: (json['createdAt'] as num?)?.toDouble() ?? 0.0,
    )..book = json['book'] == null
        ? null
        : Book.fromJson(json['book'] as Map<String, dynamic>);

Map<String, dynamic> _$AnnotationToJson(Annotation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uuid': instance.uuid,
      'bookId': instance.bookId,
      'location': instance.location,
      'selected': instance.selected,
      'highlight': instance.highlight,
      'color': instance.color,
      'createdAt': instance.createdAt,
      'book': instance.book?.toJson(),
    };
