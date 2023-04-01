import 'dart:math';
import 'package:fclipboard/model.dart';
import 'package:fuzzy/fuzzy.dart';

class Matcher {
  List<Entry> all = [];

  int maxMatches = 10;

  Matcher(this.maxMatches);

  void reset(List<Entry> news) {
    all = List.from(news);
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
