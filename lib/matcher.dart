import 'dart:math';
import 'package:fclipbaord/dao.dart';
import 'package:fclipbaord/model.dart';
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
    final keys = all.map((e) => e.title).toList();
    final fuse =
        Fuzzy(keys, options: FuzzyOptions(distance: 80, maxPatternLength: 10));
    var result = fuse.search(leading);
    result = result.sublist(0, min(maxMatches, result.length));
    List<Entry> matches = [];
    for (var r in result) {
      matches.add(all.firstWhere((e) => e.title == r.item));
    }
    return matches;
  }
}
