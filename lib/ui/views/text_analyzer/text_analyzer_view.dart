import 'package:flutter/material.dart';
import 'package:flutter_templat/core/enums/request_status.dart';
import 'package:flutter_templat/ui/shared/colors.dart';
import 'package:flutter_templat/ui/shared/utlis.dart';
import 'package:flutter_templat/ui/views/text_analyzer/text_analyzer_controller.dart';
import 'package:get/get.dart';

class TextAnalyzerView extends StatefulWidget {
  const TextAnalyzerView({super.key});

  @override
  State<TextAnalyzerView> createState() => _TextAnalyzerViewState();
}

class _TextAnalyzerViewState extends State<TextAnalyzerView> {
  TextAnalyzerController controller = Get.put(TextAnalyzerController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(title: Text('Live Text Analyzer')),
      body: Padding(
        padding: EdgeInsets.all(screenWidth(25)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: controller.textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Type or paste your text here',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: screenWidth(25)),
            Obx(() {
              if (controller.requestStatus.value == RequestStatus.ERROR) {
                return Text(
                  'Analysis failed, change the text to try again',
                  style: TextStyle(color: AppColors.redcolor),
                );
              }
              bool isLoading =
                  controller.requestStatus.value == RequestStatus.LOADING;
              // old numbers are faded until the new result comes
              return Opacity(
                opacity: isLoading ? 0.4 : 1,
                child: statsPanel(),
              );
            }),
          ],
        ),
      ),
    ));
  }

  Widget statsPanel() {
    final stats = controller.stats.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            statItem('Words', stats.words),
            SizedBox(width: screenWidth(40)),
            statItem('Letters', stats.letters),
            SizedBox(width: screenWidth(40)),
            statItem('Whitespaces', stats.whitespaces),
          ],
        ),
        SizedBox(height: screenWidth(30)),
        Text('Top 5 words', style: TextStyle(fontWeight: FontWeight.bold)),
        if (stats.topWords.isEmpty)
          Text('No words yet', style: TextStyle(color: AppColors.greycolor)),
        ...stats.topWords.map((e) {
          return Row(
            children: [
              Expanded(
                child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text('${e.value}'),
            ],
          );
        }),
      ],
    );
  }

  Widget statItem(String title, int value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(screenWidth(40)),
        decoration: BoxDecoration(
          color: AppColors.textformgrey,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(fontSize: 12, color: AppColors.greycolor)),
            FittedBox(
              child: Text(
                '$value',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
