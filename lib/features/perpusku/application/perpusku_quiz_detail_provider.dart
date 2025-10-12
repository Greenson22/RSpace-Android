// lib/features/perpusku/application/perpusku_quiz_detail_provider.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:my_aplication/features/perpusku/application/perpusku_quiz_service.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
// ==> IMPORT SERVICE DAN MODEL YANG DIPERLUKAN <==
import 'package:my_aplication/features/content_management/domain/services/discussion_service.dart';

class PerpuskuQuizDetailProvider with ChangeNotifier {
  final PerpuskuQuizService _quizService = PerpuskuQuizService();
  // ==> TAMBAHKAN DISCUSSION SERVICE <==
  final DiscussionService _discussionService = DiscussionService();
  final String relativeSubjectPath;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<QuizSet> _allQuizzesInSubject = [];
  List<QuizSet> get quizzes => _allQuizzesInSubject;

  PerpuskuQuizDetailProvider(this.relativeSubjectPath) {
    _loadAllQuizzes();
  }

  Future<void> _loadAllQuizzes() async {
    _isLoading = true;
    notifyListeners();
    _allQuizzesInSubject = await _quizService.loadQuizzes(relativeSubjectPath);
    _isLoading = false;
    notifyListeners();
  }

  /// Menambahkan pertanyaan dari string JSON ke dalam QuizSet tertentu.
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
      // Lemparkan kembali error untuk ditangani oleh UI
      rethrow;
    } finally {
      // Muat ulang data untuk memastikan UI terupdate
      await _loadAllQuizzes();
    }
  }

  // ==> FUNGSI BARU UNTUK MEMBUAT PROMPT <==
  Future<String> generatePromptFromRspaceSubject({
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
        'Subject R-Space ini tidak memiliki konten aktif untuk dibuatkan kuis.',
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
}
