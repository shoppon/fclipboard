//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class EntryGetResp {
  /// Returns a new [EntryGetResp] instance.
  EntryGetResp({
    this.entry,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Entry? entry;

  @override
  bool operator ==(Object other) => identical(this, other) || other is EntryGetResp &&
    other.entry == entry;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (entry == null ? 0 : entry!.hashCode);

  @override
  String toString() => 'EntryGetResp[entry=$entry]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.entry != null) {
      json[r'entry'] = this.entry;
    } else {
      json[r'entry'] = null;
    }
    return json;
  }

  /// Returns a new [EntryGetResp] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EntryGetResp? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "EntryGetResp[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "EntryGetResp[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return EntryGetResp(
        entry: Entry.fromJson(json[r'entry']),
      );
    }
    return null;
  }

  static List<EntryGetResp> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EntryGetResp>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EntryGetResp.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EntryGetResp> mapFromJson(dynamic json) {
    final map = <String, EntryGetResp>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EntryGetResp.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EntryGetResp-objects as value to a dart map
  static Map<String, List<EntryGetResp>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<EntryGetResp>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EntryGetResp.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

