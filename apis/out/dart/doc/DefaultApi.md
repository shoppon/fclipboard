# openapi.api.DefaultApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createSubscription**](DefaultApi.md#createsubscription) | **POST** /v1/subscriptions | Create a subscription
[**listSubscriptions**](DefaultApi.md#listsubscriptions) | **GET** /v1/subscriptions | List subscriptions
[**pullSubscription**](DefaultApi.md#pullsubscription) | **GET** /v1/subscriptions/{sid}/pull | Pull a subscription
[**pushSubscription**](DefaultApi.md#pushsubscription) | **POST** /v1/subscriptions/{sid}/push | Push a subscription


# **createSubscription**
> SubscriptionPostResp createSubscription(subscriptionPostReq)

Create a subscription

Create a subscription

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();
final subscriptionPostReq = SubscriptionPostReq(); // SubscriptionPostReq | 

try {
    final result = api_instance.createSubscription(subscriptionPostReq);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->createSubscription: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
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
> List<Subscription> listSubscriptions()

List subscriptions

List subscriptions

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.listSubscriptions();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listSubscriptions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Subscription>**](Subscription.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **pullSubscription**
> SubscriptionPullResp pullSubscription(sid)

Pull a subscription

Pull a subscription

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();
final sid = d290f1ee-6c54-4b01-90e6-d701748f0851; // String | The subscription id

try {
    final result = api_instance.pullSubscription(sid);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->pullSubscription: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
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
> Subscription pushSubscription(sid, subscriptionPushReq)

Push a subscription

Push a subscription

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();
final sid = d290f1ee-6c54-4b01-90e6-d701748f0851; // String | The subscription id
final subscriptionPushReq = SubscriptionPushReq(); // SubscriptionPushReq | 

try {
    final result = api_instance.pushSubscription(sid, subscriptionPushReq);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->pushSubscription: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sid** | **String**| The subscription id | 
 **subscriptionPushReq** | [**SubscriptionPushReq**](SubscriptionPushReq.md)|  | [optional] 

### Return type

[**Subscription**](Subscription.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

