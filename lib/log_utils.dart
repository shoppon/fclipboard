import 'dart:io';

import 'package:openapi/api.dart';

import 'utils.dart';

Future<bool> uploadLog(String action, String content, String stack) async {
  if (await loadConfig('fclipboard.debug') == 0) {
    return false;
  }

  final api = LogApi(ApiClient(basePath: await loadServerAddr()));
  final email = loadUserEmail();
  try {
    await api
        .uploadLog(
          email,
          logPostReq: LogPostReq(
            log: Log(
              action: action,
              content: content,
              platform: Platform.operatingSystem,
              stack: stack,
            ),
          ),
        )
        .timeout(const Duration(seconds: 3));
    return true;
  } catch (e) {
    return false;
  }
}
