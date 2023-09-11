//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SubscriptionPostReqSubscription {
  /// Returns a new [SubscriptionPostReqSubscription] instance.
  SubscriptionPostReqSubscription({
    this.name,
    this.description,
    this.categories = const [],
    this.public,
  });

  /// The name of the subscription
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  /// The description of the subscription
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  List<String> categories;

  /// whether the subscription is public
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? public;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubscriptionPostReqSubscription &&
    other.name == name &&
    other.description == description &&
    _deepEquality.equals(other.categories, categories) &&
    other.public == public;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (categories.hashCode) +
    (public == null ? 0 : public!.hashCode);

  @override
  String toString() => 'SubscriptionPostReqSubscription[name=$name, description=$description, categories=$categories, public=$public]';

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
      json[r'categories'] = this.categories;
    if (this.public != null) {
      json[r'public'] = this.public;
    } else {
      json[r'public'] = null;
    }
    return json;
  }

  /// Returns a new [SubscriptionPostReqSubscription] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubscriptionPostReqSubscription? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SubscriptionPostReqSubscription[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SubscriptionPostReqSubscription[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SubscriptionPostReqSubscription(
        name: mapValueOfType<String>(json, r'name'),
        description: mapValueOfType<String>(json, r'description'),
        categories: json[r'categories'] is Iterable
            ? (json[r'categories'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        public: mapValueOfType<bool>(json, r'public'),
      );
    }
    return null;
  }

  static List<SubscriptionPostReqSubscription> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubscriptionPostReqSubscription>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubscriptionPostReqSubscription.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubscriptionPostReqSubscription> mapFromJson(dynamic json) {
    final map = <String, SubscriptionPostReqSubscription>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubscriptionPostReqSubscription.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubscriptionPostReqSubscription-objects as value to a dart map
  static Map<String, List<SubscriptionPostReqSubscription>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubscriptionPostReqSubscription>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubscriptionPostReqSubscription.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

