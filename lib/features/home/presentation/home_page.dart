import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

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
  late final ProviderSubscription<HomeState> _homeSub;
  final Map<String, GlobalKey> _itemKeys = {};
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _shortcutFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _homeSub = ref.listenManual<HomeState>(
      homeControllerProvider,
      (previous, next) {
        _syncKeys(next.snippets);
        final selectedId = next.selectedSnippetId;
        if (selectedId == null) {
          if (_selectedSnippet != null) {
            _setSelectedSnippet(null);
          }
          return;
        }
        final match = next.snippets.where((s) => s.id == selectedId);
        if (match.isEmpty) {
          if (_selectedSnippet != null) {
            _setSelectedSnippet(null);
          }
          return;
        }
        final snippet = match.first;
        if (_selectedSnippet?.id != snippet.id ||
            _selectedSnippet?.updatedAt != snippet.updatedAt ||
            _selectedSnippet?.parameters.length != snippet.parameters.length) {
          _setSelectedSnippet(snippet);
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _homeSub.close();
    _searchFocusNode.dispose();
    _shortcutFocusNode.dispose();
    _clearParamControllers();
    super.dispose();
  }

  void _clearParamControllers() {
    for (final c in _paramControllers) {
      c.dispose();
    }
    _paramControllers = [];
  }

  void _setSelectedSnippet(Snippet? snippet) {
    _clearParamControllers();
    setState(() {
      _selectedSnippet = snippet;
      if (snippet != null) {
        _paramControllers = snippet.parameters
            .map((p) => _ParamControllers(
                  initialName: p.name,
                  initialDescription: p.description ?? '',
                  initialValue: p.initial ?? '',
                  isRequired: p.required,
                ))
            .toList();
        if (_paramControllers.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _paramControllers.first.focusNode.requestFocus();
          });
        }
      }
    });
  }

  void _selectSnippet(HomeController controller, Snippet snippet) {
    controller.selectSnippet(snippet.id);
    _setSelectedSnippet(snippet);
  }

  void _selectSnippetAndCopyIfNoParams(
      HomeController controller, Snippet snippet) {
    _selectSnippet(controller, snippet);
    if (snippet.parameters.isEmpty) {
      _copySnippetWithoutParameters(context, snippet);
    }
  }

  Map<ShortcutActivator, VoidCallback> _shortcutBindings(
      HomeState state, HomeController controller) {
    final bindings = <ShortcutActivator, VoidCallback>{};
    final isMac = Theme.of(context).platform == TargetPlatform.macOS;
    final digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    for (var i = 0; i < state.snippets.length && i < digits.length; i++) {
      final key = digits[i];
      bindings[SingleActivator(key, meta: isMac, control: !isMac)] = () {
        final snippet = state.snippets[i];
        _selectSnippetAndCopyIfNoParams(controller, snippet);
        Scrollable.ensureVisible(
          _itemKeys[snippet.id]!.currentContext!,
          alignment: 0.2,
          duration: const Duration(milliseconds: 200),
        );
      };
    }
    bindings[const SingleActivator(LogicalKeyboardKey.enter, shift: true)] =
        () {
      _searchFocusNode.requestFocus();
    };
    return bindings;
  }

  void _syncKeys(List<Snippet> snippets) {
    final seen = <String>{};
    for (final s in snippets) {
      seen.add(s.id);
      _itemKeys.putIfAbsent(s.id, () => GlobalKey());
    }
    final stale = _itemKeys.keys.where((k) => !seen.contains(k)).toList();
    for (final k in stale) {
      _itemKeys.remove(k);
    }
  }

  @override
  Widget build(BuildContext context) {
    final HomeState state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    _syncKeys(state.snippets);

    return Scaffold(
      appBar: AppBar(
        title: const Text('第二大脑'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_outlined),
            tooltip: '新建片段',
            onPressed: () =>
                _openAddSnippetPage(context, controller, state.selectedTagId),
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
            onPressed: () => controller.load(withSync: true),
            tooltip: '同步',
          ),
          IconButton(
            icon: const Icon(Icons.sell_outlined),
            tooltip: '标签管理',
            onPressed: () => _openTagManagement(controller),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '个人信息',
            onPressed: () => context.pushNamed('profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: CallbackShortcuts(
          bindings: _shortcutBindings(state, controller),
          child: Focus(
            focusNode: _shortcutFocusNode,
            autofocus: true,
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
                        _SearchField(
                          onChanged: controller.updateQuery,
                          focusNode: _searchFocusNode,
                        ),
                        const SizedBox(height: 12),
                        _TagBar(
                          tags: state.tags,
                          selectedId: state.selectedTagId,
                          onSelect: controller.selectTag,
                          onCreate: (name) => controller.addTag(name),
                          creating: state.creatingTag,
                        ),
                        if (_selectedSnippet != null &&
                            _selectedSnippet!.parameters.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _InlineParameterForm(
                              controllers: _paramControllers,
                              onSubmitted: () => _handleCopy(
                                  context, controller, _selectedSnippet!),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (state.loading)
                    const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: state.snippets.length,
                      itemBuilder: (context, index) {
                        final snippet = state.snippets[index];
                        final selected = state.selectedSnippetId == snippet.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            key: _itemKeys[snippet.id],
                            color: selected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.06)
                                : null,
                            elevation: selected ? 6 : 2,
                            shadowColor:
                                selected ? Colors.black26 : Colors.black12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                _selectSnippetAndCopyIfNoParams(
                                    controller, snippet);
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
                                                  padding:
                                                      const EdgeInsets.only(
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                                ?.copyWith(
                                                    color: Colors.grey[700]),
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
                                                            VisualDensity
                                                                .compact,
                                                        padding:
                                                            const EdgeInsets
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
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.copy_outlined),
                                          tooltip: '复制',
                                          onPressed: () => _handleCopy(
                                              context, controller, snippet),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: '编辑',
                                          onPressed: () => _openEditSnippetPage(
                                              context, controller, snippet),
                                        ),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          tooltip: '删除',
                                          onPressed: () => _confirmDelete(
                                              context, controller, snippet),
                                        ),
                                        IconButton(
                                          icon: Icon(snippet.pinned
                                              ? Icons.push_pin
                                              : Icons.push_pin_outlined),
                                          tooltip:
                                              snippet.pinned ? '取消置顶' : '置顶',
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
        ),
      ),
    );
  }

  Future<void> _copySnippetWithoutParameters(
      BuildContext context, Snippet snippet) async {
    final text = snippet.body.isNotEmpty ? snippet.body : snippet.title;
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已复制')));
    }
  }

  Future<void> _handleCopy(
      BuildContext context, HomeController controller, Snippet snippet) async {
    if (_selectedSnippet?.id != snippet.id) {
      _selectSnippet(controller, snippet);
    }
    if (snippet.parameters.isEmpty) {
      await _copySnippetWithoutParameters(context, snippet);
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

  Future<void> _openAddSnippetPage(
    BuildContext context,
    HomeController controller,
    String? tagId,
  ) async {
    final created = await context.pushNamed('snippet_new', extra: tagId);
    if (created == true) {
      if (!mounted) return;
      await controller.load();
    }
  }

  Future<void> _openTagManagement(HomeController controller) async {
    await context.push('/tags');
    if (!mounted) return;
    await controller.load();
  }

  Future<void> _openEditSnippetPage(
    BuildContext context,
    HomeController controller,
    Snippet snippet,
  ) async {
    final updated = await context.pushNamed('snippet_edit',
        pathParameters: {'id': snippet.id}, extra: snippet);
    if (updated == true) {
      if (!mounted) return;
      await controller.load();
      controller.selectSnippet(snippet.id);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HomeController controller,
    Snippet snippet,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除片段'),
        content: Text('确定删除“${snippet.title}”吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.deleteSnippet(snippet);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已删除')));
      }
    }
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
        requiredField = isRequired,
        focusNode = FocusNode();

  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController value;
  bool requiredField;
  final FocusNode focusNode;

  void dispose() {
    name.dispose();
    description.dispose();
    value.dispose();
    focusNode.dispose();
  }
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
  const _SearchField({required this.onChanged, this.focusNode});

  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: false,
      focusNode: focusNode,
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
            LayoutBuilder(
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
                final fieldWidth = columns == 1
                    ? width
                    : (width - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: controllers
                      .map(
                        (c) => SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            controller: c.value,
                            focusNode: c.focusNode,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () {
                              final currentIndex = controllers.indexOf(c);
                              final nextIndex = currentIndex + 1;
                              if (nextIndex < controllers.length) {
                                controllers[nextIndex].focusNode.requestFocus();
                              } else {
                                FocusScope.of(context).unfocus();
                                onSubmitted();
                              }
                            },
                            decoration: InputDecoration(
                              labelText: c.requiredField
                                  ? '* ${c.name.text}'
                                  : c.name.text,
                              helperText: c.description.text.isNotEmpty
                                  ? c.description.text
                                  : null,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
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
