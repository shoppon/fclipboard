# openapi.api.LogApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**uploadLog**](LogApi.md#uploadlog) | **POST** /v1/{uid}/logs | upload a log


# **uploadLog**
> uploadLog(uid, logPostReq)

upload a log

upload a log

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = LogApi();
final uid = shopppon@gmail.com; // String | The user id
final logPostReq = LogPostReq(); // LogPostReq | 

try {
    api_instance.uploadLog(uid, logPostReq);
} catch (e) {
    print('Exception when calling LogApi->uploadLog: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 
 **logPostReq** | [**LogPostReq**](LogPostReq.md)|  | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

