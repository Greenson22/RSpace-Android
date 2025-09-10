// lib/features/quiz/application/quiz_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/quiz_model.dart';
import 'quiz_service.dart';

class QuizProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<QuizTopic> _topics = [];
  List<QuizTopic> get topics => _topics;

  QuizProvider() {
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    _isLoading = true;
    notifyListeners();
    _topics = await _quizService.getAllTopics();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTopic(String name) async {
    await _quizService.addTopic(name);
    await fetchTopics();
  }

  Future<void> reorderTopics(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _topics.removeAt(oldIndex);
    _topics.insert(newIndex, item);

    await _quizService.saveTopicsOrder(_topics);
    notifyListeners();
  }

  Future<void> editTopic(QuizTopic oldTopic, String newName) async {
    await _quizService.renameTopic(oldTopic, newName);
    await fetchTopics();
  }

  Future<void> editTopicIcon(QuizTopic topic, String newIcon) async {
    topic.icon = newIcon;
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> deleteTopic(QuizTopic topic) async {
    await _quizService.deleteTopic(topic);
    await fetchTopics();
  }
}
