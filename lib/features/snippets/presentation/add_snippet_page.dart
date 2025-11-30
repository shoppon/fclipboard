import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/snippet.dart';
import '../../../core/data/tag.dart';
import '../../tags/data/tag_repository.dart';
import '../data/snippet_repository.dart';

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
  String? _selectedTagId;
  bool _saving = false;
  bool get _isEditing => widget.snippet != null;

  @override
  void initState() {
    super.initState();
    _selectedTagId = widget.initialTagId;
    final snippet = widget.snippet;
    if (snippet != null) {
      _titleController.text = snippet.title;
      _bodyController.text = snippet.body;
      _selectedTagId = snippet.tagId ?? widget.initialTagId;
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

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(_tagsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑片段' : '新建片段'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(context),
            child: const Text('完成'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '正文'),
            ),
            const SizedBox(height: 12),
            tagsAsync.when(
              data: (tags) {
                final selectedTagId = _selectedTagId ?? widget.initialTagId;
                final dropdownValue = tags.any((t) => t.id == selectedTagId)
                    ? selectedTagId
                    : null;
                return DropdownButtonFormField<String>(
                  value: dropdownValue,
                  hint: const Text('选择标签（可选）'),
                  items: tags
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.name),
                        ),
                      )
                      .toList(),
                  onChanged: (t) => setState(() => _selectedTagId = t),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('参数', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => setState(
                      () => _paramControllers.add(_ParamControllers.empty())),
                  icon: const Icon(Icons.add),
                  label: const Text('添加参数'),
                ),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  var columns = 1;
                  if (width >= 1200) {
                    columns = 4;
                  } else if (width >= 900) {
                    columns = 3;
                  } else if (width >= 640) {
                    columns = 2;
                  }
                  const spacing = 12.0;
                  final cardWidth = columns == 1
                      ? width
                      : (width - spacing * (columns - 1)) / columns;
                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children:
                          List.generate(_paramControllers.length, (index) {
                        final pc = _paramControllers[index];
                        return SizedBox(
                          width: cardWidth,
                          child: Card(
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
                                      onPressed: () => setState(() {
                                        _paramControllers
                                            .removeAt(index)
                                            .dispose();
                                      }),
                                      child: const Text('删除'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
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
    try {
      if (_isEditing && widget.snippet != null) {
        await ref.read(snippetRepositoryProvider).updateSnippet(
              snippet: widget.snippet!,
              title: title,
              body: _bodyController.text.trim(),
              tagId: _selectedTagId ??
                  widget.initialTagId ??
                  widget.snippet!.tagId,
              parameters: params,
            );
      } else {
        await ref.read(snippetRepositoryProvider).createSnippet(
              title: title,
              body: _bodyController.text.trim(),
              tagId: _selectedTagId ?? widget.initialTagId,
              parameters: params,
            );
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
