import 'dart:io';
import 'dart:math';
import 'package:yaml/yaml.dart';
import 'package:fuzzy/fuzzy.dart';

class Matcher {
  Map<String, String> all = {};

  int maxMatches = 10;

  Matcher(this.maxMatches) {
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

  Map<String, String> match(String leading) {
    final fuse = Fuzzy(all.keys.toList(),
        options: FuzzyOptions(distance: 80, maxPatternLength: 10));
    var result = fuse.search(leading);
    result = result.sublist(0, min(maxMatches, result.length));
    Map<String, String> matches = {};
    for (var r in result) {
      matches[r.item] = all[r.item].toString();
    }
    return matches;
  }
}
