# openapi.api.SubscriptionApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createSubscription**](SubscriptionApi.md#createsubscription) | **POST** /v1/{uid}/subscriptions | Create a subscription
[**listSubscriptions**](SubscriptionApi.md#listsubscriptions) | **GET** /v1/{uid}/subscriptions | List subscriptions
[**pullSubscription**](SubscriptionApi.md#pullsubscription) | **GET** /v1/{uid}/subscriptions/{sid}/pull | Pull a subscription
[**pushSubscription**](SubscriptionApi.md#pushsubscription) | **POST** /v1/{uid}/subscriptions/{sid}/push | Push a subscription


# **createSubscription**
> SubscriptionPostResp createSubscription(uid, subscriptionPostReq)

Create a subscription

Create a subscription

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubscriptionApi();
final uid = shopppon@gmail.com; // String | The user id
final subscriptionPostReq = SubscriptionPostReq(); // SubscriptionPostReq | 

try {
    final result = api_instance.createSubscription(uid, subscriptionPostReq);
    print(result);
} catch (e) {
    print('Exception when calling SubscriptionApi->createSubscription: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 
 **subscriptionPostReq** | [**SubscriptionPostReq**](SubscriptionPostReq.md)|  | [optional] 

### Return type

[**SubscriptionPostResp**](SubscriptionPostResp.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listSubscriptions**
> SubscriptionListResp listSubscriptions(uid)

List subscriptions

List subscriptions

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubscriptionApi();
final uid = shopppon@gmail.com; // String | The user id

try {
    final result = api_instance.listSubscriptions(uid);
    print(result);
} catch (e) {
    print('Exception when calling SubscriptionApi->listSubscriptions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 

### Return type

[**SubscriptionListResp**](SubscriptionListResp.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **pullSubscription**
> SubscriptionPullResp pullSubscription(uid, sid)

Pull a subscription

Pull a subscription

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubscriptionApi();
final uid = shopppon@gmail.com; // String | The user id
final sid = d290f1ee-6c54-4b01-90e6-d701748f0851; // String | The subscription id

try {
    final result = api_instance.pullSubscription(uid, sid);
    print(result);
} catch (e) {
    print('Exception when calling SubscriptionApi->pullSubscription: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 
 **sid** | **String**| The subscription id | 

### Return type

[**SubscriptionPullResp**](SubscriptionPullResp.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **pushSubscription**
> SubscriptionPushResp pushSubscription(uid, sid, subscriptionPushReq)

Push a subscription

Push a subscription

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubscriptionApi();
final uid = shopppon@gmail.com; // String | The user id
final sid = d290f1ee-6c54-4b01-90e6-d701748f0851; // String | The subscription id
final subscriptionPushReq = SubscriptionPushReq(); // SubscriptionPushReq | 

try {
    final result = api_instance.pushSubscription(uid, sid, subscriptionPushReq);
    print(result);
} catch (e) {
    print('Exception when calling SubscriptionApi->pushSubscription: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uid** | **String**| The user id | 
 **sid** | **String**| The subscription id | 
 **subscriptionPushReq** | [**SubscriptionPushReq**](SubscriptionPushReq.md)|  | [optional] 

### Return type

[**SubscriptionPushResp**](SubscriptionPushResp.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

