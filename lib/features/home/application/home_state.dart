import '../../../core/data/category.dart';
import '../../../core/data/entry.dart';

class HomeState {
  const HomeState({
    required this.entries,
    required this.categories,
    required this.loading,
    required this.query,
    required this.creatingCategory,
    required this.creatingEntry,
    this.selectedEntryId,
    this.selectedCategoryId,
  });

  final List<Entry> entries;
  final List<Category> categories;
  final bool loading;
  final String query;
  final String? selectedCategoryId;
  final bool creatingCategory;
  final bool creatingEntry;
  final String? selectedEntryId;

  HomeState copyWith({
    List<Entry>? entries,
    List<Category>? categories,
    bool? loading,
    String? query,
    String? selectedCategoryId,
    bool? creatingCategory,
    bool? creatingEntry,
    String? selectedEntryId,
  }) {
    return HomeState(
      entries: entries ?? this.entries,
      categories: categories ?? this.categories,
      loading: loading ?? this.loading,
      query: query ?? this.query,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      creatingCategory: creatingCategory ?? this.creatingCategory,
      creatingEntry: creatingEntry ?? this.creatingEntry,
      selectedEntryId: selectedEntryId ?? this.selectedEntryId,
    );
  }

  factory HomeState.initial() => const HomeState(
        entries: [],
        categories: [],
        loading: false,
        query: "",
        creatingCategory: false,
        creatingEntry: false,
        selectedEntryId: null,
      );
}
