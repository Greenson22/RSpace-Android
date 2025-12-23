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

  // State untuk filter tampilan hidden
  bool _showHidden = false;
  bool get showHidden => _showHidden;

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

  // Toggle untuk menampilkan/menyembunyikan item hidden secara global di UI
  void toggleShowHidden() {
    _showHidden = !_showHidden;
    notifyListeners();
  }

  // Fungsi untuk mengubah status hidden pada topik spesifik
  Future<void> toggleTopicVisibility(ProgressTopic topic) async {
    topic.isHidden = !topic.isHidden;
    await _progressService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> addTopic(String name) async {
    await _progressService.addTopic(name);
    await fetchTopics();
  }

  Future<void> reorderTopics(int oldIndex, int newIndex) async {
    final item = _topics.removeAt(oldIndex);
    _topics.insert(newIndex, item);

    await _progressService.saveTopicsOrder(_topics);
    notifyListeners();
  }

  Future<void> editTopic(ProgressTopic oldTopic, String newName) async {
    await _progressService.renameTopic(oldTopic, newName);
    await fetchTopics();
  }

  Future<void> editTopicIcon(ProgressTopic topic, String newIcon) async {
    topic.icon = newIcon;
    await _progressService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> deleteTopic(ProgressTopic topic) async {
    await _progressService.deleteTopic(topic);
    await fetchTopics();
  }
}
