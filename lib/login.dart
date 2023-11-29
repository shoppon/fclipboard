import 'package:fclipboard/generated/l10n.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).login),
      ),
      body: SignInScreen(
        actions: [
          VerifyPhoneAction((context, _) {
            Navigator.pushNamed(context, '/phone');
          }),
          AuthCancelledAction((context) {
            FirebaseUIAuth.signOut(context: context);
            Navigator.pushReplacementNamed(context, '/');
          }),
          AuthStateChangeAction((context, state) {
            final user = switch (state) {
              SignedIn(user: final user) => user,
              _ => null,
            };
            switch (user) {
              case User(emailVerified: true):
                Navigator.pop(context);
              case User(emailVerified: false):
                Navigator.pushReplacementNamed(context, '/verify-email');
            }
          })
        ],
      ),
    );
  }
}
