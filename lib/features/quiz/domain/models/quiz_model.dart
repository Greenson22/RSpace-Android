// lib/features/quiz/domain/models/quiz_model.dart

import 'package:uuid/uuid.dart';

//==> TAMBAHKAN ENUM BARU UNTUK TINGKAT KESULITAN <==
enum QuizDifficulty { ringan, medium, susah, hots }

//==> TAMBAHKAN FUNGSI HELPER UNTUK MENDAPATKAN NAMA YANG MUDAH DIBACA <==
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

// Model untuk Pilihan Jawaban (Tidak Berubah)
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

// Model untuk satu Pertanyaan (Tidak Berubah)
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

// Model untuk satu file JSON kuis (satu set kuis)
class QuizSet {
  String name; // Nama file JSON tanpa ekstensi
  List<QuizQuestion> questions;

  QuizSet({required this.name, this.questions = const []});

  factory QuizSet.fromJson(String name, Map<String, dynamic> json) {
    final questionsList = json['questions'] as List? ?? [];
    final questions = questionsList
        .map((q) => QuizQuestion.fromJson(q))
        .toList();
    return QuizSet(name: name, questions: questions);
  }

  Map<String, dynamic> toJson() {
    return {'questions': questions.map((q) => q.toJson()).toList()};
  }
}

class QuizTopic {
  String name;
  String icon;
  int position;
  String categoryName; // ==> FIELD BARU

  // Pengaturan Kuis
  bool shuffleQuestions;
  int questionLimit; // 0 berarti tanpa batas
  List<String> includedQuizSets; // Menyimpan nama file dari QuizSet
  bool showCorrectAnswer;
  bool autoAdvanceNextQuestion;
  int autoAdvanceDelay; // Dalam detik

  QuizTopic({
    required this.name,
    this.icon = '❓',
    this.position = -1,
    required this.categoryName, // ==> JADIKAN REQUIRED
    this.shuffleQuestions = true,
    this.questionLimit = 0,
    this.includedQuizSets = const [],
    this.showCorrectAnswer = false,
    this.autoAdvanceNextQuestion = false,
    this.autoAdvanceDelay = 2,
  });

  factory QuizTopic.fromConfig(
    String name,
    String categoryName,
    Map<String, dynamic> configJson,
  ) {
    return QuizTopic(
      name: name,
      categoryName: categoryName, // ==> TAMBAHKAN
      icon: configJson['icon'] as String? ?? '❓',
      position: configJson['position'] as int? ?? -1,
      shuffleQuestions: configJson['shuffleQuestions'] as bool? ?? true,
      questionLimit: configJson['questionLimit'] as int? ?? 0,
      includedQuizSets: List<String>.from(configJson['includedQuizSets'] ?? []),
      showCorrectAnswer: configJson['showCorrectAnswer'] as bool? ?? false,
      autoAdvanceNextQuestion:
          configJson['autoAdvanceNextQuestion'] as bool? ?? false,
      autoAdvanceDelay: configJson['autoAdvanceDelay'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toConfigJson() {
    return {
      'icon': icon,
      'position': position,
      'shuffleQuestions': shuffleQuestions,
      'questionLimit': questionLimit,
      'includedQuizSets': includedQuizSets,
      'showCorrectAnswer': showCorrectAnswer,
      'autoAdvanceNextQuestion': autoAdvanceNextQuestion,
      'autoAdvanceDelay': autoAdvanceDelay,
    };
  }

  Map<String, dynamic> toFullJson() {
    return {'name': name, 'metadata': toConfigJson()};
  }
}

// ==> KELAS BARU UNTUK KATEGORI
class QuizCategory {
  String name;
  String icon;
  int position;

  QuizCategory({required this.name, this.icon = '🗂️', this.position = -1});

  factory QuizCategory.fromJson(String name, Map<String, dynamic> json) {
    return QuizCategory(
      name: name,
      icon: json['icon'] as String? ?? '🗂️',
      position: json['position'] as int? ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {'icon': icon, 'position': position};
  }
}
