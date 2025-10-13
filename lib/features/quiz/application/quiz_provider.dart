// lib/features/perpusku/application/perpusku_quiz_provider.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/quiz/application/quiz_service.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';

class PerpuskuQuizProvider with ChangeNotifier {
  final PerpuskuQuizService _quizService = PerpuskuQuizService();
  final String relativeSubjectPath;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<QuizSet> _quizzes = [];
  List<QuizSet> get quizzes => _quizzes;

  PerpuskuQuizProvider(this.relativeSubjectPath) {
    loadQuizzes();
  }

  Future<void> loadQuizzes() async {
    _isLoading = true;
    notifyListeners();
    _quizzes = await _quizService.loadQuizzes(relativeSubjectPath);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addQuiz(String name) async {
    if (_quizzes.any((q) => q.name == name)) {
      throw Exception('Kuis dengan nama "$name" sudah ada.');
    }
    final newQuiz = QuizSet(name: name, questions: []);
    _quizzes.add(newQuiz);
    await _quizService.saveQuizzes(relativeSubjectPath, _quizzes);
    notifyListeners();
  }

  // Tambahkan fungsi edit, hapus, dll. di sini sesuai kebutuhan
}
