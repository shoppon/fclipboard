import 'package:fclipboard/generated/l10n.dart';
import 'package:fclipboard/subscription_adding.dart';
import 'package:fclipboard/subscription_creating.dart';
import 'package:fclipboard/subscription_list.dart';
import 'package:fclipboard/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubscriptionMenu extends StatelessWidget {
  const SubscriptionMenu({Key? key}) : super(key: key);

  bool checkLoginState(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showToast(context, S.of(context).loginTooltip, true);
      return false;
    } else if (!user.emailVerified) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.cloud),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: TextButton(
            onPressed: () {
              if (!checkLoginState(context)) {
                return;
              }
              Navigator.pop(context);
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
              if (!checkLoginState(context)) {
                return;
              }
              Navigator.pop(context);
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
              if (!checkLoginState(context)) {
                return;
              }
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
