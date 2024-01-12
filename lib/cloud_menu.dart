import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:openapi/api.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

import 'generated/l10n.dart';
import 'model.dart' as m;

class CloudMenu extends StatelessWidget {
  CloudMenu({Key? key}) : super(key: key);

  final _dbHelper = DBHelper();

  Future<List<Entry>> getServerEntries() async {
    final api = EntryApi(ApiClient(basePath: await loadServerAddr()));
    final email = loadUserEmail();
    final resp = await api.listEntries(email);
    return resp!.entries;
  }

  Future<bool> syncEntries(ProgressDialog pd) async {
    final localEntries = await _dbHelper.entries();
    final serverEntires = await getServerEntries();
    final total = localEntries.length + serverEntires.length;
    int count = 0;
    // upload if not exist in server(uuid is empty)
    // update if exist in server(uuid is not empty)
    // delete if deleted in server(uuid is not empty and deleted is true)
    final api = EntryApi(ApiClient(basePath: await loadServerAddr()));
    final email = loadUserEmail();
    for (final le in localEntries) {
      count++;
      pd.update(value: count * 100 ~/ total, msg: le.title);
      if (le.uuid.isEmpty) {
        final resp = await api.createEntry(email,
            entryPostReq: EntryPostReq(
              entry: EntryBody(
                name: le.title,
                content: le.subtitle,
                category: le.categoryName,
                counter: le.counter,
                parameters: le.parameters
                    .map((e) => Parameter.fromJson(e.toJson())!)
                    .toList(),
              ),
            ));
        le.uuid = resp!.entry!.uuid!;
        await _dbHelper.insertEntry(le);
      } else {
        final se = serverEntires.firstWhereOrNull((e) => e.uuid == le.uuid);
        if (se != null) {
          if (se.deleted!) {
            await _dbHelper.deleteEntry(le.title);
          } else {
            //TODO(xp): update local
          }
        }
      }
    }
    for (final se in serverEntires) {
      count++;
      pd.update(value: count * 100 ~/ total, msg: se.name);
      final le = localEntries.firstWhereOrNull((e) => e.title == se.name);
      if (le == null) {
        await _dbHelper.insertEntry(m.Entry.fromJson(se.toJson()));
      }
    }
    return true;
  }

  Future<bool> uploadCategories() async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        ProgressDialog pd = ProgressDialog(context: context);
        pd.show(msg: S.of(context).loading);
        try {
          await syncEntries(pd);
        } catch (e) {
          log(e.toString());
        } finally {
          pd.close();
        }
      },
      icon: const Icon(Icons.sync),
    );
  }
}
