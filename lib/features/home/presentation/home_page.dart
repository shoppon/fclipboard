import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/snippet.dart';
import '../../../core/data/tag.dart';
import '../application/home_controller.dart';
import '../application/home_state.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Snippet? _selectedSnippet;
  List<_ParamControllers> _paramControllers = [];

  void _selectSnippet(HomeController controller, Snippet snippet) {
    controller.selectSnippet(snippet.id);
    setState(() {
      _selectedSnippet = snippet;
      _paramControllers = snippet.parameters
          .map((p) => _ParamControllers(
                initialName: p.name,
                initialDescription: p.description ?? '',
                initialValue: p.initial ?? '',
                isRequired: p.required,
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final HomeState state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('fclipboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_outlined),
            tooltip: '新建片段',
            onPressed: state.creatingSnippet
                ? null
                : () => _showAddSnippetSheet(context, controller,
                    state.selectedTagId, state.creatingSnippet),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '新建标签',
            onPressed: state.creatingTag
                ? null
                : () => _showAddTagDialog(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.load(),
            tooltip: '同步',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '个人信息',
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF1FF), Color(0xFFF8FAFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '库',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                    ),
                    const SizedBox(height: 12),
                    _SearchField(onChanged: controller.updateQuery),
                    const SizedBox(height: 12),
                    _TagBar(
                      tags: state.tags,
                      selectedId: state.selectedTagId,
                      onSelect: controller.selectTag,
                      onCreate: (name) => controller.addTag(name),
                      creating: state.creatingTag,
                    ),
                    if (_selectedSnippet != null && _selectedSnippet!.parameters.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _InlineParameterForm(
                          controllers: _paramControllers,
                          onSubmitted: () => _handleCopy(context, controller, _selectedSnippet!),
                        ),
                      ),
                  ],
                ),
              ),
              if (state.loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.snippets.length,
                  itemBuilder: (context, index) {
                    final snippet = state.snippets[index];
                    final selected = state.selectedSnippetId == snippet.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: selected ? 4 : 2,
                        shadowColor: selected ? Colors.black26 : Colors.black12,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            _selectSnippet(controller, snippet);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (snippet.pinned)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 6),
                                              child: Icon(Icons.push_pin,
                                                  size: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary),
                                            ),
                                          Expanded(
                                            child: Text(
                                              snippet.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        snippet.body,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey[700]),
                                      ),
                                      const SizedBox(height: 8),
                                      if (snippet.tags.isNotEmpty)
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: -6,
                                          children: snippet.tags
                                              .map((tag) => Chip(
                                                    label: Text(tag),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 0),
                                                  ))
                                              .toList(),
                                        ),
                                      if (snippet.parameters.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.tune,
                                                  size: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary),
                                              const SizedBox(width: 4),
                                              Text('需要参数',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.copy_outlined),
                                      tooltip: '复制',
                                      onPressed: () => _handleCopy(
                                          context, controller, snippet),
                                    ),
                                    IconButton(
                                      icon: Icon(snippet.pinned
                                          ? Icons.push_pin
                                          : Icons.push_pin_outlined),
                                      tooltip: snippet.pinned ? '取消置顶' : '置顶',
                                      onPressed: () =>
                                          controller.togglePin(snippet),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCopy(
      BuildContext context, HomeController controller, Snippet snippet) async {
    _selectSnippet(controller, snippet);
    if (snippet.parameters.isEmpty) {
      await Clipboard.setData(ClipboardData(
          text: snippet.body.isNotEmpty ? snippet.body : snippet.title));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已复制')));
      }
      return;
    }

    // Validate parameters inline
    for (final pc in _paramControllers) {
      if (pc.requiredField && pc.value.text.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请填写必填参数后再复制')),
          );
        }
        return;
      }
    }
    var text = snippet.body.isNotEmpty ? snippet.body : snippet.title;
    for (final c in _paramControllers) {
      final val = c.value.text.trim();
      if (val.isNotEmpty) {
        text = text.replaceAll(c.name.text, val);
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已复制')));
    }
  }

  void _showAddSnippetSheet(BuildContext context, HomeController controller,
      String? tagId, bool creatingSnippet) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final paramControllers = <_ParamControllers>[];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Text('新建片段',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('参数（可选）',
                          style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: () {
                          setState(() =>
                              paramControllers.add(_ParamControllers.empty()));
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('添加参数'),
                      ),
                    ],
                  ),
                  ...paramControllers.map(
                    (pc) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextField(
                              controller: pc.name,
                              decoration:
                                  const InputDecoration(labelText: '名称'),
                            ),
                            TextField(
                              controller: pc.description,
                              decoration:
                                  const InputDecoration(labelText: '描述'),
                            ),
                            TextField(
                              controller: pc.value,
                              decoration:
                                  const InputDecoration(labelText: '默认值'),
                            ),
                            SwitchListTile(
                              value: pc.requiredField,
                              onChanged: (v) =>
                                  setState(() => pc.requiredField = v),
                              title: const Text('必填'),
                              contentPadding: EdgeInsets.zero,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => paramControllers.remove(pc)),
                                child: const Text('删除参数'),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: creatingSnippet
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                if (title.isEmpty) return;
                                final params = paramControllers
                                    .map(
                                      (pc) => EntryParameter(
                                        name: pc.name.text.trim(),
                                        description:
                                            pc.description.text.trim().isEmpty
                                                ? null
                                                : pc.description.text.trim(),
                                        initial: pc.value.text.trim().isEmpty
                                            ? null
                                            : pc.value.text.trim(),
                                        required: pc.requiredField,
                                      ),
                                    )
                                    .where((p) => p.name.isNotEmpty)
                                    .toList();
                                try {
                                  await controller.addSnippet(
                                    title: title,
                                    body: bodyController.text.trim(),
                                    tagId: tagId,
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
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddTagDialog(
      BuildContext context, HomeController controller) async {
    final nameController = TextEditingController();
    await showDialog(
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
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              await controller.addTag(name);
              if (context.mounted) Navigator.pop(context);
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

  factory _ParamControllers.empty() => _ParamControllers(
      initialName: '', initialDescription: '', initialValue: '');

  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController value;
  bool requiredField;
}

class _TagBar extends StatelessWidget {
  const _TagBar({
    required this.tags,
    required this.selectedId,
    required this.onSelect,
    required this.onCreate,
    required this.creating,
  });

  final List<Tag> tags;
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
                  ...tags
                      .map(
                        (c) => ChoiceChip(
                          label: Text(c.name),
                          selected: c.id == selectedId,
                          onSelected: (_) => onSelect(c.id),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: creating ? null : () => _showAddTagDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('添加标签'),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: false,
      decoration: InputDecoration(
        hintText: '搜索标题或正文',
        prefixIcon: const Icon(Icons.search),
        filled: true,
      ),
      onChanged: onChanged,
    );
  }
}

class _InlineParameterForm extends StatelessWidget {
  const _InlineParameterForm({
    required this.controllers,
    required this.onSubmitted,
  });

  final List<_ParamControllers> controllers;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('填写参数后复制', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...controllers.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: c.value,
                  decoration: InputDecoration(
                    labelText: c.requiredField ? '* ${c.name.text}' : c.name.text,
                    helperText: c.description.text.isNotEmpty ? c.description.text : null,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onSubmitted,
                child: const Text('填完复制'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
