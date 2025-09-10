// lib/features/quiz/application/quiz_detail_provider.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service.dart';
import '../domain/models/quiz_model.dart';
import 'quiz_service.dart';

class QuizDetailProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  final GeminiService _geminiService = GeminiService();

  final QuizTopic topic;
  List<QuizSet> quizSets = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  QuizDetailProvider(this.topic) {
    fetchQuizSets();
  }

  Future<void> fetchQuizSets() async {
    _isLoading = true;
    notifyListeners();
    try {
      quizSets = await _quizService.getQuizSetsInTopic(topic.name);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuizSetFromSubject(
    String quizSetName,
    String subjectJsonPath,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newQuestions = await _geminiService.generateQuizFromSubject(
        subjectJsonPath,
      );
      final newQuizSet = QuizSet(name: quizSetName, questions: newQuestions);

      // Simpan file quiz set yang baru
      await _quizService.saveQuizSet(topic.name, newQuizSet);
      // Muat ulang daftar kuis
      await fetchQuizSets();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteQuizSet(String quizSetName) async {
    // Logika untuk menghapus file quiz set akan ditambahkan di QuizService
    // Untuk saat ini, kita refresh state-nya
    quizSets.removeWhere((qs) => qs.name == quizSetName);
    // await _quizService.deleteQuizSet(topic.name, quizSetName); // (Fungsi ini perlu dibuat di service)
    notifyListeners();
  }
}
