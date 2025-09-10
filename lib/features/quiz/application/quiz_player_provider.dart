// lib/features/quiz/application/quiz_player_provider.dart

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

  Future<void> _loadQuestions() async {
    _state = QuizState.loading;
    notifyListeners();

    try {
      // Service akan menangani logika shuffle, limit, dan filter set kuis
      _questions = await _quizService.getAllQuestionsInTopic(topic);

      _userAnswers.clear();
      _currentIndex = 0;
      _state = QuizState.playing;
    } catch (e) {
      _questions = [];
      _state = QuizState.finished; // Atau bisa juga state error
    }
    notifyListeners();
  }

  void answerQuestion(QuizQuestion question, QuizOption option) {
    _userAnswers[question.id] = option;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void finishQuiz() {
    _state = QuizState.finished;
    notifyListeners();
  }

  void restartQuiz() {
    _loadQuestions();
  }
}
