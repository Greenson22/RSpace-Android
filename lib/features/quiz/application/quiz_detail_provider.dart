// lib/features/quiz/application/quiz_detail_provider.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service.dart';
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
      topic = await _quizService.getTopic(topic.name);
      quizSets = await _quizService.getQuizSetsInTopic(topic.name);

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
    QuizDifficulty difficulty,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newQuestions = await _geminiService.generateQuizFromSubject(
        subjectJsonPath,
        questionCount: questionCount,
        difficulty: difficulty,
      );
      final newQuizSet = QuizSet(name: quizSetName, questions: newQuestions);

      await _quizService.saveQuizSet(topic.name, newQuizSet);
      await fetchQuizSets();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuizSetFromText({
    required String quizSetName,
    required String customTopic,
    required int questionCount,
    required QuizDifficulty difficulty,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newQuestions = await _geminiService.generateQuizFromText(
        customTopic,
        questionCount: questionCount,
        difficulty: difficulty,
      );
      final newQuizSet = QuizSet(name: quizSetName, questions: newQuestions);

      await _quizService.saveQuizSet(topic.name, newQuizSet);
      await fetchQuizSets();
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
    required QuizDifficulty difficulty,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newQuestions = await _geminiService.generateQuizFromSubject(
        subjectJsonPath,
        questionCount: questionCount,
        difficulty: difficulty,
      );

      final existingSet = quizSets.firstWhere((qs) => qs.name == quizSetName);
      existingSet.questions.addAll(newQuestions);
      await _quizService.saveQuizSet(topic.name, existingSet);
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

  Future<void> deleteQuizSet(String quizSetName) async {
    topic.includedQuizSets.remove(quizSetName);
    await _quizService.deleteQuizSet(topic.name, quizSetName);
    await _quizService.saveTopic(topic);
    await fetchQuizSets();
  }
}
