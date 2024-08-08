import 'package:fclipboard/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated/l10n.dart';

bool isDesktop() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows;
}

bool isWindowsOrLinux() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows;
}

bool isMobile() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
}

bool isWeb() {
  return kIsWeb;
}

bool isWindows() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.windows;
}

bool isMacOS() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.macOS;
}

void showToast(BuildContext context, String content, bool negative) {
  Widget toast = Container(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25.0),
      color: negative ? Colors.redAccent : Colors.greenAccent,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.notifications),
        const SizedBox(
          width: 12.0,
        ),
        Text(content),
      ],
    ),
  );

  final FToast fToast = FToast();
  fToast.init(context);
  fToast.showToast(
    child: toast,
    gravity: ToastGravity.BOTTOM,
    toastDuration: const Duration(seconds: 2),
  );
}

String loadUserEmail() {
  return FirebaseAuth.instance.currentUser?.email ?? defaultEmail;
}

Future<String> loadServerAddr() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("fclipboard.serverAddr") ?? baseURL;
}

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

bool isLoggedIn() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return false;
  } else if (!user.emailVerified) {
    return false;
  }
  return true;
}

Color? getColor(int selected, index) {
  return selected == index ? const Color.fromARGB(255, 199, 226, 248) : null;
}

Future<int> loadConfig(String name) async {
  final prefs = await SharedPreferences.getInstance();
  final mode = prefs.getInt(name);
  return mode ?? 1;
}

Future<bool> saveConfig(String name, int value) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.setInt(name, value);
}
