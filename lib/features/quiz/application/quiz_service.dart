// lib/features/quiz/application/quiz_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import '../domain/models/quiz_model.dart';

class QuizService {
  final PathService _pathService = PathService();
  static const String _defaultIcon = '❓';

  // Helper untuk mendapatkan path folder utama kuis
  Future<String> get _quizPath async {
    final dirPath = await _pathService.quizPath;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dirPath;
  }

  // Fungsi diubah total untuk membaca, mengurutkan, dan memperbaiki posisi folder
  Future<List<QuizTopic>> getAllTopics() async {
    final quizzesPath = await _quizPath;
    final directory = Directory(quizzesPath);
    if (!await directory.exists()) {
      return [];
    }

    final folderNames = directory
        .listSync()
        .whereType<Directory>()
        .map((item) => path.basename(item.path))
        .toList();

    List<QuizTopic> topics = [];
    for (var name in folderNames) {
      final config = await _getTopicConfig(name);
      topics.add(
        QuizTopic(
          name: name,
          icon: config['icon'] as String? ?? _defaultIcon,
          position: config['position'] as int? ?? -1,
        ),
      );
    }

    // Logika untuk mengurutkan dan memperbaiki posisi (sama seperti TopicService)
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
      await _saveTopicConfig(topic);
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

  // Fungsi baru untuk menyimpan urutan semua topik
  Future<void> saveTopicsOrder(List<QuizTopic> topics) async {
    for (int i = 0; i < topics.length; i++) {
      final topic = topics[i];
      topic.position = i;
      await _saveTopicConfig(topic);
    }
  }

  // Helper untuk membaca file config dari dalam folder topik kuis
  Future<Map<String, dynamic>> _getTopicConfig(String topicName) async {
    final quizzesPath = await _quizPath;
    final configPath = path.join(quizzesPath, topicName, 'quiz_config.json');
    final configFile = File(configPath);

    if (await configFile.exists()) {
      try {
        final jsonString = await configFile.readAsString();
        if (jsonString.isNotEmpty) {
          return jsonDecode(jsonString) as Map<String, dynamic>;
        }
      } catch (e) {
        // Abaikan error dan gunakan config default
      }
    }
    return {'icon': _defaultIcon, 'position': -1};
  }

  // Helper untuk menyimpan file config di dalam folder topik kuis
  Future<void> _saveTopicConfig(QuizTopic topic) async {
    final quizzesPath = await _quizPath;
    final configPath = path.join(quizzesPath, topic.name, 'quiz_config.json');
    final configFile = File(configPath);
    try {
      await configFile.create(recursive: true);
      await configFile.writeAsString(jsonEncode(topic.toConfigJson()));
    } catch (e) {
      // Abaikan jika gagal menulis file
    }
  }

  // Fungsi diubah untuk membuat FOLDER baru
  Future<void> addTopic(String topicName) async {
    if (topicName.isEmpty)
      throw Exception('Nama topik kuis tidak boleh kosong.');
    final quizzesPath = await _quizPath;
    final newTopicPath = path.join(quizzesPath, topicName);
    final directory = Directory(newTopicPath);

    if (await directory.exists()) {
      throw Exception('Topik kuis dengan nama "$topicName" sudah ada.');
    }

    try {
      await directory.create();
      final currentTopics = await getAllTopics();
      final newTopic = QuizTopic(
        name: topicName,
        icon: _defaultIcon,
        position: currentTopics.length,
      );
      await _saveTopicConfig(newTopic);
    } catch (e) {
      throw Exception('Gagal membuat topik kuis: $e');
    }
  }

  // Fungsi diubah untuk me-rename FOLDER
  Future<void> renameTopic(QuizTopic oldTopic, String newName) async {
    if (newName.isEmpty) throw Exception('Nama baru tidak boleh kosong.');
    final quizzesPath = await _quizPath;
    final oldPath = path.join(quizzesPath, oldTopic.name);
    final newPath = path.join(quizzesPath, newName);

    final oldDir = Directory(oldPath);
    if (!await oldDir.exists()) {
      throw Exception('Topik kuis yang ingin diubah tidak ditemukan.');
    }
    if (await Directory(newPath).exists()) {
      throw Exception('Topik kuis dengan nama "$newName" sudah ada.');
    }
    try {
      final oldConfig = await _getTopicConfig(oldTopic.name);
      await oldDir.rename(newPath);
      final newTopic = QuizTopic(
        name: newName,
        icon: oldConfig['icon'] as String? ?? _defaultIcon,
        position: oldConfig['position'] as int? ?? -1,
      );
      await _saveTopicConfig(newTopic);
    } catch (e) {
      throw Exception('Gagal mengubah nama topik kuis: $e');
    }
  }

  // Fungsi diubah untuk menghapus FOLDER
  Future<void> deleteTopic(QuizTopic topic) async {
    final quizzesPath = await _quizPath;
    final topicPath = path.join(quizzesPath, topic.name);
    final directory = Directory(topicPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    final remainingTopics = await getAllTopics();
    await saveTopicsOrder(remainingTopics);
  }
}
