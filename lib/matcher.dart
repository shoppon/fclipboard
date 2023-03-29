import 'dart:math';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/model.dart';
import 'package:yaml/yaml.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:flutter/services.dart' show rootBundle;

class Matcher {
  List<Entry> all = [];

  int maxMatches = 10;

  Matcher(this.maxMatches) {
    init();
  }

  void init() async {
    final helper = DBHelper();
    final categoiries = await helper.categories();
    for (var category in categoiries) {
      final content = await rootBundle.loadString(category.conf);
      final yaml = loadYaml(content);
      all.addAll(Map<String, String>.from(yaml).entries.map((e) => Entry(
          title: '${category.name}_${e.key}',
          subtitle: e.value,
          category: category.name,
          icon: category.icon)));
    }
  }

  List<Entry> match(String leading) {
    final keys = all.map((e) => e.title.replaceAll(RegExp("_"), "")).toList();
    final fuse = Fuzzy(keys, options: FuzzyOptions(threshold: 0.8));
    var result = fuse.search(leading);
    result = result.sublist(0, min(maxMatches, result.length));
    List<Entry> matches = [];
    for (var r in result) {
      matches.add(
          all.firstWhere((e) => e.title.replaceAll(RegExp("_"), "") == r.item));
    }
    return matches;
  }
}
