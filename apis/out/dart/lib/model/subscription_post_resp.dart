//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SubscriptionPostResp {
  /// Returns a new [SubscriptionPostResp] instance.
  SubscriptionPostResp({
    this.subscription,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Subscription? subscription;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubscriptionPostResp &&
    other.subscription == subscription;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (subscription == null ? 0 : subscription!.hashCode);

  @override
  String toString() => 'SubscriptionPostResp[subscription=$subscription]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.subscription != null) {
      json[r'subscription'] = this.subscription;
    } else {
      json[r'subscription'] = null;
    }
    return json;
  }

  /// Returns a new [SubscriptionPostResp] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubscriptionPostResp? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SubscriptionPostResp[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SubscriptionPostResp[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SubscriptionPostResp(
        subscription: Subscription.fromJson(json[r'subscription']),
      );
    }
    return null;
  }

  static List<SubscriptionPostResp> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubscriptionPostResp>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubscriptionPostResp.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubscriptionPostResp> mapFromJson(dynamic json) {
    final map = <String, SubscriptionPostResp>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubscriptionPostResp.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubscriptionPostResp-objects as value to a dart map
  static Map<String, List<SubscriptionPostResp>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubscriptionPostResp>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubscriptionPostResp.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

