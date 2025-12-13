import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/tag.dart';
import '../../snippets/data/snippet_repository.dart';
import '../data/tag_repository.dart';

class _DeleteTagDecision {
  const _DeleteTagDecision({
    required this.confirmed,
    required this.deleteSnippets,
  });

  final bool confirmed;
  final bool deleteSnippets;
}

class TagManagementPage extends ConsumerStatefulWidget {
  const TagManagementPage({super.key});

  @override
  ConsumerState<TagManagementPage> createState() => _TagManagementPageState();
}

class _TagManagementPageState extends ConsumerState<TagManagementPage> {
  bool _loading = true;
  String? _error;
  List<Tag> _tags = [];
  Map<String?, int> _counts = {};
  String? _sharingTagId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tagsRepo = ref.read(tagRepositoryProvider);
      final tags = await tagsRepo.fetchTags();
      final dedupedTags = await tagsRepo.dedupeByName(tags);
      final counts = await ref.read(snippetRepositoryProvider).countByTag();
      setState(() {
        _tags = dedupedTags;
        _counts = counts;
      });
    } catch (e) {
      setState(() => _error = '加载失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(Tag tag) async {
    final nameController = TextEditingController(text: tag.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名标签'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context, name);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await ref
          .read(tagRepositoryProvider)
          .updateTag(tag: tag, name: result.trim(), color: tag.color);
      await _load();
    }
  }

  Future<void> _delete(Tag tag) async {
    final count = _counts[tag.id] ?? 0;
    final decision = await showDialog<_DeleteTagDecision>(
      context: context,
      builder: (context) {
        var deleteSnippets = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('删除标签'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('确定删除“${tag.name}”吗？'),
                if (count > 0) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: deleteSnippets,
                    onChanged: (value) =>
                        setState(() => deleteSnippets = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('同时删除该标签下的 $count 个片段'),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  const _DeleteTagDecision(
                    confirmed: false,
                    deleteSnippets: false,
                  ),
                ),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  _DeleteTagDecision(
                    confirmed: true,
                    deleteSnippets: deleteSnippets,
                  ),
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
    );
    if (decision == null || !decision.confirmed) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (decision.deleteSnippets) {
        await ref.read(snippetRepositoryProvider).deleteSnippetsByTagId(tag.id);
      }
      await ref.read(tagRepositoryProvider).deleteTag(tag.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('删除失败：$e')),
      );
    }
  }

  Future<void> _share(Tag tag) async {
    final emailController = TextEditingController();
    final tagNameController = TextEditingController(text: tag.name);
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分享标签内片段'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '将标签“${tag.name}”下的所有片段分享给指定邮箱用户。',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: '对方邮箱',
                  hintText: 'user@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return '请输入邮箱';
                  if (!email.contains('@')) return '邮箱格式不正确';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: tagNameController,
                decoration: const InputDecoration(
                  labelText: '分享时使用的标签名',
                  helperText: '默认为当前标签名称',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context, true);
            },
            child: const Text('分享'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final email = emailController.text.trim();
    final tagName = tagNameController.text.trim().isEmpty
        ? tag.name
        : tagNameController.text.trim();

    setState(() => _sharingTagId = tag.id);
    try {
      final token = await ref.read(snippetRepositoryProvider).shareTag(
            tagId: tag.id,
            email: email,
            tagName: tagName,
          );
      if (mounted) {
        await _showShareToken(token);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分享失败，请稍后重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingTagId = null);
    }
  }

  Future<void> _create() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建标签'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context, name);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await ref.read(tagRepositoryProvider).createTag(name: result.trim());
      await _load();
    }
  }

  Future<void> _showShareToken(String token) async {
    try {
      await Clipboard.setData(ClipboardData(text: token));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分享令牌已复制到剪贴板')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('自动复制失败，请手动复制令牌')),
        );
      }
    }
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('分享令牌已生成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请将令牌发送给接收人，对方在个人信息页粘贴确认后才会导入。'),
            const SizedBox(height: 8),
            const Text('令牌已自动复制到剪贴板。'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(token),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: token));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制令牌')),
              );
            },
            child: const Text('重新复制'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标签管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建标签',
            onPressed: _create,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                : _tags.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('暂无标签，点击右上角新增'),
                          ),
                        ],
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3.2,
                        ),
                        itemCount: _tags.length,
                        itemBuilder: (context, index) {
                          final tag = _tags[index];
                          final count = _counts[tag.id] ?? 0;
                          final sharing = _sharingTagId == tag.id;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(tag.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 6),
                                  Text('片段数：$count',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        tooltip: '重命名',
                                        onPressed: () => _edit(tag),
                                      ),
                                      IconButton(
                                        icon: sharing
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.share_outlined),
                                        tooltip: '分享标签内片段',
                                        onPressed:
                                            sharing ? null : () => _share(tag),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: '删除',
                                        onPressed: () => _delete(tag),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
