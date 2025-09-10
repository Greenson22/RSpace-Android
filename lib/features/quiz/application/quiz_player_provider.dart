// lib/features/quiz/application/quiz_player_provider.dart

import 'dart:async'; // ==> IMPORT TIMER
import 'package:flutter/material.dart';
import '../domain/models/quiz_model.dart';
import 'quiz_service.dart';

enum QuizState { loading, playing, finished }

class QuizPlayerProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  final QuizTopic topic;

  QuizState _state = QuizState.loading;
  QuizState get state => _state;

  List<QuizQuestion> _questions = [];
  List<QuizQuestion> get questions => _questions;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final Map<String, QuizOption?> _userAnswers = {};
  Map<String, QuizOption?> get userAnswers => _userAnswers;

  final Set<String> _revealedAnswers = {};
  bool isAnswerRevealed(String questionId) =>
      _revealedAnswers.contains(questionId);

  // ==> TAMBAHKAN TIMER DI SINI
  Timer? _autoAdvanceTimer;

  int get score {
    int correctAnswers = 0;
    _userAnswers.forEach((questionId, selectedOption) {
      if (selectedOption != null && selectedOption.isCorrect) {
        correctAnswers++;
      }
    });
    return correctAnswers;
  }

  QuizPlayerProvider({required this.topic, required String topicName}) {
    _loadQuestions();
  }

  // ==> JANGAN LUPA BERSIHKAN TIMER SAAT PROVIDER DIHAPUS
  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    _state = QuizState.loading;
    notifyListeners();

    try {
      _questions = await _quizService.getAllQuestionsInTopic(topic);
      _userAnswers.clear();
      _revealedAnswers.clear();
      _currentIndex = 0;
      _state = QuizState.playing;
    } catch (e) {
      _questions = [];
      _state = QuizState.finished;
    }
    notifyListeners();
  }

  void answerQuestion(QuizQuestion question, QuizOption option) {
    _userAnswers[question.id] = option;
    if (topic.showCorrectAnswer) {
      _revealedAnswers.add(question.id);
    }
    // ==> LOGIKA AUTO-ADVANCE
    if (topic.autoAdvanceNextQuestion) {
      _autoAdvanceTimer?.cancel(); // Batalkan timer sebelumnya jika ada
      _autoAdvanceTimer = Timer(Duration(seconds: topic.autoAdvanceDelay), () {
        if (currentIndex < _questions.length - 1) {
          nextQuestion();
        } else {
          finishQuiz();
        }
      });
    }
    notifyListeners();
  }

  void nextQuestion() {
    _autoAdvanceTimer?.cancel(); // Batalkan timer saat pindah manual
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    _autoAdvanceTimer?.cancel(); // Batalkan timer saat pindah manual
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void finishQuiz() {
    _autoAdvanceTimer?.cancel(); // Batalkan timer
    _state = QuizState.finished;
    notifyListeners();
  }

  void restartQuiz() {
    _loadQuestions();
  }
}
