import 'package:fclipboard/generated/l10n.dart';
import 'package:fclipboard/subscription_adding.dart';
import 'package:fclipboard/subscription_creating.dart';
import 'package:fclipboard/subscription_list.dart';
import 'package:flutter/material.dart';

class CloudSyncMenu extends StatelessWidget {
  const CloudSyncMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.cloud),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionListView()),
              ).then((value) => {});
            },
            child: Text(S.of(context).subscriptionList),
          ),
        ),
        PopupMenuItem(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionAddingPage()),
              ).then((value) => {});
            },
            child: Text(S.of(context).addSubscription),
          ),
        ),
        PopupMenuItem(
          child: TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionCreatingPage()),
              ).then((value) => {});
            },
            child: Text(S.of(context).creatingSubscription),
          ),
        ),
      ],
    );
  }
}
