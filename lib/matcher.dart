import 'dart:math';
import 'package:fuzzy/fuzzy.dart';

class Matcher<T> {
  List<T> all = [];
  int maxMatches = 10;

  Matcher(this.maxMatches);

  void reset(List<T> news) {
    all = List.from(news);
  }

  List<T> match(String leading, List<String> Function(T) properties) {
    final keys = all.map((e) => properties(e).join(" ")).toList();
    final fuse = Fuzzy(keys, options: FuzzyOptions(threshold: 0.8));
    var result = fuse.search(leading);
    result = result.sublist(0, min(maxMatches, result.length));
    List<T> matches = [];
    for (var r in result) {
      matches.add(all.firstWhere((e) => properties(e).join(" ") == r.item));
    }
    return matches;
  }
}
