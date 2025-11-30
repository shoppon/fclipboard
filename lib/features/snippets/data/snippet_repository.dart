import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/snippet.dart';
import '../../../core/db/local_db.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_store.dart';
import 'local_snippet_store.dart';

class SnippetRepository {
  SnippetRepository(this.ref)
      : _local = LocalSnippetStore(LocalDb.instance),
        _sync = SyncStore(LocalDb.instance);

  final Ref ref;
  final LocalSnippetStore _local;
  final SyncStore _sync;
  final _uuid = const Uuid();

  Future<List<Snippet>> fetchSnippets(
      {String query = "", String? tagId}) async {
    final snippets = await _local.list(tagId: tagId);
    final filtered = query.isEmpty
        ? snippets
        : snippets
            .where((e) =>
                e.title.toLowerCase().contains(query.toLowerCase()) ||
                e.body.toLowerCase().contains(query.toLowerCase()))
            .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    ref.read(syncServiceProvider).sync();
    return filtered;
  }

  Future<Snippet> createSnippet({
    required String title,
    required String body,
    String? tagId,
    List<String> tags = const [],
    List<EntryParameter> parameters = const [],
  }) async {
    final now = DateTime.now();
    final snippet = Snippet(
      id: _uuid.v4(),
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
      version: 1,
      tags: tags,
      tagId: tagId,
      parameters: parameters,
      pinned: false,
    );
    await _local.upsert(snippet);
    await _sync.enqueue(
        entityType: 'snippet',
        entityId: snippet.id,
        op: 'upsert',
        payload: _snippetToJson(snippet));
    ref.read(syncServiceProvider).sync();
    return snippet;
  }

  Future<Snippet> updateSnippet({
    required Snippet snippet,
    required String title,
    required String body,
    String? tagId,
    List<EntryParameter> parameters = const [],
  }) async {
    final updated = snippet.copyWith(
      title: title,
      body: body,
      tagId: tagId,
      parameters: parameters,
      updatedAt: DateTime.now(),
      version: snippet.version + 1,
    );
    await _local.upsert(updated);
    await _sync.enqueue(
        entityType: 'snippet',
        entityId: updated.id,
        op: 'upsert',
        payload: _snippetToJson(updated));
    ref.read(syncServiceProvider).sync();
    return updated;
  }

  Future<void> deleteSnippet(Snippet snippet) async {
    final deleted = snippet.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      version: snippet.version + 1,
    );
    await _local.upsert(deleted);
    await _sync.enqueue(
        entityType: 'snippet',
        entityId: deleted.id,
        op: 'upsert',
        payload: _snippetToJson(deleted));
    ref.read(syncServiceProvider).sync();
  }

  Future<Snippet> togglePin(Snippet snippet) async {
    final updated = snippet.copyWith(
        pinned: !snippet.pinned,
        updatedAt: DateTime.now(),
        version: snippet.version + 1);
    await _local.upsert(updated);
    await _sync.enqueue(
        entityType: 'snippet',
        entityId: updated.id,
        op: 'upsert',
        payload: _snippetToJson(updated));
    ref.read(syncServiceProvider).sync();
    return updated;
  }

  Map<String, dynamic> _snippetToJson(Snippet snippet) {
    return {
      'id': snippet.id,
      'title': snippet.title,
      'body': snippet.body,
      'tags': snippet.tags,
      'source': snippet.source,
      'pinned': snippet.pinned,
      'parameters': snippet.parameters.map((p) => p.toJson()).toList(),
      'version': snippet.version,
      'created_at': snippet.createdAt.toIso8601String(),
      'updated_at': snippet.updatedAt.toIso8601String(),
      'deleted_at': snippet.deletedAt?.toIso8601String(),
      'conflict_of': snippet.conflictOf,
      'tag_id': snippet.tagId,
    };
  }
}

final snippetRepositoryProvider =
    Provider<SnippetRepository>((ref) => SnippetRepository(ref));
