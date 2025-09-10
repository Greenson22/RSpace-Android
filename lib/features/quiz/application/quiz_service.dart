// lib/features/quiz/application/quiz_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import '../domain/models/quiz_model.dart';

class QuizService {
  final PathService _pathService = PathService();

  Future<String> get _quizPath async {
    final dirPath = await _pathService.quizPath;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dirPath;
  }

  Future<List<QuizTopic>> getAllTopics() async {
    final dirPath = await _quizPath;
    final directory = Directory(dirPath);
    final files = directory.listSync().whereType<File>().where(
      (file) => file.path.endsWith('.json'),
    );

    List<QuizTopic> topics = [];
    for (final file in files) {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      topics.add(QuizTopic.fromJson(jsonData));
    }

    // Logika untuk mengurutkan dan memperbaiki posisi (sama seperti ProgressService)
    final positionedTopics = topics.where((t) => t.position != -1).toList();
    final unpositionedTopics = topics.where((t) => t.position == -1).toList();

    positionedTopics.sort((a, b) => a.position.compareTo(b.position));

    int maxPosition = positionedTopics.isNotEmpty
        ? positionedTopics
              .map((t) => t.position)
              .reduce((a, b) => a > b ? a : b)
        : -1;

    for (final topic in unpositionedTopics) {
      maxPosition++;
      topic.position = maxPosition;
      await saveTopic(topic);
    }

    final allTopics = [...positionedTopics, ...unpositionedTopics];
    allTopics.sort((a, b) => a.position.compareTo(b.position));

    bool needsResave = false;
    for (int i = 0; i < allTopics.length; i++) {
      if (allTopics[i].position != i) {
        allTopics[i].position = i;
        needsResave = true;
      }
    }

    if (needsResave) {
      await saveTopicsOrder(allTopics);
    }

    return allTopics;
  }

  Future<void> saveTopicsOrder(List<QuizTopic> topics) async {
    for (int i = 0; i < topics.length; i++) {
      final topic = topics[i];
      topic.position = i;
      await saveTopic(topic);
    }
  }

  Future<void> saveTopic(QuizTopic topic) async {
    final dirPath = await _quizPath;
    final fileName = '${topic.title.replaceAll(' ', '_').toLowerCase()}.json';
    final file = File(path.join(dirPath, fileName));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(topic.toJson()));
  }

  Future<void> addTopic(String topicName) async {
    final currentTopics = await getAllTopics();
    final newTopic = QuizTopic(
      title: topicName,
      position: currentTopics.length,
    );
    await saveTopic(newTopic);
  }

  Future<void> renameTopic(QuizTopic oldTopic, String newName) async {
    final dirPath = await _quizPath;
    final oldFileName =
        '${oldTopic.title.replaceAll(' ', '_').toLowerCase()}.json';
    final oldFile = File(path.join(dirPath, oldFileName));

    if (await oldFile.exists()) {
      oldTopic.title = newName;
      await saveTopic(oldTopic);
      await oldFile.delete();
    } else {
      throw Exception("File kuis lama tidak ditemukan.");
    }
  }

  Future<void> deleteTopic(QuizTopic topic) async {
    final dirPath = await _quizPath;
    final fileName = '${topic.title.replaceAll(' ', '_').toLowerCase()}.json';
    final file = File(path.join(dirPath, fileName));
    if (await file.exists()) {
      await file.delete();
    }
    final remainingTopics = await getAllTopics();
    await saveTopicsOrder(remainingTopics);
  }
}
