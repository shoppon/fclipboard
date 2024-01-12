# openapi.api.CategoryApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createCategory**](CategoryApi.md#createcategory) | **POST** /v1/{uid}/categories | Create a category
[**listCategories**](CategoryApi.md#listcategories) | **GET** /v1/{uid}/categories | List categories


# **createCategory**
> CategoryPostResp createCategory(uid, categoryPostReq)

Create a category

Create a category

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CategoryApi();
final uid = shopppon@gmail.com; // String | The user id
final categoryPostReq = CategoryPostReq(); // CategoryPostReq | 

try {
    final result = api_instance.createCategory(uid, categoryPostReq);
    print(result);
} catch (e) {
    print('Exception when calling CategoryApi->createCategory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 
 **categoryPostReq** | [**CategoryPostReq**](CategoryPostReq.md)|  | [optional] 

### Return type

[**CategoryPostResp**](CategoryPostResp.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listCategories**
> CategoryListResp listCategories(uid)

List categories

List categories

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CategoryApi();
final uid = shopppon@gmail.com; // String | The user id

try {
    final result = api_instance.listCategories(uid);
    print(result);
} catch (e) {
    print('Exception when calling CategoryApi->listCategories: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 

### Return type

[**CategoryListResp**](CategoryListResp.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

