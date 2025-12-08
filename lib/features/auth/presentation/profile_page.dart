import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../../core/hotkey/hotkey_service.dart';
import '../../../design/ui_tokens.dart';
import '../../snippets/data/snippet_repository.dart';
import '../application/auth_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  HotKey? _hotKey;
  bool _recording = false;
  bool _saving = false;
  final _shareTokenController = TextEditingController();
  bool _acceptingShare = false;

  @override
  void initState() {
    super.initState();
    _hotKey = ref.read(hotkeyServiceProvider).current;
  }

  Future<void> _onHotKeyRecorded(HotKey hotKey) async {
    setState(() {
      _recording = false;
      _saving = true;
    });
    try {
      await ref.read(hotkeyServiceProvider).updateHotKey(hotKey);
      setState(() => _hotKey = hotKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('全局快捷键已更新')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置快捷键失败，请重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final email = auth.email ?? '未登录';
    final userId = auth.userId ?? '-';
    final hotkeySupported = HotkeyService.isSupported;

    return Scaffold(
      backgroundColor: UiTokens.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        titleSpacing: 16,
        title: const Text(
          '个人信息',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: UiTokens.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: UiTokens.cardRadius,
                      border: Border.all(color: UiTokens.border),
                      boxShadow: UiTokens.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  UiTokens.primary.withOpacity(0.12),
                              child: const Icon(Icons.person,
                                  color: UiTokens.primary),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: UiTokens.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '用户 ID: $userId',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: UiTokens.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: UiTokens.border),
                        const SizedBox(height: 12),
                        Text(
                          '账户',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: UiTokens.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(label: '邮箱', value: email),
                        _InfoRow(label: '用户 ID', value: userId),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () async {
                            await ref
                                .read(authControllerProvider.notifier)
                                .logout();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login', (route) => false);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: UiTokens.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            '退出登录',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: UiTokens.cardRadius,
                      border: Border.all(color: UiTokens.border),
                      boxShadow: UiTokens.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '全局快捷键',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: UiTokens.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '设置系统级快捷键，唤起应用到前台并聚焦搜索框（桌面端可用）。',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: UiTokens.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (_hotKey != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: UiTokens.surface,
                                  borderRadius: UiTokens.chipRadius,
                                  border: Border.all(color: UiTokens.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.flash_on,
                                        color: UiTokens.primary, size: 16),
                                    const SizedBox(width: 6),
                                    HotKeyVirtualView(hotKey: _hotKey!),
                                  ],
                                ),
                              )
                            else
                              Text(
                                '未设置',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: UiTokens.textSecondary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!hotkeySupported)
                          Text(
                            '当前平台暂不支持全局快捷键（仅 macOS / Windows / Linux 桌面端可用）。',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: UiTokens.textSecondary),
                          )
                        else ...[
                          Text(
                            _recording ? '按下新的快捷键组合...' : '点击“录制快捷键”并按下想要的组合键。',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: UiTokens.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              FilledButton.tonal(
                                onPressed: _saving
                                    ? null
                                    : () => setState(() {
                                          _recording = !_recording;
                                        }),
                                child: Text(_recording ? '取消录制' : '录制快捷键'),
                              ),
                              const SizedBox(width: 10),
                              if (_saving)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                          if (_recording) ...[
                            const SizedBox(height: 12),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: UiTokens.surface,
                                borderRadius: UiTokens.cardRadius,
                                border: Border.all(color: UiTokens.border),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: HotKeyRecorder(
                                  onHotKeyRecorded: _onHotKeyRecorded,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: UiTokens.cardRadius,
                      border: Border.all(color: UiTokens.border),
                      boxShadow: UiTokens.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '接收分享',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: UiTokens.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '粘贴分享令牌以导入对方向你发送的片段或标签内容。',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: UiTokens.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _shareTokenController,
                                decoration: const InputDecoration(
                                  labelText: '分享令牌',
                                  hintText: '粘贴收到的令牌',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: _acceptingShare
                                  ? null
                                  : () async {
                                      final token =
                                          _shareTokenController.text.trim();
                                      if (token.isEmpty) return;
                                      setState(() => _acceptingShare = true);
                                      try {
                                        final imported = await ref
                                            .read(snippetRepositoryProvider)
                                            .acceptShareToken(token);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      '已导入 $imported 项内容')));
                                        }
                                      } catch (_) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('导入失败，请检查令牌'),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(
                                              () => _acceptingShare = false);
                                        }
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: UiTokens.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: _acceptingShare
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('导入'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shareTokenController.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: UiTokens.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: UiTokens.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
