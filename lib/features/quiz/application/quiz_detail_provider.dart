// lib/features/quiz/application/quiz_detail_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service.dart';
import 'quiz_service.dart';
// ==> IMPORT TAMBAHAN
import 'package:my_aplication/features/content_management/domain/services/discussion_service.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';

class QuizDetailProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  final GeminiService _geminiService = GeminiService();
  // ==> TAMBAHKAN DISCUSSION SERVICE
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
      // ==> PERUBAHAN DI SINI: Sertakan categoryName saat mengambil data topik
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

  // ==> FUNGSI BARU UNTUK MEMBUAT PROMPT
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

  // ==> FUNGSI BARU UNTUK IMPOR JSON
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

      // ==> PERUBAHAN DI SINI: Sertakan categoryName saat menyimpan
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

      // ==> PERUBAHAN DI SINI: Sertakan categoryName saat menyimpan
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

  // ==> UBAH NAMA FUNGSI INI AGAR LEBIH SPESIFIK
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
      // ==> PERUBAHAN DI SINI: Sertakan categoryName saat menyimpan
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
    // ==> PERUBAHAN DI SINI: Sertakan categoryName saat menghapus
    await _quizService.deleteQuizSet(
      topic.categoryName,
      topic.name,
      quizSetName,
    );
    await _quizService.saveTopic(topic);
    await fetchQuizSets();
  }
}
