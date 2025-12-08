import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/hotkey/hotkey_service.dart';
import 'router.dart';

class FClipboardApp extends ConsumerStatefulWidget {
  const FClipboardApp({super.key});

  @override
  ConsumerState<FClipboardApp> createState() => _FClipboardAppState();
}

class _FClipboardAppState extends ConsumerState<FClipboardApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(hotkeyServiceProvider).init());
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: '第二大脑',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
