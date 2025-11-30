import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../../features/auth/application/auth_controller.dart';

class ApiClient {
  ApiClient(this.ref);

  final Ref ref;

  Future<http.Response> get(String path) => _send('GET', path);
  Future<http.Response> post(String path, {Object? body}) => _send('POST', path, body: body);
  Future<http.Response> put(String path, {Object? body}) => _send('PUT', path, body: body);
  Future<http.Response> delete(String path) => _send('DELETE', path);

  Future<http.Response> _send(String method, String path, {Object? body}) async {
    final token = ref.read(authControllerProvider).accessToken;
    final uri = Uri.parse('$kApiBaseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: body == null ? null : jsonEncode(body));
      case 'PUT':
        return http.put(uri, headers: headers, body: body == null ? null : jsonEncode(body));
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw UnsupportedError('Method $method not supported');
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));
