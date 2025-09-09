// lib/features/progress/application/progress_detail_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/progress_topic_model.dart';
import 'progress_service.dart';

class ProgressDetailProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  ProgressTopic topic;

  ProgressDetailProvider(this.topic);

  void update() {
    notifyListeners();
  }

  Future<void> save() async {
    await _progressService.saveTopic(topic);
  }
}
