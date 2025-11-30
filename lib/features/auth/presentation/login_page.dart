import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final auth = ref.read(authControllerProvider.notifier);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isRegister ? '创建账户' : '登录',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: '邮箱'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: '密码'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: authState.loading
                      ? null
                      : () async {
                          setState(() => _error = null);
                          final email = _emailController.text.trim();
                          final pwd = _passwordController.text;
                          final ok = _isRegister
                              ? await auth.register(email, pwd)
                              : await auth.login(email, pwd);
                          if (!ok && mounted) {
                            setState(() => _error = '操作失败，请检查邮箱/密码或稍后重试');
                          } else if (ok && mounted) {
                            context.go('/');
                          }
                        },
                  child: Text(_isRegister ? '注册并登录' : '登录'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _isRegister = !_isRegister);
                  },
                  child: Text(_isRegister ? '已有账户？去登录' : '没有账户？注册'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
