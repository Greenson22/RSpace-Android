// lib/features/quiz/application/quiz_detail_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service.dart';
import 'quiz_service.dart';
import 'package:my_aplication/features/content_management/domain/services/discussion_service.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:uuid/uuid.dart';

class QuizDetailProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  final GeminiService _geminiService = GeminiService();
  final DiscussionService _discussionService = DiscussionService();

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
      topic = await _quizService.getTopic(topic.categoryName, topic.name);
      quizSets = await _quizService.getQuizSetsInTopic(
        topic.categoryName,
        topic.name,
      );

      if (topic.includedQuizSets.isEmpty && quizSets.isNotEmpty) {
        topic.includedQuizSets = quizSets.map((e) => e.name).toList();
        await _quizService.saveTopic(topic);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> generatePromptFromSubject({
    required String subjectJsonPath,
    required int questionCount,
    required QuizDifficulty difficulty,
  }) async {
    final discussions = await _discussionService.loadDiscussions(
      subjectJsonPath,
    );
    final contentBuffer = StringBuffer();
    for (final discussion in discussions) {
      if (!discussion.finished) {
        contentBuffer.writeln('- Judul: ${discussion.discussion}');
        for (final point in discussion.points) {
          contentBuffer.writeln('  - Poin: ${point.pointText}');
        }
      }
    }

    if (contentBuffer.isEmpty) {
      throw Exception(
        'Subject ini tidak memiliki konten aktif untuk dibuatkan kuis.',
      );
    }

    final prompt =
        '''
    Anda adalah AI pembuat kuis. Berdasarkan materi berikut:
    ---
    ${contentBuffer.toString()}
    ---
    
    Buatkan $questionCount pertanyaan kuis pilihan ganda yang relevan dengan tingkat kesulitan: ${difficulty.displayName}.
    Untuk tingkat kesulitan "HOTS", buatlah pertanyaan yang membutuhkan analisis atau penerapan konsep, bukan hanya ingatan.
    
    Aturan Jawaban:
    1.  HANYA kembalikan dalam format array JSON yang valid.
    2.  Setiap objek dalam array mewakili satu pertanyaan dan HARUS memiliki kunci: "questionText", "options", dan "correctAnswerIndex".
    3.  "questionText" harus berupa string.
    4.  "options" harus berupa array berisi 4 string pilihan jawaban.
    5.  "correctAnswerIndex" harus berupa integer (0-3) yang menunjuk ke jawaban yang benar.
    6.  Jangan sertakan penjelasan atau teks lain di luar array JSON.

    Contoh Jawaban:
    [
      {
        "questionText": "Apa itu widget dalam Flutter?",
        "options": ["Blok bangunan UI", "Tipe variabel", "Fungsi database", "Permintaan jaringan"],
        "correctAnswerIndex": 0
      }
    ]
    ''';
    return prompt;
  }

  Future<void> addQuizSetFromJson({
    required String quizSetName,
    required String jsonContent,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
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

      final newQuizSet = QuizSet(name: quizSetName, questions: newQuestions);
      await _quizService.saveQuizSet(
        topic.categoryName,
        topic.name,
        newQuizSet,
      );
      await fetchQuizSets();
    } catch (e) {
      throw Exception(
        'Gagal mem-parsing JSON. Pastikan formatnya benar. Error: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuestionsToQuizSetFromJson({
    required String quizSetName,
    required String jsonContent,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
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

      final existingSet = quizSets.firstWhere((qs) => qs.name == quizSetName);
      existingSet.questions.addAll(newQuestions);
      await _quizService.saveQuizSet(
        topic.categoryName,
        topic.name,
        existingSet,
      );
      await fetchQuizSets();
    } catch (e) {
      throw Exception(
        'Gagal mem-parsing JSON. Pastikan formatnya benar. Error: $e',
      );
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

      await _quizService.saveQuizSet(
        topic.categoryName,
        topic.name,
        newQuizSet,
      );
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

      await _quizService.saveQuizSet(
        topic.categoryName,
        topic.name,
        newQuizSet,
      );
      await fetchQuizSets();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuestionsToQuizSetFromSubject({
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
      await _quizService.saveQuizSet(
        topic.categoryName,
        topic.name,
        existingSet,
      );
      await fetchQuizSets();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuestion(
    QuizSet quizSet,
    String questionText,
    List<QuizOption> options,
  ) async {
    final newQuestion = QuizQuestion(
      questionText: questionText,
      options: options,
    );
    quizSet.questions.add(newQuestion);
    await _quizService.saveQuizSet(topic.categoryName, topic.name, quizSet);
    notifyListeners();
  }

  Future<void> updateQuestion(
    QuizSet quizSet,
    QuizQuestion question,
    String newText,
    List<QuizOption> newOptions,
  ) async {
    question.questionText = newText;
    question.options = newOptions;
    await _quizService.saveQuizSet(topic.categoryName, topic.name, quizSet);
    notifyListeners();
  }

  Future<void> deleteQuestion(QuizSet quizSet, QuizQuestion question) async {
    quizSet.questions.removeWhere((q) => q.id == question.id);
    await _quizService.saveQuizSet(topic.categoryName, topic.name, quizSet);
    notifyListeners();
  }

  Future<void> reorderQuestions(
    QuizSet quizSet,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = quizSet.questions.removeAt(oldIndex);
    quizSet.questions.insert(newIndex, item);
    await _quizService.saveQuizSet(topic.categoryName, topic.name, quizSet);
    notifyListeners();
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

  Future<void> updateTimerEnabled(bool value) async {
    topic.isTimerEnabled = value;
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> updateTimerDuration(int duration) async {
    topic.timerDuration = duration > 0 ? duration : 30;
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> updateOverallTimerEnabled(bool value) async {
    topic.isOverallTimerEnabled = value;
    await _quizService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> updateOverallTimerDuration(int duration) async {
    topic.overallTimerDuration = duration > 0 ? duration : 10;
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
    await _quizService.deleteQuizSet(
      topic.categoryName,
      topic.name,
      quizSetName,
    );
    await _quizService.saveTopic(topic);
    await fetchQuizSets();
  }
}
