// lib/features/quiz/application/quiz_detail_provider.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service.dart';
import '../domain/models/quiz_model.dart';
import 'quiz_service.dart';

class QuizDetailProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  final GeminiService _geminiService = GeminiService();

  QuizTopic topic;
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
      // Muat ulang data topik terbaru untuk mendapatkan setting terakhir
      topic = await _quizService.getTopic(topic.name);
      quizSets = await _quizService.getQuizSetsInTopic(topic.name);

      // Jika belum ada set yang dipilih, pilih semua secara default
      if (topic.includedQuizSets.isEmpty && quizSets.isNotEmpty) {
        topic.includedQuizSets = quizSets.map((e) => e.name).toList();
        await _quizService.saveTopic(topic);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==> FUNGSI DIPERBARUI UNTUK MENERIMA questionCount <==
  Future<void> addQuizSetFromSubject(
    String quizSetName,
    String subjectJsonPath,
    int questionCount,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      // ==> KIRIM questionCount KE SERVICE <==
      final newQuestions = await _geminiService.generateQuizFromSubject(
        subjectJsonPath,
        questionCount: questionCount,
      );
      final newQuizSet = QuizSet(name: quizSetName, questions: newQuestions);

      await _quizService.saveQuizSet(topic.name, newQuizSet);
      await fetchQuizSets(); // Muat ulang semua data
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==> FUNGSI BARU UNTUK MENGELOLA PENGATURAN <==

  Future<void> updateShuffle(bool value) async {
    topic.shuffleQuestions = value;
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> updateQuestionLimit(int limit) async {
    topic.questionLimit = limit;
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> toggleQuizSetInclusion(String quizSetName, bool include) async {
    final included = topic.includedQuizSets.toSet();
    if (include) {
      included.add(quizSetName);
    } else {
      included.remove(quizSetName);
    }
    topic.includedQuizSets = included.toList();
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> deleteQuizSet(String quizSetName) async {
    // TODO: Implementasi di QuizService untuk menghapus file JSON
    // await _quizService.deleteQuizSet(topic.name, quizSetName);
    await fetchQuizSets(); // Untuk sementara, cukup refresh
  }
}
