import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/snippet.dart';
import '../../../core/data/tag.dart';
import '../../tags/data/tag_repository.dart';
import '../data/snippet_repository.dart';

class AddSnippetPage extends ConsumerStatefulWidget {
  const AddSnippetPage({super.key});

  @override
  ConsumerState<AddSnippetPage> createState() => _AddSnippetPageState();
}

class _AddSnippetPageState extends ConsumerState<AddSnippetPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _paramControllers = <_ParamControllers>[];
  Tag? _selectedTag;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(_tagsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建条目'),
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
              data: (tags) => DropdownButtonFormField<Tag>(
                value: _selectedTag,
                hint: const Text('选择标签（可选）'),
                items: tags
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name),
                      ),
                    )
                    .toList(),
                onChanged: (t) => setState(() => _selectedTag = t),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('参数', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => setState(() => _paramControllers.add(_ParamControllers.empty())),
                  icon: const Icon(Icons.add),
                  label: const Text('添加参数'),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _paramControllers.length,
                itemBuilder: (context, index) {
                  final pc = _paramControllers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
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
                          SwitchListTile(
                            value: pc.requiredField,
                            onChanged: (v) => setState(() => pc.requiredField = v),
                            title: const Text('必填'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => setState(() => _paramControllers.removeAt(index)),
                              child: const Text('删除'),
                            ),
                          ),
                        ],
                      ),
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
            description: pc.description.text.trim().isEmpty ? null : pc.description.text.trim(),
            initial: pc.value.text.trim().isEmpty ? null : pc.value.text.trim(),
            required: pc.requiredField,
          ),
        )
        .where((p) => p.name.isNotEmpty)
        .toList();
    try {
      await ref.read(snippetRepositoryProvider).createSnippet(
            title: title,
            body: _bodyController.text.trim(),
            tagId: _selectedTag?.id,
            parameters: params,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

final _tagsProvider = FutureProvider<List<Tag>>((ref) async {
  return ref.read(tagRepositoryProvider).fetchTags();
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

  factory _ParamControllers.empty() => _ParamControllers(initialName: '', initialDescription: '', initialValue: '');

  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController value;
  bool requiredField;
}
