import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_templat/core/data/models/text_stats_model.dart';
import 'package:flutter_templat/core/enums/request_status.dart';
import 'package:flutter_templat/core/services/base_controller.dart';
import 'package:flutter_templat/core/utils/general_utile.dart';
import 'package:get/get.dart';

class TextAnalyzerController extends BaseControoler {
  TextEditingController textController = TextEditingController();
  Rx<TextStatsModel> stats = TextStatsModel().obs;

  Timer? _timer;
  String _text = '';
  int _version = 0;
  int _doneVersion = 0;
  bool _isRunning = false;

  @override
  void onInit() {
    textController.addListener(() => onTextChanged(textController.text));
    super.onInit();
  }

  void onTextChanged(String text) {
    if (text == _text) return;
    _text = text;
    _version++;
    requestStatus.value = RequestStatus.LOADING;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: 250), analyze);
  }

  Future analyze() async {
    if (_isRunning) return;
    _isRunning = true;

    while (_doneVersion != _version && !isClosed) {
      int version = _version;
      TextStatsModel? result;
      try {
        result = await textAnalyzerService.analyze(_text);
      } catch (e) {
        print(e);
      }
      _doneVersion = version;

      if (version != _version) continue;

      if (result == null) {
        requestStatus.value = RequestStatus.ERROR;
      } else {
        stats.value = result;
        requestStatus.value = RequestStatus.DEFUALT;
      }
    }
    _isRunning = false;
  }

  @override
  void onClose() {
    _timer?.cancel();
    textController.dispose();
    super.onClose();
  }
}
