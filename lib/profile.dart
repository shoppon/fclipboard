import 'package:fclipboard/generated/l10n.dart';
import 'package:fclipboard/utils.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).profile),
      ),
      body: ProfileScreen(
        actions: [
          SignedOutAction((context) {
            Navigator.pushReplacementNamed(context, '/');
          })
        ],
        showMFATile: isMobile() || isWeb(),
        showUnlinkConfirmationDialog: true,
      ),
    );
  }
}
