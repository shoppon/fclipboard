# openapi.api.EntryApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createEntry**](EntryApi.md#createentry) | **POST** /v1/{uid}/entries | Create an entry
[**deleteEntry**](EntryApi.md#deleteentry) | **DELETE** /v1/{uid}/entries/{eid} | Delete an entry
[**getEntry**](EntryApi.md#getentry) | **GET** /v1/{uid}/entries/{eid} | Get an entry
[**listEntries**](EntryApi.md#listentries) | **GET** /v1/{uid}/entries | List entries
[**updateEntry**](EntryApi.md#updateentry) | **PATCH** /v1/{uid}/entries/{eid} | Update an entry


# **createEntry**
> EntryPostResp createEntry(uid, entryPostReq)

Create an entry

Create an entry

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = EntryApi();
final uid = shopppon@gmail.com; // String | The user id
final entryPostReq = EntryPostReq(); // EntryPostReq | 

try {
    final result = api_instance.createEntry(uid, entryPostReq);
    print(result);
} catch (e) {
    print('Exception when calling EntryApi->createEntry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 
 **entryPostReq** | [**EntryPostReq**](EntryPostReq.md)|  | [optional] 

### Return type

[**EntryPostResp**](EntryPostResp.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteEntry**
> deleteEntry(uid, eid)

Delete an entry

Delete an entry

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = EntryApi();
final uid = shopppon@gmail.com; // String | The user id
final eid = d290f1ee-6c54-4b01-90e6-d701748f0851; // String | The entry id

try {
    api_instance.deleteEntry(uid, eid);
} catch (e) {
    print('Exception when calling EntryApi->deleteEntry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 
 **eid** | **String**| The entry id | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getEntry**
> EntryGetResp getEntry(uid, eid)

Get an entry

Get an entry

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = EntryApi();
final uid = shopppon@gmail.com; // String | The user id
final eid = d290f1ee-6c54-4b01-90e6-d701748f0851; // String | The entry id

try {
    final result = api_instance.getEntry(uid, eid);
    print(result);
} catch (e) {
    print('Exception when calling EntryApi->getEntry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 
 **eid** | **String**| The entry id | 

### Return type

[**EntryGetResp**](EntryGetResp.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listEntries**
> EntryListResp listEntries(uid)

List entries

List entries

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = EntryApi();
final uid = shopppon@gmail.com; // String | The user id

try {
    final result = api_instance.listEntries(uid);
    print(result);
} catch (e) {
    print('Exception when calling EntryApi->listEntries: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 

### Return type

[**EntryListResp**](EntryListResp.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateEntry**
> EntryPatchResp updateEntry(uid, eid, entryPatchReq)

Update an entry

Update an entry

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = EntryApi();
final uid = shopppon@gmail.com; // String | The user id
final eid = d290f1ee-6c54-4b01-90e6-d701748f0851; // String | The entry id
final entryPatchReq = EntryPatchReq(); // EntryPatchReq | 

try {
    final result = api_instance.updateEntry(uid, eid, entryPatchReq);
    print(result);
} catch (e) {
    print('Exception when calling EntryApi->updateEntry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 
 **eid** | **String**| The entry id | 
 **entryPatchReq** | [**EntryPatchReq**](EntryPatchReq.md)|  | [optional] 

### Return type

[**EntryPatchResp**](EntryPatchResp.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

