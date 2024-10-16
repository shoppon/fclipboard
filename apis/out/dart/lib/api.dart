//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/category_api.dart';
part 'api/entry_api.dart';
part 'api/log_api.dart';
part 'api/subscription_api.dart';

part 'model/category.dart';
part 'model/category_list_resp.dart';
part 'model/category_post_req.dart';
part 'model/category_post_req_category.dart';
part 'model/category_post_resp.dart';
part 'model/entry.dart';
part 'model/entry_body.dart';
part 'model/entry_get_resp.dart';
part 'model/entry_list_resp.dart';
part 'model/entry_patch_req.dart';
part 'model/entry_patch_resp.dart';
part 'model/entry_post_req.dart';
part 'model/entry_post_resp.dart';
part 'model/log.dart';
part 'model/log_post_req.dart';
part 'model/parameter.dart';
part 'model/subscription.dart';
part 'model/subscription_list_resp.dart';
part 'model/subscription_post_req.dart';
part 'model/subscription_post_req_subscription.dart';
part 'model/subscription_post_resp.dart';
part 'model/subscription_pull_resp.dart';
part 'model/subscription_push_req.dart';
part 'model/subscription_push_resp.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
