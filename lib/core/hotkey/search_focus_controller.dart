import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeFocusController {
  VoidCallback? _focusSearch;

  void registerSearchHandler(VoidCallback cb) {
    _focusSearch = cb;
  }

  void clear() {
    _focusSearch = null;
  }

  void focusSearch() {
    _focusSearch?.call();
  }
}

final homeFocusControllerProvider = Provider<HomeFocusController>((ref) {
  final controller = HomeFocusController();
  ref.onDispose(controller.clear);
  return controller;
});
