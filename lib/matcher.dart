import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:fuzzy/fuzzy.dart';

class Matcher {
  Map<String, String> all = {};

  Matcher() {
    init();
  }

  void init() async {
    final directory = Directory('conf');
    final files = await directory.list().toList();
    for (var file in files) {
      if (file is File && file.path.endsWith('.yaml')) {
        final content = await file.readAsString();
        final yaml = loadYaml(content);
        all.addAll(Map<String, String>.from(yaml));
      }
    }
  }

  match(String leading) {
    final fuse = Fuzzy(['a', 'b', 'c'],
        options: FuzzyOptions(distance: 80, maxPatternLength: 10));
    final result = fuse.search(leading);
    return result;
  }
}
