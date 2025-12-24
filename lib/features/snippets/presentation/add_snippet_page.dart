import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/snippet.dart';
import '../../../core/data/tag.dart';
import '../../../design/ui_tokens.dart';
import '../../tags/data/tag_repository.dart';
import '../data/snippet_repository.dart';

InputDecoration _formDecoration(
  String label, {
  String? hint,
  String? helper,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: UiTokens.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: UiTokens.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: UiTokens.primary, width: 1.4),
    ),
  );
}

class AddSnippetPage extends ConsumerStatefulWidget {
  const AddSnippetPage({super.key, this.initialTagId, this.snippet});

  final String? initialTagId;
  final Snippet? snippet;

  @override
  ConsumerState<AddSnippetPage> createState() => _AddSnippetPageState();
}

class _AddSnippetPageState extends ConsumerState<AddSnippetPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _paramControllers = <_ParamControllers>[];
  final _selectedTags = <_TagInput>[];
  final _pendingTagIds = <String>[];
  bool _tagIdsHydrated = false;
  bool _saving = false;
  bool get _isEditing => widget.snippet != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialTagId != null) {
      _pendingTagIds.add(widget.initialTagId!);
    }
    final snippet = widget.snippet;
    if (snippet != null) {
      _titleController.text = snippet.title;
      _bodyController.text = snippet.body;
      _pendingTagIds
        ..clear()
        ..addAll(snippet.tagIds.toSet());
      _paramControllers.addAll(
        snippet.parameters
            .map(
              (p) => _ParamControllers(
                initialName: p.name,
                initialDescription: p.description ?? '',
                initialValue: p.initial ?? '',
                isRequired: p.required,
              ),
            )
            .toList(),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    for (final controller in _paramControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _normalizeTagName(String value) => value.trim();

  static bool _sameTagName(String a, String b) =>
      _normalizeTagName(a).toLowerCase() == _normalizeTagName(b).toLowerCase();

  Tag? _findTagById(List<Tag> tags, String id) {
    for (final tag in tags) {
      if (tag.id == id) return tag;
    }
    return null;
  }

  Tag? _findTagByName(List<Tag> tags, String name) {
    for (final tag in tags) {
      if (_sameTagName(tag.name, name)) return tag;
    }
    return null;
  }

  void _hydrateTagIds(List<Tag> tags) {
    if (_tagIdsHydrated) return;
    _tagIdsHydrated = true;
    if (_pendingTagIds.isEmpty) return;
    final toAdd = <_TagInput>[];
    for (final id in _pendingTagIds) {
      final matched = _findTagById(tags, id);
      if (matched == null) continue;
      final exists = _selectedTags.any((tag) => tag.id == matched.id);
      if (exists) continue;
      toAdd.add(_TagInput(id: matched.id, name: matched.name));
    }
    if (toAdd.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selectedTags.addAll(toAdd));
    });
  }

  void _addTagInputs(Iterable<_TagInput> inputs) {
    final existingNames =
        _selectedTags.map((tag) => tag.name.toLowerCase()).toSet();
    final existingIds =
        _selectedTags.map((tag) => tag.id).whereType<String>().toSet();
    final toAdd = <_TagInput>[];
    for (final input in inputs) {
      final name = _normalizeTagName(input.name);
      if (name.isEmpty) continue;
      if (input.id != null && existingIds.contains(input.id)) continue;
      if (existingNames.contains(name.toLowerCase())) continue;
      toAdd.add(_TagInput(id: input.id, name: name));
    }
    if (toAdd.isEmpty) return;
    setState(() => _selectedTags.addAll(toAdd));
  }

  void _removeTag(_TagInput tag) {
    setState(() {
      _selectedTags.removeWhere((item) {
        if (tag.id != null) return item.id == tag.id;
        return _sameTagName(item.name, tag.name);
      });
    });
  }

  void _submitTagInput(
    List<Tag> tags,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    final raw = controller.text;
    if (raw.trim().isEmpty) {
      controller.clear();
      return;
    }
    final parts = raw.split(RegExp(r'[,\n，]+'));
    final inputs = parts.map(
      (part) {
        final normalized = _normalizeTagName(part);
        if (normalized.isEmpty) return null;
        final matched = _findTagByName(tags, normalized);
        return _TagInput(id: matched?.id, name: matched?.name ?? normalized);
      },
    ).whereType<_TagInput>();
    _addTagInputs(inputs);
    controller.clear();
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(_tagsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: UiTokens.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        toolbarHeight: 64,
        titleSpacing: 16,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('返回'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? '编辑片段' : '新建片段',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: UiTokens.textPrimary,
              ),
            ),
            Text(
              '清晰标题 + 精准标签，让检索更高效',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: UiTokens.textSecondary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.icon(
              onPressed: _saving ? null : () => _save(context),
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? '保存中' : '完成'),
              style: FilledButton.styleFrom(
                backgroundColor: UiTokens.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: '基本信息',
                    description: '标题清晰、正文用等宽字体书写命令，支持参数占位符。',
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: _formDecoration(
                            '标题',
                            hint: '例如：k8s 删除 namespace 中的 Pod',
                            helper: '建议 3-8 个词，突出动作和对象',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bodyController,
                          maxLines: 6,
                          decoration: _formDecoration(
                            '正文',
                            hint: '粘贴命令或文本，支持 {{param}} 变量占位',
                            helper: '复制时可自动替换参数；长文本会自动折行',
                          ),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: '标签',
                    description: '用于分组过滤，支持多个标签。',
                    child: tagsAsync.when(
                      data: (tags) {
                        _hydrateTagIds(tags);
                        TextEditingController? fieldController;
                        FocusNode? fieldFocusNode;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedTags.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: UiTokens.surface,
                                  borderRadius: UiTokens.cardRadius,
                                  border: Border.all(color: UiTokens.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.sell_outlined,
                                        color: UiTokens.textSecondary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '暂无标签。使用下方输入框添加多个标签。',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: UiTokens.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_selectedTags.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedTags
                                    .map(
                                      (tag) => InputChip(
                                        label: Text(tag.name),
                                        onDeleted: () => _removeTag(tag),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                        backgroundColor: UiTokens.subtle,
                                        labelStyle: const TextStyle(
                                          color: UiTokens.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        side: const BorderSide(
                                          color: UiTokens.border,
                                        ),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: UiTokens.chipRadius,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            const SizedBox(height: 10),
                            Autocomplete<Tag>(
                              displayStringForOption: (tag) => tag.name,
                              optionsBuilder: (value) {
                                final query = value.text.trim().toLowerCase();
                                final filtered = tags.where((tag) {
                                  final selected = _selectedTags.any((t) =>
                                      t.id == tag.id ||
                                      _sameTagName(t.name, tag.name));
                                  if (selected) return false;
                                  if (query.isEmpty) return true;
                                  return tag.name.toLowerCase().contains(query);
                                });
                                return filtered.take(8);
                              },
                              onSelected: (tag) {
                                _addTagInputs(
                                    [_TagInput(id: tag.id, name: tag.name)]);
                                fieldController?.clear();
                                fieldFocusNode?.requestFocus();
                              },
                              fieldViewBuilder: (
                                context,
                                textEditingController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                fieldController = textEditingController;
                                fieldFocusNode = focusNode;
                                return TextField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: _formDecoration(
                                    '添加标签',
                                    hint: '输入后回车添加，可多选',
                                    helper: '支持自动补全已有标签',
                                  ),
                                  onSubmitted: (_) => _submitTagInput(
                                    tags,
                                    textEditingController,
                                    focusNode,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: '参数',
                    description: '参数名需与正文中的占位符一致，支持默认值。',
                    trailing: TextButton.icon(
                      onPressed: () => setState(
                        () => _paramControllers.add(_ParamControllers.empty()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('添加参数'),
                    ),
                    child: _ParameterGrid(
                      controllers: _paramControllers,
                      onDelete: (index) => setState(() {
                        _paramControllers.removeAt(index).dispose();
                      }),
                      onToggleRequired: (index, value) => setState(
                        () => _paramControllers[index].requiredField = value,
                      ),
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

  Future<void> _save(BuildContext context) async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    final params = _paramControllers
        .map(
          (pc) => EntryParameter(
            name: pc.name.text.trim(),
            description: pc.description.text.trim().isEmpty
                ? null
                : pc.description.text.trim(),
            initial: pc.value.text.trim().isEmpty ? null : pc.value.text.trim(),
            required: pc.requiredField,
          ),
        )
        .where((p) => p.name.isNotEmpty)
        .toList();
    List<Tag> availableTags = const [];
    try {
      availableTags = await ref.read(_tagsProvider.future);
    } catch (_) {
      // ignore tag lookup failures; still save snippet content
    }
    final tagRepo = ref.read(tagRepositoryProvider);
    final resolvedTagIds = <String>[];
    for (final input in _selectedTags) {
      if (input.id != null) {
        resolvedTagIds.add(input.id!);
        continue;
      }
      final normalized = _normalizeTagName(input.name);
      if (normalized.isEmpty) continue;
      final existing = _findTagByName(availableTags, normalized);
      if (existing != null) {
        resolvedTagIds.add(existing.id);
        continue;
      }
      final created = await tagRepo.createTag(name: normalized);
      availableTags = [...availableTags, created];
      resolvedTagIds.add(created.id);
    }
    final uniqueTagIds = <String>[];
    final seen = <String>{};
    for (final id in resolvedTagIds) {
      if (seen.add(id)) uniqueTagIds.add(id);
    }
    try {
      if (_isEditing && widget.snippet != null) {
        await ref.read(snippetRepositoryProvider).updateSnippet(
              snippet: widget.snippet!,
              title: title,
              body: _bodyController.text.trim(),
              tagIds: uniqueTagIds,
              parameters: params,
            );
      } else {
        await ref.read(snippetRepositoryProvider).createSnippet(
              title: title,
              body: _bodyController.text.trim(),
              tagIds: uniqueTagIds,
              parameters: params,
            );
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.description,
    this.trailing,
  });

  final String title;
  final String? description;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: UiTokens.textPrimary,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: UiTokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ParameterGrid extends StatelessWidget {
  const _ParameterGrid({
    required this.controllers,
    required this.onDelete,
    required this.onToggleRequired,
  });

  final List<_ParamControllers> controllers;
  final void Function(int) onDelete;
  final void Function(int, bool) onToggleRequired;

  @override
  Widget build(BuildContext context) {
    if (controllers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: UiTokens.surface,
          borderRadius: UiTokens.cardRadius,
          border: Border.all(color: UiTokens.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.tips_and_updates_outlined,
                color: UiTokens.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '暂无参数。使用“添加参数”定义可替换的变量，如 {{cluster}}。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UiTokens.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var columns = 1;
        if (width >= 1200) {
          columns = 3;
        } else if (width >= 840) {
          columns = 2;
        }
        const spacing = 12.0;
        final cardWidth =
            columns == 1 ? width : (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(controllers.length, (index) {
            final pc = controllers[index];
            return SizedBox(
              width: cardWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: UiTokens.cardRadius,
                  border: Border.all(color: UiTokens.border),
                  boxShadow: UiTokens.softShadow,
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: pc.name,
                      decoration: _formDecoration(
                        '名称',
                        hint: '与正文占位符一致，如 {{cluster}}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pc.description,
                      decoration: _formDecoration(
                        '描述',
                        hint: '向使用者说明这个参数',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pc.value,
                      decoration: _formDecoration(
                        '默认值',
                        hint: '可选，填入默认替换内容',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Row(
                          children: [
                            Switch.adaptive(
                              value: pc.requiredField,
                              onChanged: (v) => onToggleRequired(index, v),
                              activeColor: UiTokens.primary,
                            ),
                            const Text('必填'),
                          ],
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => onDelete(index),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('删除'),
                          style: TextButton.styleFrom(
                            foregroundColor: UiTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

final _tagsProvider = FutureProvider<List<Tag>>((ref) async {
  final repo = ref.read(tagRepositoryProvider);
  final tags = await repo.fetchTags();
  return repo.dedupeByName(tags);
});

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

  void dispose() {
    name.dispose();
    description.dispose();
    value.dispose();
  }

  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController value;
  bool requiredField;
}

class _TagInput {
  const _TagInput({required this.name, this.id});

  final String name;
  final String? id;
}
