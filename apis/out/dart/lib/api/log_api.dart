//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class LogApi {
  LogApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// upload a log
  ///
  /// upload a log
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [LogPostReq] logPostReq:
  Future<Response> uploadLogWithHttpInfo(String uid, { LogPostReq? logPostReq, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/logs'
      .replaceAll('{uid}', uid);

    // ignore: prefer_final_locals
    Object? postBody = logPostReq;

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

  /// upload a log
  ///
  /// upload a log
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [LogPostReq] logPostReq:
  Future<void> uploadLog(String uid, { LogPostReq? logPostReq, }) async {
    final response = await uploadLogWithHttpInfo(uid,  logPostReq: logPostReq, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
