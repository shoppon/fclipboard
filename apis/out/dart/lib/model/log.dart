//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Log {
  /// Returns a new [Log] instance.
  Log({
    required this.action,
    required this.content,
    this.stack,
    required this.platform,
  });

  /// The action of the log
  String action;

  /// The content of the log
  String content;

  /// The stack of the log
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? stack;

  /// The platform of the log
  String platform;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Log &&
    other.action == action &&
    other.content == content &&
    other.stack == stack &&
    other.platform == platform;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (action.hashCode) +
    (content.hashCode) +
    (stack == null ? 0 : stack!.hashCode) +
    (platform.hashCode);

  @override
  String toString() => 'Log[action=$action, content=$content, stack=$stack, platform=$platform]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'action'] = this.action;
      json[r'content'] = this.content;
    if (this.stack != null) {
      json[r'stack'] = this.stack;
    } else {
      json[r'stack'] = null;
    }
      json[r'platform'] = this.platform;
    return json;
  }

  /// Returns a new [Log] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Log? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Log[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Log[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Log(
        action: mapValueOfType<String>(json, r'action')!,
        content: mapValueOfType<String>(json, r'content')!,
        stack: mapValueOfType<String>(json, r'stack'),
        platform: mapValueOfType<String>(json, r'platform')!,
      );
    }
    return null;
  }

  static List<Log> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Log>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Log.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Log> mapFromJson(dynamic json) {
    final map = <String, Log>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Log.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Log-objects as value to a dart map
  static Map<String, List<Log>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Log>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Log.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'action',
    'content',
    'platform',
  };
}

