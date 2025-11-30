import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/snippet.dart';
import '../../../core/data/tag.dart';
import '../../../design/ui_tokens.dart';
import '../application/home_controller.dart';
import '../application/home_state.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const double _contentMaxWidth = 1120;
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

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: UiTokens.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        toolbarHeight: 66,
        titleSpacing: 16,
        title: Row(
          children: [
            const Text(
              '第二大脑',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: UiTokens.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: UiTokens.subtle,
                borderRadius: UiTokens.chipRadius,
              ),
              child: Text(
                '高效检索 · 快速粘贴',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: UiTokens.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: UiTokens.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('新建片段'),
              onPressed: () =>
                  _openAddSnippetPage(context, controller, state.selectedTagId),
            ),
          ),
          _AppBarIcon(
            icon: Icons.refresh,
            tooltip: '同步',
            onPressed: () => controller.load(withSync: true),
          ),
          _MoreMenu(
            onNewTag: state.creatingTag
                ? null
                : () => _showAddTagDialog(context, controller),
            onManageTags: () => _openTagManagement(controller),
            onProfile: () => context.pushNamed('profile'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: CallbackShortcuts(
          bindings: _shortcutBindings(state, controller),
          child: Focus(
            focusNode: _shortcutFocusNode,
            autofocus: true,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _contentMaxWidth),
                      child: _HeaderPanel(
                        searchFocusNode: _searchFocusNode,
                        onQueryChanged: controller.updateQuery,
                        tags: state.tags,
                        selectedTagId: state.selectedTagId,
                        onSelectTag: controller.selectTag,
                        paramControllers: _selectedSnippet != null
                            ? _paramControllers
                            : const [],
                        showParams:
                            _selectedSnippet?.parameters.isNotEmpty ?? false,
                        creatingTags: state.creatingTag,
                        onSubmitParams: _selectedSnippet == null
                            ? null
                            : () => _handleCopy(
                                  context,
                                  controller,
                                  _selectedSnippet!,
                                ),
                        snippetTitle: _selectedSnippet?.title,
                      ),
                    ),
                  ),
                ),
                if (state.loading) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _contentMaxWidth),
                      child: state.snippets.isEmpty
                          ? _EmptyState(
                              onCreate: () => _openAddSnippetPage(
                                  context, controller, state.selectedTagId),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                              itemCount: state.snippets.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final snippet = state.snippets[index];
                                final selected =
                                    state.selectedSnippetId == snippet.id;
                                return _SnippetCard(
                                  key: _itemKeys[snippet.id],
                                  snippet: snippet,
                                  selected: selected,
                                  onTap: () => _selectSnippetAndCopyIfNoParams(
                                      controller, snippet),
                                  onCopy: () =>
                                      _handleCopy(context, controller, snippet),
                                  onEdit: () => _openEditSnippetPage(
                                      context, controller, snippet),
                                  onDelete: () => _confirmDelete(
                                      context, controller, snippet),
                                  onPin: () => controller.togglePin(snippet),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? UiTokens.primary : UiTokens.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 6),
      child: ChoiceChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: UiTokens.primary.withOpacity(0.12),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? UiTokens.primary.withOpacity(0.4) : UiTokens.border,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: UiTokens.chipRadius,
        ),
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}

class _SnippetCard extends StatefulWidget {
  const _SnippetCard({
    super.key,
    required this.snippet,
    required this.selected,
    required this.onTap,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
  });

  final Snippet snippet;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  @override
  State<_SnippetCard> createState() => _SnippetCardState();
}

