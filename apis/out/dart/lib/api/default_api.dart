//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DefaultApi {
  DefaultApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a subscription
  ///
  /// Create a subscription
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [SubscriptionPostReq] subscriptionPostReq:
  Future<Response> createSubscriptionWithHttpInfo(String uid, { SubscriptionPostReq? subscriptionPostReq, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/subscriptions'
      .replaceAll('{uid}', uid);

    // ignore: prefer_final_locals
    Object? postBody = subscriptionPostReq;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a subscription
  ///
  /// Create a subscription
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [SubscriptionPostReq] subscriptionPostReq:
  Future<SubscriptionPostResp?> createSubscription(String uid, { SubscriptionPostReq? subscriptionPostReq, }) async {
    final response = await createSubscriptionWithHttpInfo(uid,  subscriptionPostReq: subscriptionPostReq, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SubscriptionPostResp',) as SubscriptionPostResp;
    
    }
    return null;
  }

  /// List subscriptions
  ///
  /// List subscriptions
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  Future<Response> listSubscriptionsWithHttpInfo(String uid,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/subscriptions'
      .replaceAll('{uid}', uid);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List subscriptions
  ///
  /// List subscriptions
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  Future<SubscriptionListResp?> listSubscriptions(String uid,) async {
    final response = await listSubscriptionsWithHttpInfo(uid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SubscriptionListResp',) as SubscriptionListResp;
    
    }
    return null;
  }

  /// Pull a subscription
  ///
  /// Pull a subscription
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [String] sid (required):
  ///   The subscription id
  Future<Response> pullSubscriptionWithHttpInfo(String uid, String sid,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/subscriptions/{sid}/pull'
      .replaceAll('{uid}', uid)
      .replaceAll('{sid}', sid);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Pull a subscription
  ///
  /// Pull a subscription
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [String] sid (required):
  ///   The subscription id
  Future<SubscriptionPullResp?> pullSubscription(String uid, String sid,) async {
    final response = await pullSubscriptionWithHttpInfo(uid, sid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SubscriptionPullResp',) as SubscriptionPullResp;
    
    }
    return null;
  }

  /// Push a subscription
  ///
  /// Push a subscription
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [String] sid (required):
  ///   The subscription id
  ///
  /// * [SubscriptionPushReq] subscriptionPushReq:
  Future<Response> pushSubscriptionWithHttpInfo(String uid, String sid, { SubscriptionPushReq? subscriptionPushReq, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}subscriptions/{sid}/push'
      .replaceAll('{uid}', uid)
      .replaceAll('{sid}', sid);

    // ignore: prefer_final_locals
    Object? postBody = subscriptionPushReq;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Push a subscription
  ///
  /// Push a subscription
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [String] sid (required):
  ///   The subscription id
  ///
  /// * [SubscriptionPushReq] subscriptionPushReq:
  Future<Subscription?> pushSubscription(String uid, String sid, { SubscriptionPushReq? subscriptionPushReq, }) async {
    final response = await pushSubscriptionWithHttpInfo(uid, sid,  subscriptionPushReq: subscriptionPushReq, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Subscription',) as Subscription;
    
    }
    return null;
  }
}
