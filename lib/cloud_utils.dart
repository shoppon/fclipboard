import 'package:fclipboard/dao.dart';
import 'package:openapi/api.dart';

import 'model.dart' as m;
import 'utils.dart';

bool isParametersSame(m.Entry local, Entry server) {
  if (local.parameters.length != server.parameters.length) {
    return false;
  }
  for (var i = 0; i < local.parameters.length; i++) {
    if (local.parameters[i].name != server.parameters[i].name ||
        local.parameters[i].initial != server.parameters[i].initial ||
        local.parameters[i].description != server.parameters[i].description ||
        local.parameters[i].required != server.parameters[i].required_) {
      return false;
    }
  }
  return true;
}

Future<void> updateLocalEntry(m.Entry local, Entry server) async {
  if (local.uuid == server.uuid! &&
      local.title == server.name! &&
      local.subtitle == server.content! &&
      isParametersSame(local, server)) {
    return;
  }
  local.uuid = server.uuid!;
  local.title = server.name!;
  local.subtitle = server.content!;
  local.version = server.version!;
  local.parameters =
      server.parameters.map((e) => m.Param.fromJson(e.toJson())).toList();
  await DBHelper().insertEntry(local);
}

Future<Entry> updateServerEntry(m.Entry entry) async {
  final api = EntryApi(ApiClient(basePath: await loadServerAddr()));
  final email = loadUserEmail();
  final req = EntryPatchReq(
      entry: EntryBody(
          name: entry.title,
          content: entry.subtitle,
          counter: entry.counter,
          version: entry.version,
          parameters: entry.parameters
              .map((e) => Parameter.fromJson(e.toJson())!)
              .toList()));
  final resp = await api
      .updateEntry(email, entry.uuid, entryPatchReq: req)
      .timeout(const Duration(seconds: 3));
  return resp!.entry!;
}

Future<Entry?> getServerEntry(String eid) async {
  final api = EntryApi(ApiClient(basePath: await loadServerAddr()));
  final email = loadUserEmail();
  try {
    final resp =
        await api.getEntry(email, eid).timeout(const Duration(seconds: 3));
    return resp!.entry!;
  } on ApiException catch (e) {
    if (e.code == 404) {
      return null;
    } else {
      rethrow;
    }
  }
}

Future<void> updateLocalCategory(m.Category local, Category server) async {
  if (local.uuid == server.uuid! && local.name == server.name!) {
    return;
  }
  local.uuid = server.uuid!;
  local.name = server.name!;
  await DBHelper().insertCategory(local);
}

Future<bool> deleteServerCategory(String cid) async {
  final api = CategoryApi(ApiClient(basePath: await loadServerAddr()));
  final email = loadUserEmail();
  try {
    await api.deleteCategory(email, cid).timeout(const Duration(seconds: 3));
    return true;
  } catch (e) {
    return false;
  }
}
