// lib/features/perpusku/domain/models/quiz_model.dart

import 'package:uuid/uuid.dart';

enum QuizDifficulty { ringan, medium, susah, hots }

extension QuizDifficultyExtension on QuizDifficulty {
  String get displayName {
    switch (this) {
      case QuizDifficulty.ringan:
        return 'Ringan';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.susah:
        return 'Susah';
      case QuizDifficulty.hots:
        return 'HOTS';
    }
  }
}

class QuizOption {
  String text;
  bool isCorrect;

  QuizOption({required this.text, this.isCorrect = false});

  factory QuizOption.fromJson(Map<String, dynamic> json) => QuizOption(
    text: json['text'] as String,
    isCorrect: json['isCorrect'] as bool,
  );

  Map<String, dynamic> toJson() => {'text': text, 'isCorrect': isCorrect};
}

class QuizQuestion {
  final String id;
  String questionText;
  List<QuizOption> options;

  QuizQuestion({String? id, required this.questionText, required this.options})
    : id = id ?? const Uuid().v4();

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    var optionsList = json['options'] as List;
    List<QuizOption> options = optionsList
        .map((i) => QuizOption.fromJson(i))
        .toList();

    return QuizQuestion(
      id: json['id'] as String? ?? const Uuid().v4(),
      questionText: json['questionText'] as String,
      options: options,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionText': questionText,
    'options': options.map((o) => o.toJson()).toList(),
  };
}

class QuizSet {
  String name;
  List<QuizQuestion> questions;

  bool shuffleQuestions;
  int questionLimit;
  bool showCorrectAnswer;
  bool autoAdvanceNextQuestion;
  int autoAdvanceDelay;
  bool isTimerEnabled;
  int timerDuration;
  bool isOverallTimerEnabled;
  int overallTimerDuration;

  QuizSet({
    required this.name,
    this.questions = const [],
    this.shuffleQuestions = true,
    this.questionLimit = 0,
    this.showCorrectAnswer = true,
    this.autoAdvanceNextQuestion = true,
    this.autoAdvanceDelay = 2,
    this.isTimerEnabled = false,
    this.timerDuration = 30,
    this.isOverallTimerEnabled = false,
    this.overallTimerDuration = 10,
  });

  factory QuizSet.fromJson(String name, Map<String, dynamic> json) {
    final questionsList = json['questions'] as List? ?? [];
    final questions = questionsList
        .map((q) => QuizQuestion.fromJson(q))
        .toList();
    return QuizSet(
      name: name,
      questions: questions,
      shuffleQuestions: json['shuffleQuestions'] as bool? ?? true,
      questionLimit: json['questionLimit'] as int? ?? 0,
      showCorrectAnswer: json['showCorrectAnswer'] as bool? ?? true,
      autoAdvanceNextQuestion: json['autoAdvanceNextQuestion'] as bool? ?? true,
      autoAdvanceDelay: json['autoAdvanceDelay'] as int? ?? 2,
      isTimerEnabled: json['isTimerEnabled'] as bool? ?? false,
      timerDuration: json['timerDuration'] as int? ?? 30,
      isOverallTimerEnabled: json['isOverallTimerEnabled'] as bool? ?? false,
      overallTimerDuration: json['overallTimerDuration'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questions': questions.map((q) => q.toJson()).toList(),
      'shuffleQuestions': shuffleQuestions,
      'questionLimit': questionLimit,
      'showCorrectAnswer': showCorrectAnswer,
      'autoAdvanceNextQuestion': autoAdvanceNextQuestion,
      'autoAdvanceDelay': autoAdvanceDelay,
      'isTimerEnabled': isTimerEnabled,
      'timerDuration': timerDuration,
      'isOverallTimerEnabled': isOverallTimerEnabled,
      'overallTimerDuration': overallTimerDuration,
    };
  }

  QuizTopic toQuizTopic(String categoryName) {
    return QuizTopic(
      name: name,
      categoryName: categoryName,
      shuffleQuestions: shuffleQuestions,
      questionLimit: questionLimit,
      showCorrectAnswer: showCorrectAnswer,
      autoAdvanceNextQuestion: autoAdvanceNextQuestion,
      autoAdvanceDelay: autoAdvanceDelay,
      isTimerEnabled: isTimerEnabled,
      timerDuration: timerDuration,
      isOverallTimerEnabled: isOverallTimerEnabled,
      overallTimerDuration: overallTimerDuration,
    );
  }
}

// NOTE: QuizTopic dan QuizCategory tidak lagi digunakan oleh Kuis v2
//       dan dapat dihapus jika Anda sudah yakin tidak ada referensi lain.
//       Untuk saat ini, saya biarkan untuk menjaga kompatibilitas sementara.
class QuizTopic {
  String name;
  String categoryName;
  bool shuffleQuestions;
  int questionLimit;
  bool showCorrectAnswer;
  bool autoAdvanceNextQuestion;
  int autoAdvanceDelay;
  bool isTimerEnabled;
  int timerDuration;
  bool isOverallTimerEnabled;
  int overallTimerDuration;

  QuizTopic({
    required this.name,
    required this.categoryName,
    this.shuffleQuestions = true,
    this.questionLimit = 0,
    this.showCorrectAnswer = false,
    this.autoAdvanceNextQuestion = false,
    this.autoAdvanceDelay = 2,
    this.isTimerEnabled = false,
    this.timerDuration = 30,
    this.isOverallTimerEnabled = false,
    this.overallTimerDuration = 10,
  });
}
