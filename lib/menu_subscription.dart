import 'package:fclipboard/generated/l10n.dart';
import 'package:fclipboard/subscription_adding.dart';
import 'package:fclipboard/subscription_creating.dart';
import 'package:fclipboard/subscription_list.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/material.dart';

class SubscriptionMenu extends StatelessWidget {
  const SubscriptionMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.cloud),
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () {
            if (!checkLoginState(context)) {
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SubscriptionListView()),
            ).then((value) => {});
          },
          child: Text(S.of(context).subscriptionList),
        ),
        PopupMenuItem(
          onTap: () {
            if (!checkLoginState(context)) {
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SubscriptionAddingPage()),
            ).then((value) => {});
          },
          child: Text(S.of(context).addSubscription),
        ),
        PopupMenuItem(
          onTap: () {
            if (!checkLoginState(context)) {
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SubscriptionCreatingPage()),
            ).then((value) => {});
          },
          child: Text(S.of(context).creatingSubscription),
        ),
      ],
    );
  }
}
