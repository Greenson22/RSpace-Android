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

  Future<void> addQuizSetFromSubject(
    String quizSetName,
    String subjectJsonPath,
    int questionCount,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
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

  Future<void> addQuestionsToQuizSet({
    required String quizSetName,
    required String subjectJsonPath,
    required int questionCount,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Generate pertanyaan baru
      final newQuestions = await _geminiService.generateQuizFromSubject(
        subjectJsonPath,
        questionCount: questionCount,
      );

      // 2. Muat set kuis yang ada
      final existingSet = quizSets.firstWhere((qs) => qs.name == quizSetName);

      // 3. Tambahkan pertanyaan baru ke daftar yang sudah ada
      existingSet.questions.addAll(newQuestions);

      // 4. Simpan kembali seluruh set kuis
      await _quizService.saveQuizSet(topic.name, existingSet);

      // 5. Muat ulang data untuk memperbarui UI
      await fetchQuizSets();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateShuffle(bool value) async {
    topic.shuffleQuestions = value;
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> updateShowCorrectAnswer(bool value) async {
    topic.showCorrectAnswer = value;
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> updateAutoAdvance(bool value) async {
    topic.autoAdvanceNextQuestion = value;
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> updateAutoAdvanceDelay(int delay) async {
    topic.autoAdvanceDelay = delay;
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

  // ==> PERBAIKI FUNGSI INI <==
  Future<void> deleteQuizSet(String quizSetName) async {
    // Hapus dari daftar inklusi di topik
    topic.includedQuizSets.remove(quizSetName);
    // Hapus file fisik
    await _quizService.deleteQuizSet(topic.name, quizSetName);
    // Simpan perubahan pada topik (daftar inklusi yang baru)
    await _quizService.saveTopic(topic);
    // Muat ulang data untuk memperbarui UI
    await fetchQuizSets();
  }
}
