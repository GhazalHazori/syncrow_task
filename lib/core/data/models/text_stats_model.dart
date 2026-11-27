class TextStatsModel {
  int words;
  int letters;
  int whitespaces;
  List<MapEntry<String, int>> topWords;

  TextStatsModel({
    this.words = 0,
    this.letters = 0,
    this.whitespaces = 0,
    this.topWords = const [],
  });
}
