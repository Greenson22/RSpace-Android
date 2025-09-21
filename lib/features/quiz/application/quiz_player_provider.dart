// lib/features/quiz/application/quiz_player_provider.dart

import 'dart:async';
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

  Timer? _autoAdvanceTimer;
  Timer? _questionTimer;
  int _remainingTime = 0;
  int get remainingTime => _remainingTime;

  // ==> STATE BARU UNTUK TIMER KESELURUHAN
  Timer? _overallTimer;
  Duration _overallRemainingTime = Duration.zero;
  Duration get overallRemainingTime => _overallRemainingTime;

  int get score {
    int correctAnswers = 0;
    _userAnswers.forEach((questionId, selectedOption) {
      if (selectedOption != null && selectedOption.isCorrect) {
        correctAnswers++;
      }
    });
    return correctAnswers;
  }

  QuizPlayerProvider({required this.topic}) {
    _loadQuestions();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _questionTimer?.cancel();
    _overallTimer?.cancel(); // ==> BERSIHKAN TIMER
    super.dispose();
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    if (topic.isTimerEnabled) {
      _remainingTime = topic.timerDuration;
      notifyListeners();

      _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime > 0) {
          _remainingTime--;
          notifyListeners();
        } else {
          _handleTimeUp();
        }
      });
    }
  }

  // ==> FUNGSI BARU UNTUK MEMULAI TIMER KESELURUHAN
  void _startOverallTimer() {
    _overallTimer?.cancel();
    if (topic.isOverallTimerEnabled) {
      _overallRemainingTime = Duration(minutes: topic.overallTimerDuration);
      notifyListeners();

      _overallTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_overallRemainingTime.inSeconds > 0) {
          _overallRemainingTime -= const Duration(seconds: 1);
          notifyListeners();
        } else {
          // Waktu keseluruhan habis, akhiri kuis
          finishQuiz();
        }
      });
    }
  }

  void _handleTimeUp() {
    _questionTimer?.cancel();
    if (currentIndex < _questions.length - 1) {
      nextQuestion();
    } else {
      finishQuiz();
    }
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
      _startQuestionTimer();
      _startOverallTimer(); // ==> MULAI TIMER KESELURUHAN
    } catch (e) {
      _questions = [];
      _state = QuizState.finished;
    }
    notifyListeners();
  }

  void answerQuestion(QuizQuestion question, QuizOption option) {
    _questionTimer?.cancel();
    _userAnswers[question.id] = option;
    if (topic.showCorrectAnswer) {
      _revealedAnswers.add(question.id);
    }
    if (topic.autoAdvanceNextQuestion) {
      _autoAdvanceTimer?.cancel();
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
    _autoAdvanceTimer?.cancel();
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _startQuestionTimer();
      notifyListeners();
    }
  }

  void previousQuestion() {
    _autoAdvanceTimer?.cancel();
    if (_currentIndex > 0) {
      _currentIndex--;
      _startQuestionTimer();
      notifyListeners();
    }
  }

  void finishQuiz() {
    _autoAdvanceTimer?.cancel();
    _questionTimer?.cancel();
    _overallTimer?.cancel(); // ==> HENTIKAN TIMER KESELURUHAN
    _state = QuizState.finished;
    notifyListeners();
  }

  void restartQuiz() {
    _loadQuestions();
  }
}
