import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/snippet.dart';
import '../../../core/db/local_db.dart';
import '../../../core/sync/sync_store.dart';
import 'local_snippet_store.dart';

class SnippetRepository {
  SnippetRepository(this.ref)
      : _local = LocalSnippetStore(LocalDb.instance),
        _sync = SyncStore(LocalDb.instance),
        _api = ref.read(apiClientProvider);

  final Ref ref;
  final LocalSnippetStore _local;
  final SyncStore _sync;
  final ApiClient _api;
  final _uuid = const Uuid();

  Future<List<Snippet>> fetchSnippets({String? tagId}) async {
    final snippets = await _local.list(tagId: tagId);
    snippets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return snippets;
  }

  Future<Snippet> createSnippet({
    required String title,
    required String body,
    List<String> tagIds = const [],
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
      tagIds: tagIds,
      parameters: parameters,
      pinned: false,
    );
    await _local.upsert(snippet);
    await _sync.enqueue(
        entityType: 'snippet',
        entityId: snippet.id,
        op: 'upsert',
        payload: _snippetToJson(snippet));
    return snippet;
  }

  Future<Snippet> updateSnippet({
    required Snippet snippet,
    required String title,
    required String body,
    List<String>? tagIds,
    List<EntryParameter> parameters = const [],
  }) async {
    final updated = snippet.copyWith(
      title: title,
      body: body,
      tagIds: tagIds ?? snippet.tagIds,
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
        op: 'delete',
        payload: _snippetToJson(deleted));
  }

  Future<int> deleteSnippetsByTagId(String tagId) async {
    final items = await _local.list(tagId: tagId);
    for (final snippet in items) {
      await deleteSnippet(snippet);
    }
    return items.length;
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
    return updated;
  }

  Future<String> shareSnippet({
    required Snippet snippet,
    required String email,
    String? tagId,
    String? tagName,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'tag_id': tagId,
      'tag_name': tagName,
    }..removeWhere((_, value) => value == null);
    final res = await _api.post('/snippets/${snippet.id}/share', body: payload);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Share failed with status ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['token'] as String? ?? '';
  }

  Future<String> shareTag({
    required String tagId,
    required String email,
    String? tagName,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'tag_name': tagName,
    }..removeWhere((_, value) => value == null);
    final res = await _api.post('/tags/$tagId/share', body: payload);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Share tag failed with status ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['token'] as String? ?? '';
  }

  Future<int> acceptShareToken(String token) async {
    final res = await _api.post('/share/accept', body: {'token': token});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Accept share failed with status ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['imported'] as num?)?.toInt() ?? 0;
  }

  Map<String, dynamic> _snippetToJson(Snippet snippet) {
    return {
      'id': snippet.id,
      'title': snippet.title,
      'body': snippet.body,
      'tag_ids': snippet.tagIds,
      'source': snippet.source,
      'pinned': snippet.pinned,
      'parameters': snippet.parameters.map((p) => p.toJson()).toList(),
      'version': snippet.version,
      'created_at': snippet.createdAt.toIso8601String(),
      'updated_at': snippet.updatedAt.toIso8601String(),
      'deleted_at': snippet.deletedAt?.toIso8601String(),
      'conflict_of': snippet.conflictOf,
    };
  }

  Future<Map<String?, int>> countByTag() async {
    return _local.countByTag();
  }

  Future<void> pruneNotIn(Set<String> ids) async {
    await _local.pruneNotIn(ids);
  }

  Future<void> dedupeByTitle(List<Snippet> items) async {
    final seen = <String, Snippet>{};
    final toDelete = <String>[];
    for (final s in items) {
      final existing = seen[s.title];
      if (existing == null || s.updatedAt.isAfter(existing.updatedAt)) {
        if (existing != null) {
          toDelete.add(existing.id);
        }
        seen[s.title] = s;
      } else {
        toDelete.add(s.id);
      }
    }
    if (toDelete.isNotEmpty) {
      await _local.deleteByIds(toDelete);
    }
  }
}

final snippetRepositoryProvider =
    Provider<SnippetRepository>((ref) => SnippetRepository(ref));
