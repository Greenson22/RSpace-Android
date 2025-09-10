// lib/features/quiz/application/quiz_detail_provider.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_service.dart';
import 'package:my_aplication/features/content_management/domain/services/topic_service.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service.dart';
import '../domain/models/quiz_model.dart';
import 'quiz_service.dart';

class QuizDetailProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  final GeminiService _geminiService = GeminiService();
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();

  QuizTopic topic;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  QuizDetailProvider(this.topic);

  Future<void> addQuestionsFromSubject(String subjectJsonPath) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newQuestions = await _geminiService.generateQuizFromSubject(
        subjectJsonPath,
      );
      topic.questions.addAll(newQuestions);
      await _quizService.saveTopic(topic);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    topic.questions.removeWhere((q) => q.id == questionId);
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  // Fungsi untuk mendapatkan semua topik dan subjek untuk dialog pemilihan
  Future<Map<String, List<String>>> getTopicsAndSubjects() async {
    final topics = await _topicService.getTopics();
    // Anda bisa menambahkan logika untuk memuat subjek di sini
    // Untuk saat ini, kita akan memuatnya secara dinamis di dialog
    return {for (var v in topics) v.name: []};
  }
}
