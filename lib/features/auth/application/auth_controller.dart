import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../application/auth_state.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref) : super(AuthState.initial()) {
    _loadSession();
  }

  final Ref ref;
  static const _kAccessKey = 'auth.access';
  static const _kRefreshKey = 'auth.refresh';
  static const _kEmailKey = 'auth.email';
  static const _kUserIdKey = 'auth.userId';

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_kAccessKey);
    final refresh = prefs.getString(_kRefreshKey);
    final email = prefs.getString(_kEmailKey);
    final userId = prefs.getString(_kUserIdKey);
    state = state.copyWith(
      initialized: true,
      accessToken: access,
      refreshToken: refresh,
      email: email,
      userId: userId,
    );
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true);
    final uri = Uri.parse('$kApiBaseUrl/auth/login');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    if (res.statusCode != 200) {
      state = state.copyWith(loading: false);
      return false;
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    final userId = await _fetchUserId(access);
    await _persistSession(access, refresh, email, userId);
    state = state.copyWith(
      loading: false,
      accessToken: access,
      refreshToken: refresh,
      email: email,
      userId: userId,
    );
    return true;
  }

  Future<bool> register(String email, String password) async {
    state = state.copyWith(loading: true);
    final uri = Uri.parse('$kApiBaseUrl/auth/register');
    final res = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    if (res.statusCode != 201) {
      state = state.copyWith(loading: false);
      return false;
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    final userId = await _fetchUserId(access);
    await _persistSession(access, refresh, email, userId);
    state = state.copyWith(
      loading: false,
      accessToken: access,
      refreshToken: refresh,
      email: email,
      userId: userId,
    );
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessKey);
    await prefs.remove(_kRefreshKey);
    await prefs.remove(_kEmailKey);
    await prefs.remove(_kUserIdKey);
    state = AuthState.initial().copyWith(initialized: true);
  }

  Future<void> _persistSession(
      String? access, String? refresh, String? email, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (access != null) await prefs.setString(_kAccessKey, access);
    if (refresh != null) await prefs.setString(_kRefreshKey, refresh);
    if (email != null) await prefs.setString(_kEmailKey, email);
    if (userId != null) await prefs.setString(_kUserIdKey, userId);
    state = state.copyWith(
        accessToken: access,
        refreshToken: refresh,
        email: email,
        userId: userId);
  }

  Future<String?> _fetchUserId(String? access) async {
    if (access == null) return null;
    final uri = Uri.parse('$kApiBaseUrl/auth/me');
    final res =
        await http.get(uri, headers: {'Authorization': 'Bearer $access'});
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final id = data['id'] as String?;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) await prefs.setString(_kUserIdKey, id);
    return id;
  }
}
