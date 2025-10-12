// lib/features/perpusku/application/perpusku_quiz_detail_provider.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_aplication/features/perpusku/application/perpusku_quiz_service.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';

class PerpuskuQuizDetailProvider with ChangeNotifier {
  final PerpuskuQuizService _quizService = PerpuskuQuizService();
  final String relativeSubjectPath;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<QuizSet> _allQuizzesInSubject = [];
  List<QuizSet> get quizzes => _allQuizzesInSubject;

  PerpuskuQuizDetailProvider(this.relativeSubjectPath) {
    _loadAllQuizzes();
  }

  Future<void> _loadAllQuizzes() async {
    _isLoading = true;
    notifyListeners();
    _allQuizzesInSubject = await _quizService.loadQuizzes(relativeSubjectPath);
    _isLoading = false;
    notifyListeners();
  }

  /// Menambahkan pertanyaan dari string JSON ke dalam QuizSet tertentu.
  Future<void> addQuestionsFromJson({
    required String quizSetName,
    required String jsonContent,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final quizSetIndex = _allQuizzesInSubject.indexWhere(
        (q) => q.name == quizSetName,
      );
      if (quizSetIndex == -1) {
        throw Exception('QuizSet dengan nama "$quizSetName" tidak ditemukan.');
      }

      final List<dynamic> jsonResponse = jsonDecode(jsonContent);
      final newQuestions = jsonResponse.map((item) {
        final optionsList = (item['options'] as List<dynamic>).cast<String>();
        final correctIndex = item['correctAnswerIndex'] as int;
        final options = List.generate(optionsList.length, (i) {
          return QuizOption(text: optionsList[i], isCorrect: i == correctIndex);
        });
        return QuizQuestion(
          questionText: item['questionText'] as String,
          options: options,
        );
      }).toList();

      _allQuizzesInSubject[quizSetIndex].questions.addAll(newQuestions);
      await _quizService.saveQuizzes(relativeSubjectPath, _allQuizzesInSubject);
    } catch (e) {
      // Lemparkan kembali error untuk ditangani oleh UI
      rethrow;
    } finally {
      // Muat ulang data untuk memastikan UI terupdate
      await _loadAllQuizzes();
    }
  }
}
