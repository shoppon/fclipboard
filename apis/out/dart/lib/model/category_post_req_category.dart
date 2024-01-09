//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CategoryPostReqCategory {
  /// Returns a new [CategoryPostReqCategory] instance.
  CategoryPostReqCategory({
    this.name,
    this.description,
    this.isPrivate,
    this.icon,
  });

  /// The name of the category
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  /// The description of the category
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  /// Whether the category is private
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isPrivate;

  /// The icon of the category
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? icon;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CategoryPostReqCategory &&
    other.name == name &&
    other.description == description &&
    other.isPrivate == isPrivate &&
    other.icon == icon;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (isPrivate == null ? 0 : isPrivate!.hashCode) +
    (icon == null ? 0 : icon!.hashCode);

  @override
  String toString() => 'CategoryPostReqCategory[name=$name, description=$description, isPrivate=$isPrivate, icon=$icon]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.isPrivate != null) {
      json[r'is_private'] = this.isPrivate;
    } else {
      json[r'is_private'] = null;
    }
    if (this.icon != null) {
      json[r'icon'] = this.icon;
    } else {
      json[r'icon'] = null;
    }
    return json;
  }

  /// Returns a new [CategoryPostReqCategory] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CategoryPostReqCategory? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CategoryPostReqCategory[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CategoryPostReqCategory[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CategoryPostReqCategory(
        name: mapValueOfType<String>(json, r'name'),
        description: mapValueOfType<String>(json, r'description'),
        isPrivate: mapValueOfType<bool>(json, r'is_private'),
        icon: mapValueOfType<String>(json, r'icon'),
      );
    }
    return null;
  }

  static List<CategoryPostReqCategory> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CategoryPostReqCategory>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CategoryPostReqCategory.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CategoryPostReqCategory> mapFromJson(dynamic json) {
    final map = <String, CategoryPostReqCategory>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CategoryPostReqCategory.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CategoryPostReqCategory-objects as value to a dart map
  static Map<String, List<CategoryPostReqCategory>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CategoryPostReqCategory>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CategoryPostReqCategory.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

