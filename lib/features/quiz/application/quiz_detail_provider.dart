// lib/features/quiz/application/quiz_detail_provider.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_aplication/features/quiz/application/quiz_service.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service_flutter_gemini.dart';
import '../domain/models/quiz_model.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:html/parser.dart' show parse;
import 'package:my_aplication/features/content_management/domain/services/discussion_service.dart';
// ==> IMPORT BARU
import 'package:my_aplication/features/settings/application/gemini_settings_service.dart';
import 'package:my_aplication/features/settings/domain/models/gemini_settings_model.dart';

class QuizDetailProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  final DiscussionService _discussionService = DiscussionService();
  final PathService _pathService = PathService();
  final GeminiServiceFlutterGemini _geminiService =
      GeminiServiceFlutterGemini();
  final String relativeSubjectPath;

  // ==> SERVICE BARU & STATE UNTUK PENGATURAN
  final GeminiSettingsService _settingsService = GeminiSettingsService();
  GeminiSettings? _geminiSettings;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<QuizSet> _allQuizzesInSubject = [];
  List<QuizSet> get quizzes => _allQuizzesInSubject;

  // ==> GETTER BARU UNTUK MENGAKSES PENGATURAN
  Future<GeminiSettings> get geminiSettings async {
    _geminiSettings ??= await _settingsService.loadSettings();
    return _geminiSettings!;
  }

  QuizDetailProvider(this.relativeSubjectPath) {
    _loadAllQuizzes();
  }

  Future<void> _loadAllQuizzes() async {
    _isLoading = true;
    notifyListeners();
    _allQuizzesInSubject = await _quizService.loadQuizzes(relativeSubjectPath);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateQuizSetSettings(
    QuizSet quizSet, {
    bool? shuffleQuestions,
    int? questionLimit,
    bool? showCorrectAnswer,
    bool? autoAdvanceNextQuestion,
    int? autoAdvanceDelay,
    bool? isTimerEnabled,
    int? timerDuration,
    bool? isOverallTimerEnabled,
    int? overallTimerDuration,
  }) async {
    final quizToUpdate = _allQuizzesInSubject.firstWhere(
      (q) => q.name == quizSet.name,
    );

    quizToUpdate.shuffleQuestions =
        shuffleQuestions ?? quizToUpdate.shuffleQuestions;
    quizToUpdate.questionLimit = questionLimit ?? quizToUpdate.questionLimit;
    quizToUpdate.showCorrectAnswer =
        showCorrectAnswer ?? quizToUpdate.showCorrectAnswer;
    quizToUpdate.autoAdvanceNextQuestion =
        autoAdvanceNextQuestion ?? quizToUpdate.autoAdvanceNextQuestion;
    quizToUpdate.autoAdvanceDelay =
        autoAdvanceDelay ?? quizToUpdate.autoAdvanceDelay;
    quizToUpdate.isTimerEnabled = isTimerEnabled ?? quizToUpdate.isTimerEnabled;
    quizToUpdate.timerDuration = timerDuration ?? quizToUpdate.timerDuration;
    quizToUpdate.isOverallTimerEnabled =
        isOverallTimerEnabled ?? quizToUpdate.isOverallTimerEnabled;
    quizToUpdate.overallTimerDuration =
        overallTimerDuration ?? quizToUpdate.overallTimerDuration;

    await _quizService.saveQuizzes(relativeSubjectPath, _allQuizzesInSubject);
    notifyListeners();
  }

  Future<void> addQuestionsFromJson({
    required String quizSetName,
    required String jsonContent,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final quizSetIndex = _allQuizzesInSubject.indexWhere(
        (q) => q.name == quizSetName,
      );
      if (quizSetIndex == -1) {
        throw Exception('QuizSet dengan nama "$quizSetName" tidak ditemukan.');
      }

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

      _allQuizzesInSubject[quizSetIndex].questions.addAll(newQuestions);
      await _quizService.saveQuizzes(relativeSubjectPath, _allQuizzesInSubject);
    } catch (e) {
      rethrow;
    } finally {
      await _loadAllQuizzes();
    }
  }

  Future<String> _buildQuizContextFromRspace(String subjectJsonPath) async {
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
        'Subject R-Space ini tidak memiliki konten aktif untuk dibuatkan kuis.',
      );
    }
    return contentBuffer.toString();
  }

  Future<String> _buildQuizContextFromHtml(
    String relativeHtmlPath,
    String discussionTitle,
  ) async {
    final file = await _pathService.getHtmlFile(relativeHtmlPath);
    if (!await file.exists()) {
      throw Exception('File HTML tidak ditemukan di path: $relativeHtmlPath');
    }
    final htmlContent = await file.readAsString();
    final document = parse(htmlContent);
    final String textContent = document.body?.text.trim() ?? '';
    if (textContent.isEmpty) {
      throw Exception(
        'File HTML tidak memiliki konten teks untuk dibuatkan kuis.',
      );
    }
    return 'Judul Materi: $discussionTitle\nIsi Teks:\n$textContent';
  }

  Future<String> generatePromptFromRspaceSubject({
    required String subjectJsonPath,
    required int questionCount,
    required QuizDifficulty difficulty,
  }) async {
    final context = await _buildQuizContextFromRspace(subjectJsonPath);
    final prompt =
        '''
    Anda adalah AI pembuat kuis. Berdasarkan konteks materi berikut:
    ---
    $context
    ---

    Buatkan $questionCount pertanyaan kuis pilihan ganda yang relevan dengan tingkat kesulitan: ${difficulty.displayName}.
    Untuk tingkat kesulitan "HOTS", buatlah pertanyaan yang membutuhkan analisis atau penerapan konsep, bukan hanya ingatan.

    Aturan Jawaban SANGAT PENTING:
    1.  Jawaban Anda HARUS HANYA berupa array JSON yang valid, tidak ada teks lain.
    2.  Setiap objek dalam array mewakili satu pertanyaan dan HARUS memiliki kunci: "questionText", "options", dan "correctAnswerIndex".
    3.  "questionText" harus berupa string.
    4.  "options" harus berupa array berisi 4 string pilihan jawaban.
    5.  "correctAnswerIndex" harus berupa integer (0-3) yang menunjuk ke jawaban yang benar.
    6.  Jangan sertakan markdown seperti ```json di awal atau akhir.

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

  Future<String> generatePromptFromHtmlDiscussion({
    required String relativeHtmlPath,
    required String discussionTitle,
    required int questionCount,
    required QuizDifficulty difficulty,
  }) async {
    final context = await _buildQuizContextFromHtml(
      relativeHtmlPath,
      discussionTitle,
    );
    final prompt =
        '''
    Anda adalah AI pembuat kuis. Berdasarkan konteks materi berikut:
    ---
    $context
    ---

    Buatkan $questionCount pertanyaan kuis pilihan ganda yang relevan dengan tingkat kesulitan: ${difficulty.displayName}.
    Untuk tingkat kesulitan "HOTS", buatlah pertanyaan yang membutuhkan analisis atau penerapan konsep, bukan hanya ingatan.

    Aturan Jawaban SANGAT PENTING:
    1.  Jawaban Anda HARUS HANYA berupa array JSON yang valid, tidak ada teks lain.
    2.  Setiap objek dalam array mewakili satu pertanyaan dan HARUS memiliki kunci: "questionText", "options", dan "correctAnswerIndex".
    3.  "questionText" harus berupa string.
    4.  "options" harus berupa array berisi 4 string pilihan jawaban.
    5.  "correctAnswerIndex" harus berupa integer (0-3) yang menunjuk ke jawaban yang benar.
    6.  Jangan sertakan markdown seperti ```json di awal atau akhir.

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

  Future<void> generateAndAddQuestionsFromRspaceSubject({
    required String quizSetName,
    required String subjectJsonPath,
    required int questionCount,
    required QuizDifficulty difficulty,
  }) async {
    final context = await _buildQuizContextFromRspace(subjectJsonPath);
    final newQuestions = await _geminiService.generateQuizQuestions(
      context: context,
      questionCount: questionCount,
      difficulty: difficulty,
    );

    final quizSetIndex = _allQuizzesInSubject.indexWhere(
      (q) => q.name == quizSetName,
    );
    if (quizSetIndex == -1) {
      throw Exception('Kuis "$quizSetName" tidak ditemukan.');
    }
    _allQuizzesInSubject[quizSetIndex].questions.addAll(newQuestions);
    await _quizService.saveQuizzes(relativeSubjectPath, _allQuizzesInSubject);
    await _loadAllQuizzes();
  }

  Future<void> generateAndAddQuestionsFromHtmlDiscussion({
    required String quizSetName,
    required String relativeHtmlPath,
    required String discussionTitle,
    required int questionCount,
    required QuizDifficulty difficulty,
  }) async {
    final context = await _buildQuizContextFromHtml(
      relativeHtmlPath,
      discussionTitle,
    );
    final newQuestions = await _geminiService.generateQuizQuestions(
      context: context,
      questionCount: questionCount,
      difficulty: difficulty,
    );

    final quizSetIndex = _allQuizzesInSubject.indexWhere(
      (q) => q.name == quizSetName,
    );
    if (quizSetIndex == -1) {
      throw Exception('Kuis "$quizSetName" tidak ditemukan.');
    }
    _allQuizzesInSubject[quizSetIndex].questions.addAll(newQuestions);
    await _quizService.saveQuizzes(relativeSubjectPath, _allQuizzesInSubject);
    await _loadAllQuizzes();
  }
}
