# openapi.api.CategoryApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createCategory**](CategoryApi.md#createcategory) | **POST** /v1/{uid}/categories | Create a category


# **createCategory**
> createCategory(uid, categoryPostReq)

Create a category

Create a category

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CategoryApi();
final uid = shopppon@gmail.com; // String | The user id
final categoryPostReq = CategoryPostReq(); // CategoryPostReq | 

try {
    api_instance.createCategory(uid, categoryPostReq);
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

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

