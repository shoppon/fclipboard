import 'dart:developer';

import 'package:fclipboard/constants.dart';
import 'package:fclipboard/generated/l10n.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:openapi/api.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dao.dart';
import 'model.dart' as model;

var logger = Logger();

class SubscriptionListView extends StatefulWidget {
  const SubscriptionListView({
    Key? key,
  }) : super(key: key);

  @override
  State<SubscriptionListView> createState() => _SubscriptionListViewState();
}

class _SubscriptionListViewState extends State<SubscriptionListView> {
  List<Subscription> _subscriptions = [];
  final _dbHelper = DBHelper();
  int _curSelected = -1;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<String> _loadUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("fclipboard.email")!;
  }

  Future<void> _loadSubscriptions() async {
    final email = await _loadUserEmail();
    final apiInstance = DefaultApi(ApiClient(basePath: baseURL));
    try {
      final listResp = await apiInstance.listSubscriptions(email);
      setState(() {
        _subscriptions = listResp!.subscriptions;
      });
    } catch (e) {
      logger.e("Failed to load subscription", error: e);
      if (context.mounted) {
        showToast(context, S.of(context).loadFailed, true);
      }
    }
  }

  Future<void> _pushSubscription(Subscription subscription) async {
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(msg: S.of(context).pushing);
    final apiInstance = DefaultApi(ApiClient(basePath: baseURL));
    final dbs = await _dbHelper.entries(categories: subscription.categories);
    if (dbs.isEmpty) {
      pd.close();
      return;
    }
    final List<Entry> entries = [];
    for (final db in dbs) {
      final params = db.parameters
          .map((e) => EntryParametersInner(
                name: e.name,
                initial: e.initial,
                required_: e.required,
                description: e.description,
              ))
          .toList();
      entries.add(Entry(
        name: db.title,
        content: db.subtitle,
        counter: db.counter,
        category: db.categoryName,
        parameters: params,
      ));
    }
    try {
      final email = await _loadUserEmail();
      await apiInstance.pushSubscription(email, subscription.id,
          subscriptionPushReq: SubscriptionPushReq(entries: entries));
      if (context.mounted) {
        showToast(context, S.of(context).addSuccessfully, false);
      }
    } catch (e) {
      logger.e("Failed to push", error: e);
      if (context.mounted) {
        showToast(context, S.of(context).addFailed, true);
      }
    } finally {
      pd.close();
    }
  }

  Future<void> _pullSubscription(Subscription subscription) async {
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(msg: "Loading...");
    final apiInstance = DefaultApi(ApiClient(basePath: baseURL));
    final email = await _loadUserEmail();
    try {
      final resp = await apiInstance.pullSubscription(email, subscription.id);
      // FIXME(xp): this operation may be very slow
      final total = resp?.entries.length;
      var count = 0;
      for (final e in resp!.entries) {
        List<model.Param> params = [];
        for (final p in e.parameters) {
          params.add(model.Param.fromJson(p.toJson()));
        }
        final entry = model.Entry(
            title: e.name!,
            subtitle: e.content!,
            parameters: params,
            categoryId: 0,
            categoryName: e.category!,
            counter: e.counter ?? 0);
        await _dbHelper.importEntry(entry);
        setState(() {
          pd.update(value: count * 100 ~/ total!, msg: entry.title);
        });
        count++;
      }
    } catch (e) {
      log(e.toString());
    } finally {
      pd.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Subscriptions'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: ListView.builder(
          itemCount: _subscriptions.length,
          itemBuilder: (context, index) {
            final subscription = _subscriptions[index];
            return Container(
              color: _curSelected == index
                  ? const Color.fromARGB(255, 199, 226, 248)
                  : null,
              child: ListTile(
                title: Text(subscription.name ?? ''),
                subtitle: Text(subscription.categories.join(', ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        _pullSubscription(subscription);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.publish_outlined),
                      onPressed: () {
                        _pushSubscription(subscription);
                      },
                    ),
                  ],
                ),
                selected: _curSelected == index,
                onTap: () {
                  setState(() {
                    _curSelected = index;
                  });
                },
              ),
            );
          },
        ));
  }
}
