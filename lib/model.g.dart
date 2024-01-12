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
      'parameters': instance.parameters.map((e) => e.toJson()).toList(),
    };