class _SnippetCardState extends State<_SnippetCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = DateFormat('MM-dd HH:mm').format(widget.snippet.updatedAt);
    final pinLabel = widget.snippet.pinned ? '取消置顶' : '置顶';
    final maxLines = _expanded ? 12 : 3;
    final canExpand = widget.snippet.body.trim().length > 140;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: UiTokens.cardRadius,
        border: Border.all(
          color: widget.selected
              ? UiTokens.primary.withOpacity(0.45)
              : UiTokens.border,
        ),
        boxShadow: widget.selected ? UiTokens.hoverShadow : UiTokens.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: UiTokens.cardRadius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: UiTokens.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (widget.snippet.pinned)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.push_pin,
                                    size: 18,
                                    color: UiTokens.primary,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  widget.snippet.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: UiTokens.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: UiTokens.codeBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: UiTokens.codeBorder),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              widget.snippet.body,
                              maxLines: maxLines,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: UiTokens.textSecondary,
                                height: 1.35,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          if (canExpand && !_expanded)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => setState(() {
                                  _expanded = true;
                                }),
                                icon: const Icon(
                                  Icons.expand_more,
                                  size: 16,
                                ),
                                label: const Text('展开全部'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  foregroundColor: UiTokens.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _PrimaryActionButton(
                          label: '复制',
                          icon: Icons.copy_outlined,
                          onTap: widget.onCopy,
                        ),
                        const SizedBox(height: 8),
                        _SnippetMenuButton(
                          pinned: widget.snippet.pinned,
                          pinLabel: pinLabel,
                          onEdit: widget.onEdit,
                          onDelete: widget.onDelete,
                          onPin: widget.onPin,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.snippet.tags.isNotEmpty)
                      ...widget.snippet.tags.map(
                        (tag) => _InfoBadge(
                          label: tag,
                          icon: Icons.sell_outlined,
                          background: UiTokens.subtle,
                          foreground: UiTokens.textSecondary,
                        ),
                      ),
                    if (widget.snippet.parameters.isNotEmpty)
                      const _InfoBadge(
                        label: '需要参数',
                        icon: Icons.tune,
                        background: Color(0xFFEFF6FF),
                        foreground: UiTokens.primary,
                      ),
                    _InfoBadge(
                      label: dateText,
                      icon: Icons.schedule,
                      background: UiTokens.surface,
                      foreground: UiTokens.textSecondary,
                    ),
                    if (widget.snippet.source != null &&
                        widget.snippet.source!.isNotEmpty)
                      _InfoBadge(
                        label: widget.snippet.source!,
                        icon: Icons.work_outline,
                        background: UiTokens.surface,
                        foreground: UiTokens.textSecondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: UiTokens.subtle,
        foregroundColor: UiTokens.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: UiTokens.border),
        ),
        elevation: 0,
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

enum _SnippetMenu { edit, delete, pin, unpin }

class _SnippetMenuButton extends StatelessWidget {
  const _SnippetMenuButton({
    required this.pinned,
    required this.pinLabel,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
  });

