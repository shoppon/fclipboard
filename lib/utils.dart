import 'dart:io';

bool isDesktop() {
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}
