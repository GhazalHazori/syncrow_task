import 'dart:isolate';

import 'package:flutter_templat/core/data/models/text_stats_model.dart';

class TextAnalyzerService {
  // new isolate for every run, if it crashes the future completes with error
  Future<TextStatsModel> analyze(String text) {
    return Isolate.run(() => analyzeText(text));
  }
}

// top level so it can run inside the isolate
TextStatsModel analyzeText(String text) {
  // letters and numbers, \p{M} is for arabic tashkeel
  RegExp wordExp =
      RegExp(r"[\p{L}\p{N}\p{M}]+(['’][\p{L}\p{N}\p{M}]+)*", unicode: true);
  RegExp letterExp = RegExp(r'\p{L}', unicode: true);
  RegExp spaceExp = RegExp(r'\s');

  Map<String, int> counts = {};
  int words = 0;
  for (var match in wordExp.allMatches(text)) {
    String word = match.group(0)!.toLowerCase();
    counts[word] = (counts[word] ?? 0) + 1;
    words++;
  }

  List<MapEntry<String, int>> sorted = counts.entries.toList();
  sorted.sort((a, b) {
    if (a.value != b.value) return b.value.compareTo(a.value);
    return a.key.compareTo(b.key);
  });

  return TextStatsModel(
    words: words,
    letters: letterExp.allMatches(text).length,
    whitespaces: spaceExp.allMatches(text).length,
    topWords: sorted.take(5).toList(),
  );
}
