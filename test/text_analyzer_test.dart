import 'dart:async';

import 'package:flutter_templat/core/data/models/text_stats_model.dart';
import 'package:flutter_templat/core/enums/request_status.dart';
import 'package:flutter_templat/core/services/text_analyzer_service.dart';
import 'package:flutter_templat/ui/views/text_analyzer/text_analyzer_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class FakeAnalyzerService extends TextAnalyzerService {
  List<String> calls = [];
  Map<String, Completer<TextStatsModel>> pending = {};

  @override
  Future<TextStatsModel> analyze(String text) {
    calls.add(text);
    pending[text] = Completer<TextStatsModel>();
    return pending[text]!.future;
  }
}

Future wait([int ms = 350]) => Future.delayed(Duration(milliseconds: ms));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => Get.reset());

  group('analyzeText', () {
    test('empty text', () {
      final stats = analyzeText('');
      expect(stats.words, 0);
      expect(stats.letters, 0);
      expect(stats.whitespaces, 0);
      expect(stats.topWords, isEmpty);
    });

    test('only spaces', () {
      final stats = analyzeText('   \t\n  ');
      expect(stats.words, 0);
      expect(stats.letters, 0);
      expect(stats.whitespaces, 7);
    });

    test('only symbols', () {
      final stats = analyzeText(r'@#$% ^&*()');
      expect(stats.words, 0);
      expect(stats.letters, 0);
      expect(stats.whitespaces, 1);
      expect(stats.topWords, isEmpty);
    });

    test('words letters and whitespaces', () {
      final stats = analyzeText("Hello, hello! Don't stop.\n");
      expect(stats.words, 4);
      expect(stats.letters, 18);
      expect(stats.whitespaces, 4);
      expect(stats.topWords.first.key, 'hello');
      expect(stats.topWords.first.value, 2);
    });

    test('arabic text', () {
      final stats = analyzeText('مرحبا بالعالم مرحبا');
      expect(stats.words, 3);
      expect(stats.letters, 17);
      expect(stats.topWords.first.key, 'مرحبا');
    });

    test('top 5 words sorted by count then by name', () {
      final stats = analyzeText('a a a B b b d d c c e f');
      expect(stats.topWords.map((e) => e.key).toList(),
          ['a', 'b', 'c', 'd', 'e']);
      expect(stats.topWords.map((e) => e.value).toList(), [3, 3, 2, 2, 1]);
    });
  });

  group('TextAnalyzerService', () {
    test('runs in isolate', () async {
      final stats = await TextAnalyzerService().analyze('lorem ipsum ' * 200000);
      expect(stats.words, 400000);
    });
  });

  group('TextAnalyzerController', () {
    test('shows stats of the text', () async {
      Get.put(TextAnalyzerService());
      final controller = Get.put(TextAnalyzerController());

      controller.textController.text = 'one two two';
      expect(controller.requestStatus.value, RequestStatus.LOADING);
      await wait(1500);

      expect(controller.requestStatus.value, RequestStatus.DEFUALT);
      expect(controller.stats.value.words, 3);
      expect(controller.stats.value.topWords.first.key, 'two');
    });

    test('old result is ignored and middle texts are skipped', () async {
      final service = FakeAnalyzerService();
      Get.put<TextAnalyzerService>(service);
      final controller = Get.put(TextAnalyzerController());

      controller.onTextChanged('a');
      await wait();
      controller.onTextChanged('ab');
      await wait();
      controller.onTextChanged('abc');
      await wait();
      expect(service.calls, ['a']);

      service.pending['a']!.complete(TextStatsModel(words: 111));
      await wait(50);
      expect(controller.stats.value.words, 0);
      expect(controller.requestStatus.value, RequestStatus.LOADING);
      expect(service.calls, ['a', 'abc']);

      service.pending['abc']!.complete(TextStatsModel(words: 222));
      await wait(50);
      expect(controller.stats.value.words, 222);
      expect(controller.requestStatus.value, RequestStatus.DEFUALT);
    });

    test('error then works again on next change', () async {
      final service = FakeAnalyzerService();
      Get.put<TextAnalyzerService>(service);
      final controller = Get.put(TextAnalyzerController());

      controller.onTextChanged('boom');
      await wait();
      service.pending['boom']!.completeError(Exception('isolate crashed'));
      await wait(50);
      expect(controller.requestStatus.value, RequestStatus.ERROR);

      controller.onTextChanged('boom!');
      await wait();
      service.pending['boom!']!.complete(TextStatsModel(words: 1));
      await wait(50);
      expect(controller.requestStatus.value, RequestStatus.DEFUALT);
      expect(controller.stats.value.words, 1);
    });
  });
}
