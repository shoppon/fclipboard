import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/snippet.dart';
import '../../../core/data/tag.dart';
import '../../../core/sync/sync_service.dart';
import '../../snippets/data/snippet_repository.dart';
import '../../tags/data/tag_repository.dart';
import 'home_state.dart';

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  final snippetsRepo = ref.watch(snippetRepositoryProvider);
  final tagsRepo = ref.watch(tagRepositoryProvider);
  return HomeController(ref, snippetsRepo, tagsRepo);
});

class HomeController extends StateNotifier<HomeState> {
  HomeController(this.ref, this._snippets, this._tags)
      : super(HomeState.initial()) {
    load();
  }

  final Ref ref;
  final SnippetRepository _snippets;
  final TagRepository _tags;

  Future<void> load({bool withSync = false}) async {
    state = state.copyWith(loading: true);
    try {
      if (withSync) {
        await ref.read(syncServiceProvider).sync();
      }
      await _refreshState();
    } catch (_) {
      // silent fail; auth guard will redirect on logout if unauthorized
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> downloadAll() async {
    if (state.loading) return;
    state = state.copyWith(loading: true, selectedSnippetId: null);
    try {
      await ref.read(syncServiceProvider).downloadAll();
      await _refreshState();
    } catch (_) {
      // silent fail to keep UI responsive
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> updateQuery(String query) async {
    state = state.copyWith(
      query: query,
      loading: true,
      selectedSnippetId: null,
    );
    try {
      final results = await _snippets.fetchSnippets(tagId: state.selectedTagId);
      final filtered = _filterSnippets(results, query, state.tags);
      state = state.copyWith(snippets: filtered);
    } catch (_) {
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> _refreshState() async {
    final tags = await _tags.fetchTags();
    final dedupedTags = await _tags.dedupeByName(tags);
    final results = await _snippets.fetchSnippets(tagId: state.selectedTagId);
    await _snippets.dedupeByTitle(results);
    final filtered = _filterSnippets(results, state.query, dedupedTags);
    final selectedSnippetExists =
        filtered.any((e) => e.id == state.selectedSnippetId);
    final selectedTagExists =
        dedupedTags.any((t) => t.id == state.selectedTagId);
    state = state.copyWith(
      snippets: filtered,
      tags: dedupedTags,
      selectedSnippetId: selectedSnippetExists ? state.selectedSnippetId : null,
      selectedTagId: selectedTagExists ? state.selectedTagId : null,
    );
  }

  Future<void> selectTag(String? tagId) async {
    state = state.copyWith(
      selectedTagId: tagId,
      loading: true,
      selectedSnippetId: null,
    );
    try {
      final results = await _snippets.fetchSnippets(tagId: tagId);
      final filtered = _filterSnippets(results, state.query, state.tags);
      state = state.copyWith(snippets: filtered);
    } catch (_) {
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> togglePin(Snippet snippet) async {
    final updated = await _snippets.togglePin(snippet);
    final snippets = List<Snippet>.from(state.snippets);
    final idx = snippets.indexWhere((e) => e.id == snippet.id);
    if (idx == -1) {
      snippets.add(updated);
    } else {
      snippets[idx] = updated;
    }
    state = state.copyWith(
        snippets: snippets..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
  }

  void selectSnippet(String? snippetId) {
    state = state.copyWith(selectedSnippetId: snippetId);
  }

  Future<void> deleteSnippet(Snippet snippet) async {
    if (state.loading) return;
    state = state.copyWith(
      selectedSnippetId: state.selectedSnippetId == snippet.id
          ? null
          : state.selectedSnippetId,
    );
    await _snippets.deleteSnippet(snippet);
    await load();
  }

  Future<void> addTag(String name, {String? color}) async {
    if (state.creatingTag) return;
    state = state.copyWith(creatingTag: true);
    try {
      await _tags.createTag(name: name, color: color);
      await load();
    } finally {
      state = state.copyWith(creatingTag: false);
    }
  }

  Future<void> deleteTag(String id) async {
    if (state.creatingTag) return;
    state = state.copyWith(creatingTag: true);
    try {
      await _tags.deleteTag(id);
      final selected = state.selectedTagId == id ? null : state.selectedTagId;
      state = state.copyWith(selectedTagId: selected);
      await load();
    } finally {
      state = state.copyWith(creatingTag: false);
    }
  }

  Future<void> addSnippet({
    required String title,
    required String body,
    List<String> tagIds = const [],
    List<EntryParameter> parameters = const [],
  }) async {
    if (state.creatingSnippet) return;
    state = state.copyWith(creatingSnippet: true);
    try {
      await _snippets.createSnippet(
        title: title,
        body: body,
        tagIds: tagIds,
        parameters: parameters,
      );
      await load();
    } finally {
      state = state.copyWith(creatingSnippet: false);
    }
  }

  List<Snippet> _filterSnippets(
    List<Snippet> items,
    String query,
    List<Tag> tags,
  ) {
    if (query.trim().isEmpty) return items;
    final needle = query.toLowerCase();
    final tagNameById = {
      for (final tag in tags) tag.id: tag.name.toLowerCase()
    };
    return items.where((snippet) {
      if (snippet.title.toLowerCase().contains(needle)) return true;
      if (snippet.body.toLowerCase().contains(needle)) return true;
      for (final tagId in snippet.tagIds) {
        final name = tagNameById[tagId];
        if (name != null && name.contains(needle)) return true;
      }
      return false;
    }).toList();
  }

  Future<String> shareSnippet({
    required Snippet snippet,
    required String email,
    String? tagId,
    String? tagName,
  }) async {
    return _snippets.shareSnippet(
      snippet: snippet,
      email: email,
      tagId: tagId,
      tagName: tagName,
    );
  }
}
