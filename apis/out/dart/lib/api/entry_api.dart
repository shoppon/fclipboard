//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class EntryApi {
  EntryApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create an entry
  ///
  /// Create an entry
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [EntryPostReq] entryPostReq:
  Future<Response> createEntryWithHttpInfo(String uid, { EntryPostReq? entryPostReq, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/entries'
      .replaceAll('{uid}', uid);

    // ignore: prefer_final_locals
    Object? postBody = entryPostReq;

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

  /// Create an entry
  ///
  /// Create an entry
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [EntryPostReq] entryPostReq:
  Future<EntryPostResp?> createEntry(String uid, { EntryPostReq? entryPostReq, }) async {
    final response = await createEntryWithHttpInfo(uid,  entryPostReq: entryPostReq, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'EntryPostResp',) as EntryPostResp;
    
    }
    return null;
  }

  /// Delete an entry
  ///
  /// Delete an entry
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [String] eid (required):
  ///   The entry id
  Future<Response> deleteEntryWithHttpInfo(String uid, String eid,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/entries/{eid}'
      .replaceAll('{uid}', uid)
      .replaceAll('{eid}', eid);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Delete an entry
  ///
  /// Delete an entry
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [String] eid (required):
  ///   The entry id
  Future<void> deleteEntry(String uid, String eid,) async {
    final response = await deleteEntryWithHttpInfo(uid, eid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get an entry
  ///
  /// Get an entry
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [String] eid (required):
  ///   The entry id
  Future<Response> getEntryWithHttpInfo(String uid, String eid,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/entries/{eid}'
      .replaceAll('{uid}', uid)
      .replaceAll('{eid}', eid);

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

  /// Get an entry
  ///
  /// Get an entry
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [String] eid (required):
  ///   The entry id
  Future<EntryGetResp?> getEntry(String uid, String eid,) async {
    final response = await getEntryWithHttpInfo(uid, eid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'EntryGetResp',) as EntryGetResp;
    
    }
    return null;
  }

  /// List entries
  ///
  /// List entries
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  Future<Response> listEntriesWithHttpInfo(String uid,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/entries'
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

  /// List entries
  ///
  /// List entries
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  Future<EntryListResp?> listEntries(String uid,) async {
    final response = await listEntriesWithHttpInfo(uid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'EntryListResp',) as EntryListResp;
    
    }
    return null;
  }

  /// Update an entry
  ///
  /// Update an entry
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [String] eid (required):
  ///   The entry id
  ///
  /// * [EntryPatchReq] entryPatchReq:
  Future<Response> updateEntryWithHttpInfo(String uid, String eid, { EntryPatchReq? entryPatchReq, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/entries/{eid}'
      .replaceAll('{uid}', uid)
      .replaceAll('{eid}', eid);

    // ignore: prefer_final_locals
    Object? postBody = entryPatchReq;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Update an entry
  ///
  /// Update an entry
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [String] eid (required):
  ///   The entry id
  ///
  /// * [EntryPatchReq] entryPatchReq:
  Future<EntryPatchResp?> updateEntry(String uid, String eid, { EntryPatchReq? entryPatchReq, }) async {
    final response = await updateEntryWithHttpInfo(uid, eid,  entryPatchReq: entryPatchReq, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'EntryPatchResp',) as EntryPatchResp;
    
    }
    return null;
  }
}
