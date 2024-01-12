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

  Future<List<Category>> getServerCategories() async {
    final api = CategoryApi(ApiClient(basePath: await loadServerAddr()));
    final email = loadUserEmail();
    final resp = await api.listCategories(email);
    return resp!.categories;
  }

  Future<bool> syncEntries(ProgressDialog pd) async {
    final localEntries = await _dbHelper.entries();
    final serverEntires = await getServerEntries();
    final localCategories = await _dbHelper.categories();
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
        await _dbHelper.insertEntry(m.Entry(
          title: se.name!,
          subtitle: se.content!,
          categoryId: localCategories
              .firstWhereOrNull((c) => c.name == se.category!)!
              .id,
          counter: se.counter!,
          uuid: se.uuid!,
          parameters:
              se.parameters.map((e) => m.Param.fromJson(e.toJson())).toList(),
        ));
      }
    }
    return true;
  }

  Future<bool> syncCategories() async {
    final localCategories = await _dbHelper.categories();
    final serverCategories = await getServerCategories();
    // upload if not exist in server
    // update if exist in server
    // delete if deleted in server
    final api = CategoryApi(ApiClient(basePath: await loadServerAddr()));
    final email = loadUserEmail();
    for (final lc in localCategories) {
      if (lc.uuid.isEmpty) {
        final resp = await api.createCategory(email,
            categoryPostReq: CategoryPostReq(
                category: CategoryPostReqCategory(
              name: lc.name,
              icon: lc.icon,
              isPrivate: lc.isPrivate,
            )));
        lc.uuid = resp!.category!.uuid!;
        await _dbHelper.insertCategory(lc);
      } else {
        final sc = serverCategories.firstWhereOrNull((c) => c.uuid == lc.uuid);
        if (sc != null) {
          if (sc.deleted!) {
            await _dbHelper.deleteCategory(lc.name);
          } else {
            //TODO(xp): update local
          }
        }
      }
    }
    for (final sc in serverCategories) {
      final lc = localCategories.firstWhereOrNull((c) => c.name == sc.name);
      if (lc == null) {
        await _dbHelper.insertCategory(m.Category(
          name: sc.name!,
          icon: sc.icon!,
          uuid: sc.uuid!,
          isPrivate: sc.isPrivate!,
        ));
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        ProgressDialog pd = ProgressDialog(context: context);
        pd.show(msg: S.of(context).loading);
        try {
          await syncCategories();
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
