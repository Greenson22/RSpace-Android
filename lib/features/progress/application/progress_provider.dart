// lib/features/progress/application/progress_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/progress_topic_model.dart';
import 'progress_service.dart';

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<ProgressTopic> _topics = [];
  List<ProgressTopic> get topics => _topics;

  ProgressProvider() {
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    _isLoading = true;
    notifyListeners();
    _topics = await _progressService.getAllTopics();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTopic(String name) async {
    await _progressService.addTopic(name);
    await fetchTopics();
  }

  Future<void> reorderTopics(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _topics.removeAt(oldIndex);
    _topics.insert(newIndex, item);

    await _progressService.saveTopicsOrder(_topics);
    notifyListeners();
  }

  // Fungsi baru untuk edit
  Future<void> editTopic(ProgressTopic oldTopic, String newName) async {
    await _progressService.renameTopic(oldTopic, newName);
    await fetchTopics();
  }

  // Fungsi baru untuk hapus
  Future<void> deleteTopic(ProgressTopic topic) async {
    await _progressService.deleteTopic(topic);
    await fetchTopics();
  }
}
