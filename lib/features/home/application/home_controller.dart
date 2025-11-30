import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/entry.dart';
import '../../../core/sync/sync_service.dart';
import '../../categories/data/category_repository.dart';
import '../../entries/data/entry_repository.dart';
import 'home_state.dart';

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>((ref) {
  final entriesRepo = ref.watch(entryRepositoryProvider);
  final categoriesRepo = ref.watch(categoryRepositoryProvider);
  return HomeController(ref, entriesRepo, categoriesRepo);
});

class HomeController extends StateNotifier<HomeState> {
  HomeController(this.ref, this._entries, this._categories) : super(HomeState.initial()) {
    load();
  }

  final Ref ref;
  final EntryRepository _entries;
  final CategoryRepository _categories;

  Future<void> load() async {
    state = state.copyWith(loading: true);
    await ref.read(syncServiceProvider).sync();
    final categories = await _categories.fetchCategories();
    final results = await _entries.fetchEntries(
      query: state.query,
      categoryId: state.selectedCategoryId,
    );
    state = state.copyWith(entries: results, categories: categories, loading: false);
  }

  Future<void> updateQuery(String query) async {
    state = state.copyWith(query: query, loading: true);
    final results = await _entries.fetchEntries(query: query, categoryId: state.selectedCategoryId);
    state = state.copyWith(entries: results, loading: false);
  }

  Future<void> selectCategory(String? categoryId) async {
    state = state.copyWith(selectedCategoryId: categoryId, loading: true);
    final results = await _entries.fetchEntries(query: state.query, categoryId: categoryId);
    state = state.copyWith(entries: results, loading: false);
  }

  Future<void> togglePin(Entry entry) async {
    final updated = await _entries.togglePin(entry);
    final entries = List<Entry>.from(state.entries);
    final idx = entries.indexWhere((e) => e.id == entry.id);
    if (idx == -1) {
      entries.add(updated);
    } else {
      entries[idx] = updated;
    }
    state = state.copyWith(entries: entries..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
  }

  void selectEntry(String? entryId) {
    state = state.copyWith(selectedEntryId: entryId);
  }

  Future<void> addCategory(String name, {String? color}) async {
    if (state.creatingCategory) return;
    state = state.copyWith(creatingCategory: true);
    try {
      await _categories.createCategory(name: name, color: color);
      await load();
    } finally {
      state = state.copyWith(creatingCategory: false);
    }
  }

  Future<void> addEntry({
    required String title,
    required String body,
    String? categoryId,
    List<EntryParameter> parameters = const [],
  }) async {
    if (state.creatingEntry) return;
    state = state.copyWith(creatingEntry: true);
    try {
      await _entries.createEntry(
        title: title,
        body: body,
        categoryId: categoryId,
        parameters: parameters,
      );
      await load();
    } finally {
      state = state.copyWith(creatingEntry: false);
    }
  }
}
