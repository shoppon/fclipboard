import 'package:fclipboard/generated/l10n.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class EmailVerifyPage extends StatelessWidget {
  const EmailVerifyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).save),
      ),
      body: EmailVerificationScreen(actions: [
        EmailVerifiedAction(() {
          Navigator.pop(context);
        }),
        AuthCancelledAction((context) {
          FirebaseUIAuth.signOut(context: context);
          Navigator.pushReplacementNamed(context, '/');
        })
      ]),
    );
  }
}
