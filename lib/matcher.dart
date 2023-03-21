import 'dart:convert';
import 'dart:math';
import 'package:yaml/yaml.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:flutter/services.dart' show rootBundle;

class Matcher {
  Map<String, String> all = {};

  int maxMatches = 10;

  Matcher(this.maxMatches) {
    init();
  }

  void init() async {
    final manifiestContent = await rootBundle.loadString('AssetManifest.json');
    final manifestMap = json.decode(manifiestContent);
    final commandsPath = manifestMap.keys
        .where((String key) => key.contains('commands/'))
        .where((String key) => key.endsWith('.yaml'))
        .toList();
    for (var file in commandsPath) {
      String content = await rootBundle.loadString(file);
      final yaml = loadYaml(content);
      all.addAll(Map<String, String>.from(yaml));
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
