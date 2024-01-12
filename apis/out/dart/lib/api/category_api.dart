//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class CategoryApi {
  CategoryApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a category
  ///
  /// Create a category
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [CategoryPostReq] categoryPostReq:
  Future<Response> createCategoryWithHttpInfo(String uid, { CategoryPostReq? categoryPostReq, }) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/categories'
      .replaceAll('{uid}', uid);

    // ignore: prefer_final_locals
    Object? postBody = categoryPostReq;

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

  /// Create a category
  ///
  /// Create a category
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  ///
  /// * [CategoryPostReq] categoryPostReq:
  Future<CategoryPostResp?> createCategory(String uid, { CategoryPostReq? categoryPostReq, }) async {
    final response = await createCategoryWithHttpInfo(uid,  categoryPostReq: categoryPostReq, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CategoryPostResp',) as CategoryPostResp;
    
    }
    return null;
  }

  /// List categories
  ///
  /// List categories
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  Future<Response> listCategoriesWithHttpInfo(String uid,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/{uid}/categories'
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

  /// List categories
  ///
  /// List categories
  ///
  /// Parameters:
  ///
  /// * [String] uid (required):
  ///   The user id
  Future<CategoryListResp?> listCategories(String uid,) async {
    final response = await listCategoriesWithHttpInfo(uid,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CategoryListResp',) as CategoryListResp;
    
    }
    return null;
  }
}
