// lib/features/perpusku/application/perpusku_quiz_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';

class PerpuskuQuizService {
  final PathService _pathService = PathService();

  /// Memuat semua QuizSet dari file quizzes.json di dalam subjek tertentu.
  Future<List<QuizSet>> loadQuizzes(String relativeSubjectPath) async {
    final file = await _pathService.getPerpuskuSubjectQuizFile(
      relativeSubjectPath,
    );
    if (!await file.exists()) {
      return []; // Kembalikan list kosong jika file belum ada
    }

    try {
      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      // ==> PERBAIKAN: Gunakan 'name' dari dalam JSON, bukan dari nama file <==
      return jsonList
          .map((json) => QuizSet.fromJson(json['name'], json))
          .toList();
    } catch (e) {
      // Jika ada error parsing, anggap saja file kosong
      return [];
    }
  }

  /// Menyimpan daftar QuizSet ke file quizzes.json.
  Future<void> saveQuizzes(
    String relativeSubjectPath,
    List<QuizSet> quizzes,
  ) async {
    final file = await _pathService.getPerpuskuSubjectQuizFile(
      relativeSubjectPath,
    );
    const encoder = JsonEncoder.withIndent('  ');
    // ==> PERBAIKAN: Sertakan 'name' di dalam JSON saat menyimpan <==
    final listJson = quizzes.map((quiz) {
      return {'name': quiz.name, ...quiz.toJson()};
    }).toList();
    await file.writeAsString(encoder.convert(listJson));
  }

  /// Menambahkan satu QuizSet baru ke dalam file quizzes.json.
  Future<void> addQuizSet(String relativeSubjectPath, String quizName) async {
    final currentQuizzes = await loadQuizzes(relativeSubjectPath);
    if (currentQuizzes.any((q) => q.name == quizName)) {
      throw Exception('Kuis dengan nama "$quizName" sudah ada di subjek ini.');
    }
    currentQuizzes.add(QuizSet(name: quizName, questions: []));
    await saveQuizzes(relativeSubjectPath, currentQuizzes);
  }
}
