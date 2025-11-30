import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/category.dart';
import '../../../core/data/entry.dart';
import '../../auth/application/auth_controller.dart';
import '../application/home_controller.dart';
import '../application/home_state.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeState state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('fclipboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.load(),
            tooltip: '刷新列表',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出登录',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索标题或正文（桌面支持全局唤起，Web 提供页面快捷键）',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: controller.updateQuery,
              ),
            ),
            _CategoryBar(
              categories: state.categories,
              selectedId: state.selectedCategoryId,
              onSelect: controller.selectCategory,
              onCreate: (name) => controller.addCategory(name),
              creating: state.creatingCategory,
            ),
            if (state.loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView.separated(
                itemCount: state.entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = state.entries[index];
                  return ListTile(
                    selected: state.selectedEntryId == entry.id,
                    title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: -6,
                          children: entry.tags
                              .map((tag) => Chip(label: Text(tag), visualDensity: VisualDensity.compact))
                              .toList(),
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () => _handleCopy(context, controller, entry),
                        ),
                        IconButton(
                          icon: Icon(entry.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                          onPressed: () => controller.togglePin(entry),
                        ),
                      ],
                    ),
                    onTap: () {
                      controller.selectEntry(entry.id);
                      _handleCopy(context, controller, entry);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.creatingEntry
            ? null
            : () => _showAddEntryDialog(context, controller, state.selectedCategoryId, state.creatingEntry),
        icon: const Icon(Icons.add),
        label: const Text('新建条目'),
      ),
    );
  }

  Future<void> _handleCopy(BuildContext context, HomeController controller, Entry entry) async {
    controller.selectEntry(entry.id);
    if (entry.parameters.isEmpty) {
      await Clipboard.setData(ClipboardData(text: entry.body.isNotEmpty ? entry.body : entry.title));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
      }
      return;
    }

    final controllers = entry.parameters
        .map(
          (p) => _ParamControllers(
            initialName: p.name,
            initialDescription: p.description ?? '',
            initialValue: p.initial ?? '',
            isRequired: p.required,
          ),
        )
        .toList();

    await showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        bool submitting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('填写参数后复制'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...controllers.map(
                        (c) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: TextFormField(
                                controller: c.value,
                                decoration: InputDecoration(
                                  labelText: c.requiredField ? '* ${c.name.text}' : c.name.text,
                                  helperText: c.description.text.isNotEmpty ? c.description.text : null,
                                ),
                                validator: (v) {
                                  if (c.requiredField && (v == null || v.trim().isEmpty)) {
                                    return '必填';
                                  }
                                  return null;
                                },
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          setState(() => submitting = true);
                          var text = entry.body.isNotEmpty ? entry.body : entry.title;
                          for (final c in controllers) {
                            final val = c.value.text.trim();
                            if (val.isNotEmpty) {
                              text = text.replaceAll(c.name.text, val);
                            }
                          }
                          await Clipboard.setData(ClipboardData(text: text));
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
                          }
                        },
                  child: const Text('复制'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEntryDialog(
      BuildContext context, HomeController controller, String? categoryId, bool creatingEntry) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final paramControllers = <_ParamControllers>[];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建条目'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '正文'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('参数（可选）', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ...paramControllers.map(
                      (pc) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: pc.name,
                                decoration: const InputDecoration(labelText: '名称'),
                              ),
                              TextField(
                                controller: pc.description,
                                decoration: const InputDecoration(labelText: '描述'),
                              ),
                              TextField(
                                controller: pc.value,
                                decoration: const InputDecoration(labelText: '默认值'),
                              ),
                              CheckboxListTile(
                                value: pc.requiredField,
                                onChanged: (v) => setState(() => pc.requiredField = v ?? false),
                                title: const Text('必填'),
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() => paramControllers.remove(pc));
                                  },
                                  child: const Text('删除参数'),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          paramControllers.add(_ParamControllers.empty());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('添加参数'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: creatingEntry
                ? null
                : () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final params = paramControllers
                  .map(
                    (pc) => EntryParameter(
                      name: pc.name.text.trim(),
                      description: pc.description.text.trim().isEmpty ? null : pc.description.text.trim(),
                      initial: pc.value.text.trim().isEmpty ? null : pc.value.text.trim(),
                      required: pc.requiredField,
                    ),
                  )
                  .where((p) => p.name.isNotEmpty)
                  .toList();
              try {
                await controller.addEntry(
                  title: title,
                  body: bodyController.text.trim(),
                  categoryId: categoryId,
                  parameters: params,
                );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('保存失败: $e')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _ParamControllers {
  _ParamControllers({
    required String initialName,
    String initialDescription = '',
    String initialValue = '',
    bool isRequired = false,
  })  : name = TextEditingController(text: initialName),
        description = TextEditingController(text: initialDescription),
        value = TextEditingController(text: initialValue),
        requiredField = isRequired;

  factory _ParamControllers.empty() => _ParamControllers(initialName: '', initialDescription: '', initialValue: '');

  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController value;
  bool requiredField;
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onCreate,
    required this.creating,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final Future<void> Function(String) onCreate;
  final bool creating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: selectedId == null,
                    onSelected: (_) => onSelect(null),
                  ),
                  ...categories.map(
                    (c) => ChoiceChip(
                      label: Text(c.name),
                      selected: c.id == selectedId,
                      onSelected: (_) => onSelect(c.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: creating ? null : () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加分类'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建分类'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                try {
                  await onCreate(name);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('创建失败: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
