import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../router.dart';
import 'search_focus_controller.dart';

class HotkeyService {
  HotkeyService(this.ref);

  final Ref ref;
  HotKey? _current;
  static const _prefKey = 'settings.global_hotkey';

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  static bool get isSupported => _supported;

  HotKey? get current => _current;

  Future<void> init() async {
    if (!_supported) return;
    await windowManager.ensureInitialized();
    final saved = await _loadSavedHotKey();
    if (saved != null) {
      await _register(saved);
    }
  }

  Future<void> updateHotKey(HotKey hotKey) async {
    if (!_supported) return;
    await windowManager.ensureInitialized();
    await _register(hotKey);
    await _persistHotKey(hotKey);
  }

  Future<void> _activateApp() async {
    if (!_supported) return;
    try {
      await windowManager.show();
      await windowManager.setSkipTaskbar(false);
      await windowManager.focus();
      await windowManager.focus();
    } catch (_) {}
    try {
      ref.read(appRouterProvider).go('/');
    } catch (_) {}
    ref.read(homeFocusControllerProvider).focusSearch();
  }

  Future<void> _register(HotKey hotKey) async {
    await hotKeyManager.unregisterAll();
    _current = hotKey;
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (_) => _activateApp(),
    );
  }

  Future<HotKey?> _loadSavedHotKey() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return HotKey.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistHotKey(HotKey hotKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(hotKey.toJson()));
  }

  Future<void> dispose() async {
    if (!_supported) return;
    await hotKeyManager.unregisterAll();
  }
}

final hotkeyServiceProvider = Provider<HotkeyService>((ref) {
  final service = HotkeyService(ref);
  ref.onDispose(service.dispose);
  return service;
});