  final bool pinned;
  final String pinLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UiTokens.border),
        color: Colors.white,
      ),
      child: PopupMenuButton<_SnippetMenu>(
        tooltip: '更多操作',
        onSelected: (action) {
          switch (action) {
            case _SnippetMenu.edit:
              onEdit();
              break;
            case _SnippetMenu.delete:
              onDelete();
              break;
            case _SnippetMenu.pin:
            case _SnippetMenu.unpin:
              onPin();
              break;
          }
        },
        position: PopupMenuPosition.under,
        itemBuilder: (context) => [
          _menuItem(
            icon: Icons.edit_outlined,
            label: '编辑',
            value: _SnippetMenu.edit,
          ),
          _menuItem(
            icon: pinned ? Icons.push_pin : Icons.push_pin_outlined,
            label: pinLabel,
            value: pinned ? _SnippetMenu.unpin : _SnippetMenu.pin,
          ),
          _menuItem(
            icon: Icons.delete_outline,
            label: '删除',
            value: _SnippetMenu.delete,
          ),
        ],
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Icon(Icons.more_horiz, color: UiTokens.textSecondary),
        ),
      ),
    );
  }

  PopupMenuItem<_SnippetMenu> _menuItem({
    required IconData icon,
    required String label,
    required _SnippetMenu value,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: UiTokens.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: UiTokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.icon,
    this.background = UiTokens.surface,
    this.foreground = UiTokens.textSecondary,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: UiTokens.chipRadius,
        border: Border.all(color: UiTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum _OverflowAction { newTag, manageTags, profile }

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.onNewTag,
    required this.onManageTags,
    required this.onProfile,
  });

  final VoidCallback? onNewTag;
  final VoidCallback onManageTags;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: UiTokens.border),
        ),
        child: PopupMenuButton<_OverflowAction>(
          tooltip: '更多',
          onSelected: (action) {
            switch (action) {
              case _OverflowAction.newTag:
                onNewTag?.call();
                break;
              case _OverflowAction.manageTags:
                onManageTags();
                break;
              case _OverflowAction.profile:
                onProfile();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _OverflowAction.newTag,
              enabled: onNewTag != null,
              child: Row(
                children: const [
                  Icon(Icons.folder_open, size: 18),
                  SizedBox(width: 8),
                  Text('新建标签'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _OverflowAction.manageTags,
              child: Row(
                children: const [
                  Icon(Icons.sell_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('标签管理'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _OverflowAction.profile,
              child: Row(
                children: const [
                  Icon(Icons.person, size: 18),
                  SizedBox(width: 8),
                  Text('个人信息'),
                ],
              ),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Icon(Icons.more_vert, color: UiTokens.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _AppBarIcon extends StatelessWidget {
  const _AppBarIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: UiTokens.textSecondary,
          padding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: UiTokens.border),
          ),
          hoverColor: UiTokens.subtle,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: UiTokens.cardRadius,
          border: Border.all(color: UiTokens.border),
          boxShadow: UiTokens.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books_outlined,
                size: 48, color: UiTokens.primary),
            const SizedBox(height: 12),
            Text(
              '暂无片段',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: UiTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '创建你的第一个快捷片段，或调整搜索/标签过滤。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: UiTokens.textSecondary,
              ),
            ),
            if (onCreate != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onCreate,
                child: const Text('新建片段'),
              ),
            ],
          ],
        ),
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

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({
    required this.searchFocusNode,
    required this.onQueryChanged,
    required this.tags,
    required this.selectedTagId,
    required this.onSelectTag,
    required this.paramControllers,
    required this.showParams,
    required this.snippetTitle,
    this.onSubmitParams,
    this.creatingTags = false,
  });

  final FocusNode searchFocusNode;
  final ValueChanged<String> onQueryChanged;
  final List<Tag> tags;
  final String? selectedTagId;
  final ValueChanged<String?> onSelectTag;
  final List<_ParamControllers> paramControllers;
  final bool showParams;
  final VoidCallback? onSubmitParams;
  final String? snippetTitle;
  final bool creatingTags;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: UiTokens.cardRadius,
            border: Border.all(color: UiTokens.border),
            boxShadow: UiTokens.softShadow,
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            children: [
              _SearchField(
                onChanged: onQueryChanged,
                focusNode: searchFocusNode,
              ),
              const SizedBox(height: 12),
              _TagBar(
                tags: tags,
                selectedId: selectedTagId,
                onSelect: onSelectTag,
                creating: creatingTags,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: showParams
              ? _InlineParameterForm(
                  key: ValueKey(snippetTitle ?? 'params'),
                  controllers: paramControllers,
                  onSubmitted: onSubmitParams ?? () {},
                  title: snippetTitle == null ? '填写参数' : '为“$snippetTitle”填写参数',
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TagBar extends StatelessWidget {
  const _TagBar({
    required this.tags,
    required this.selectedId,
    required this.onSelect,
    required this.creating,
  });

  final List<Tag> tags;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final bool creating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '标签筛选',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: UiTokens.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            if (creating)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: '全部',
                selected: selectedId == null,
                onTap: () => onSelect(null),
              ),
              ...tags.map(
                (c) => _FilterChip(
                  label: c.name,
                  selected: c.id == selectedId,
                  onTap: () => onSelect(c.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged, this.focusNode});

  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      autofocus: false,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: '搜索标题、标签或正文',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: UiTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: UiTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: UiTokens.primary, width: 1.4),
        ),
      ),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: UiTokens.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      onChanged: onChanged,
    );
  }
}

class _InlineParameterForm extends StatelessWidget {
  const _InlineParameterForm({
    super.key,
    required this.controllers,
    required this.onSubmitted,
    required this.title,
  });

  final List<_ParamControllers> controllers;
  final VoidCallback onSubmitted;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: UiTokens.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: UiTokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                                : '按回车一键复制',
                            filled: true,
                            fillColor: UiTokens.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: UiTokens.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: UiTokens.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: UiTokens.primary, width: 1.4),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
