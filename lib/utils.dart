import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

bool isDesktop() {
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
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
