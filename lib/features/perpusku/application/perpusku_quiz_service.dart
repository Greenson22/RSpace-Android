// lib/features/perpusku/application/perpusku_quiz_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import '../domain/models/quiz_model.dart';

class PerpuskuQuizService {
  final PathService _pathService = PathService();

  Future<List<QuizSet>> loadQuizzes(String relativeSubjectPath) async {
    final file = await _pathService.getPerpuskuSubjectQuizFile(
      relativeSubjectPath,
    );
    if (!await file.exists()) {
      return [];
    }

    try {
      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => QuizSet.fromJson(json['name'], json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveQuizzes(
    String relativeSubjectPath,
    List<QuizSet> quizzes,
  ) async {
    final file = await _pathService.getPerpuskuSubjectQuizFile(
      relativeSubjectPath,
    );
    const encoder = JsonEncoder.withIndent('  ');
    final listJson = quizzes.map((quiz) {
      return {'name': quiz.name, ...quiz.toJson()};
    }).toList();
    await file.writeAsString(encoder.convert(listJson));
  }

  Future<void> addQuizSet(String relativeSubjectPath, String quizName) async {
    final currentQuizzes = await loadQuizzes(relativeSubjectPath);
    if (currentQuizzes.any((q) => q.name == quizName)) {
      throw Exception('Kuis dengan nama "$quizName" sudah ada di subjek ini.');
    }
    currentQuizzes.add(QuizSet(name: quizName, questions: []));
    await saveQuizzes(relativeSubjectPath, currentQuizzes);
  }
}
