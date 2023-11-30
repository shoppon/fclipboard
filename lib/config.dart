import 'package:fclipboard/utils.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/foundation.dart';

const googleClientId =
    '748110936399-qpmsrv4b7i6btvh9p5j6a9arm1b1i5sq.apps.googleusercontent.com';

List<AuthProvider> getAuthProviders() {
  if (kIsWeb) {
    return [
      EmailAuthProvider(),
      GoogleProvider(clientId: googleClientId),
    ];
  } else if (isMobile()) {
    return [
      EmailAuthProvider(),
      AppleProvider(),
    ];
  } else if (isMacOS()) {
    return [
      EmailAuthProvider(),
      AppleProvider(),
    ];
  } else {
    return [EmailAuthProvider()];
  }
}
