// lib/features/quiz/domain/models/quiz_model.dart

import 'package:uuid/uuid.dart';

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

class QuizTopic {
  String name;
  String icon;
  int position;
  List<QuizQuestion> questions;

  QuizTopic({
    required this.name,
    this.icon = '❓',
    this.position = -1,
    this.questions = const [],
  });

  factory QuizTopic.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final questionsList = json['questions'] as List? ?? [];
    final questions = questionsList
        .map((q) => QuizQuestion.fromJson(q))
        .toList();

    return QuizTopic(
      name: json['name'] as String? ?? 'Tanpa Nama', // Diambil dari nama folder
      icon: metadata['icon'] as String? ?? '❓',
      position: metadata['position'] as int? ?? -1,
      questions: questions,
    );
  }

  // Konstruktor khusus untuk membaca dari file config di service
  factory QuizTopic.fromConfig(String name, Map<String, dynamic> configJson) {
    return QuizTopic(
      name: name,
      icon: configJson['icon'] as String? ?? '❓',
      position: configJson['position'] as int? ?? -1,
      questions: [], // Pertanyaan akan dimuat terpisah
    );
  }

  Map<String, dynamic> toConfigJson() {
    return {'icon': icon, 'position': position};
  }

  Map<String, dynamic> toFullJson() {
    return {
      'name': name,
      'metadata': toConfigJson(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
