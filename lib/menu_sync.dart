import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:fclipboard/apple_books.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:openapi/api.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';

import 'cloud_utils.dart';
import 'generated/l10n.dart';
import 'model.dart' as m;

class CloudMenu extends StatelessWidget {
  CloudMenu({Key? key, required this.onChanged}) : super(key: key);

  final _dbHelper = DBHelper();
  final void Function() onChanged;

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
        EntryPostResp? resp = await uploadEntry(api, email, le);
        await updateLocalEntry(le, resp!.entry!);
      } else {
        final se = serverEntires.firstWhereOrNull((e) => e.uuid == le.uuid);
        if (se == null) {
          EntryPostResp? resp = await uploadEntry(api, email, le);
          await updateLocalEntry(le, resp!.entry!);
        } else {
          if (se.deleted!) {
            await _dbHelper.deleteEntry(le.title);
          } else {
            await updateLocalEntry(le, se);
          }
        }
      }
    }
    for (final se in serverEntires) {
      count++;
      pd.update(value: count * 100 ~/ total, msg: se.name);
      if (se.deleted!) {
        continue;
      }

      final le = localEntries.firstWhereOrNull((e) => e.title == se.name);
      if (le == null) {
        await createLocalEntry(se, localCategories);
      } else {
        await updateLocalEntry(le, se);
      }
    }
    return true;
  }

  Future<void> createLocalEntry(
    Entry se,
    List<m.Category> localCategories,
  ) async {
    await _dbHelper.insertEntry(m.Entry(
      title: se.name!,
      subtitle: se.content!,
      categoryId:
          localCategories.firstWhereOrNull((c) => c.name == se.category!)!.id,
      counter: se.counter ?? 0,
      version: se.version!,
      uuid: se.uuid!,
      parameters:
          se.parameters.map((e) => m.Param.fromJson(e.toJson())).toList(),
    ));
  }

  Future<EntryPostResp?> uploadEntry(
      EntryApi api, String email, m.Entry le) async {
    final resp = await api.createEntry(email,
        entryPostReq: EntryPostReq(
          entry: EntryBody(
            name: le.title,
            content: le.subtitle,
            category: le.categoryName,
            counter: le.counter,
            version: le.version,
            parameters: le.parameters
                .map((e) => Parameter.fromJson(e.toJson())!)
                .toList(),
          ),
        ));
    return resp;
  }

  Future<void> createLocalCategory(Category sc) async {
    await _dbHelper.insertCategory(m.Category(
      name: sc.name!,
      icon: sc.icon!,
      uuid: sc.uuid!,
      isPrivate: sc.isPrivate ?? false,
    ));
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
            updateLocalCategory(lc, sc);
          }
        }
      }
    }
    for (final sc in serverCategories) {
      if (sc.deleted!) {
        continue;
      }

      final lc = localCategories.firstWhereOrNull((c) => c.name == sc.name);
      if (lc == null) {
        await createLocalCategory(sc);
      } else {
        await updateLocalCategory(lc, sc);
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.sync),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () async {
            if (!checkLoginState(context)) {
              return;
            }
            ProgressDialog pd = ProgressDialog(context: context);
            pd.show(msg: S.of(context).loading);
            try {
              await syncCategories();
              await syncEntries(pd);
              if (context.mounted) {
                showToast(context, S.of(context).successfully, false);
              }
              onChanged();
            } catch (e, stackTrace) {
              log(e.toString(), stackTrace: stackTrace);
              if (context.mounted) {
                showToast(context, S.of(context).failed, true);
              }
            } finally {
              pd.close();
            }
          },
          child: Text(S.of(context).syncCloud),
        ),
        if (isMacOS())
          PopupMenuItem(
            onTap: () async {
              if (!checkLoginState(context)) {
                return;
              }
              ProgressDialog pd = ProgressDialog(context: context);
              pd.show(msg: S.of(context).loading);
              try {
                await importAppleBooks();
                onChanged();
                if (context.mounted) {
                  showToast(context, S.of(context).successfully, false);
                }
              } catch (e, stackTrace) {
                log(e.toString(), stackTrace: stackTrace);
                if (context.mounted) {
                  showToast(context, S.of(context).failed, true);
                }
              } finally {
                pd.close();
              }
            },
            child: Text(S.of(context).syncAppleBooks),
          ),
      ],
    );
  }
}
