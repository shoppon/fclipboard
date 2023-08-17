//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Entry {
  /// Returns a new [Entry] instance.
  Entry({
    this.title,
    this.content,
    this.category,
    this.counter,
    this.parameters = const [],
  });

  /// The title of the entry
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? title;

  /// The content of the entry
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? content;

  /// The category of the entry
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? category;

  /// The counter of the entry
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? counter;

  List<EntryParametersInner> parameters;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Entry &&
    other.title == title &&
    other.content == content &&
    other.category == category &&
    other.counter == counter &&
    _deepEquality.equals(other.parameters, parameters);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (title == null ? 0 : title!.hashCode) +
    (content == null ? 0 : content!.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (counter == null ? 0 : counter!.hashCode) +
    (parameters.hashCode);

  @override
  String toString() => 'Entry[title=$title, content=$content, category=$category, counter=$counter, parameters=$parameters]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.content != null) {
      json[r'content'] = this.content;
    } else {
      json[r'content'] = null;
    }
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
    if (this.counter != null) {
      json[r'counter'] = this.counter;
    } else {
      json[r'counter'] = null;
    }
      json[r'parameters'] = this.parameters;
    return json;
  }

  /// Returns a new [Entry] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Entry? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Entry[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Entry[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Entry(
        title: mapValueOfType<String>(json, r'title'),
        content: mapValueOfType<String>(json, r'content'),
        category: mapValueOfType<String>(json, r'category'),
        counter: mapValueOfType<int>(json, r'counter'),
        parameters: EntryParametersInner.listFromJson(json[r'parameters']),
      );
    }
    return null;
  }

  static List<Entry> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Entry>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Entry.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Entry> mapFromJson(dynamic json) {
    final map = <String, Entry>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Entry.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Entry-objects as value to a dart map
  static Map<String, List<Entry>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Entry>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Entry.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

