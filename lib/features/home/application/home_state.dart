import '../../../core/data/snippet.dart';
import '../../../core/data/tag.dart';

class HomeState {
  const HomeState({
    required this.snippets,
    required this.tags,
    required this.loading,
    required this.query,
    required this.creatingTag,
    required this.creatingSnippet,
    this.selectedSnippetId,
    this.selectedTagId,
  });

  final List<Snippet> snippets;
  final List<Tag> tags;
  final bool loading;
  final String query;
  final String? selectedTagId;
  final bool creatingTag;
  final bool creatingSnippet;
  final String? selectedSnippetId;

  HomeState copyWith({
    List<Snippet>? snippets,
    List<Tag>? tags,
    bool? loading,
    String? query,
    String? selectedTagId,
    bool? creatingTag,
    bool? creatingSnippet,
    String? selectedSnippetId,
  }) {
    return HomeState(
      snippets: snippets ?? this.snippets,
      tags: tags ?? this.tags,
      loading: loading ?? this.loading,
      query: query ?? this.query,
      selectedTagId: selectedTagId ?? this.selectedTagId,
      creatingTag: creatingTag ?? this.creatingTag,
      creatingSnippet: creatingSnippet ?? this.creatingSnippet,
      selectedSnippetId: selectedSnippetId ?? this.selectedSnippetId,
    );
  }

  factory HomeState.initial() => const HomeState(
        snippets: [],
        tags: [],
        loading: false,
        query: "",
        creatingTag: false,
        creatingSnippet: false,
        selectedSnippetId: null,
        selectedTagId: null,
      );
}
