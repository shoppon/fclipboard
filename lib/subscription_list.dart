import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import 'dao.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final apiInstance =
        DefaultApi(ApiClient(basePath: 'http://localhost:8000'));
    final listResp = await apiInstance.listSubscriptions();
    setState(() {
      _subscriptions = listResp!.subscriptions;
    });
  }

  Future<void> _pushSubscription(Subscription subscription) async {
    final apiInstance =
        DefaultApi(ApiClient(basePath: 'http://localhost:8000'));
    final dbs = await _dbHelper.entries(category: subscription.categories[0]);
    final List<Entry> entries = [];
    for (final db in dbs) {
      entries.add(Entry(
        title: db.title,
        content: db.subtitle,
        category: db.categoryName,
      ));
    }
    await apiInstance.pushSubscription(subscription.id!,
        subscriptionPushReq: SubscriptionPushReq(entries: entries));
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
            return ListTile(
              title: Text(subscription.url ?? ''),
              subtitle: Text(subscription.categories.join(', ')),
              trailing: IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () {
                  _pushSubscription(subscription);
                },
              ),
            );
          },
        ));
  }
}
