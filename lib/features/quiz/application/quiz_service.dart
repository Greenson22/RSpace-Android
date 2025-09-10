// lib/features/quiz/application/quiz_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import '../domain/models/quiz_model.dart';

class QuizService {
  final PathService _pathService = PathService();
  static const String _defaultIcon = '❓';
  static const String _configFile = 'quiz_topic_config.json';

  Future<String> get _quizPath async {
    final dirPath = await _pathService.quizPath;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dirPath;
  }

  Future<QuizTopic> getTopic(String topicName) async {
    final quizzesPath = await _quizPath;
    final topicPath = path.join(quizzesPath, topicName);
    final configFile = File(path.join(topicPath, _configFile));

    if (!await configFile.exists()) {
      throw Exception('File konfigurasi untuk $topicName tidak ditemukan.');
    }

    final configString = await configFile.readAsString();
    final configJson = jsonDecode(configString) as Map<String, dynamic>;

    // Asumsi ada file utama untuk pertanyaan, atau bisa dikembangkan lebih lanjut
    // Untuk saat ini, kita gabungkan saja dalam satu file config.
    final fullTopic = QuizTopic.fromJson({'name': topicName, ...configJson});

    return fullTopic;
  }

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
      topics.add(QuizTopic.fromConfig(name, config));
    }

    // ... (Logika sorting dan fixing posisi sama seperti sebelumnya) ...
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

  Future<void> saveTopicsOrder(List<QuizTopic> topics) async {
    for (int i = 0; i < topics.length; i++) {
      final topic = topics[i];
      topic.position = i;
      await _saveTopicConfig(topic);
    }
  }

  Future<Map<String, dynamic>> _getTopicConfig(String topicName) async {
    final quizzesPath = await _quizPath;
    final configPath = path.join(quizzesPath, topicName, _configFile);
    final configFile = File(configPath);

    if (await configFile.exists()) {
      try {
        final jsonString = await configFile.readAsString();
        if (jsonString.isNotEmpty) {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          // Pastikan ada data 'questions' di dalam config
          data['questions'] ??= [];
          return data;
        }
      } catch (e) {
        // Abaikan
      }
    }
    return {'icon': _defaultIcon, 'position': -1, 'questions': []};
  }

  // Helper diubah untuk menyimpan seluruh data topik (termasuk pertanyaan)
  Future<void> saveTopic(QuizTopic topic) async {
    final quizzesPath = await _quizPath;
    final configPath = path.join(quizzesPath, topic.name, _configFile);
    final configFile = File(configPath);
    try {
      if (!await configFile.parent.exists()) {
        await configFile.parent.create(recursive: true);
      }
      const encoder = JsonEncoder.withIndent('  ');
      await configFile.writeAsString(encoder.convert(topic.toFullJson()));
    } catch (e) {
      // Abaikan jika gagal menulis file
    }
  }

  Future<void> _saveTopicConfig(QuizTopic topic) async {
    // Membaca data yang ada untuk mempertahankan 'questions'
    final existingData = await _getTopicConfig(topic.name);
    final questions = existingData['questions'] ?? [];

    final configData = topic.toConfigJson();
    final fullData = {
      'name': topic.name,
      'metadata': configData,
      'questions': questions,
    };

    final quizzesPath = await _quizPath;
    final configPath = path.join(quizzesPath, topic.name, _configFile);
    final configFile = File(configPath);

    try {
      await configFile.create(recursive: true);
      const encoder = JsonEncoder.withIndent('  ');
      await configFile.writeAsString(encoder.convert(fullData));
    } catch (e) {
      // Handle error
    }
  }

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
        questions: [],
      );
      await saveTopic(
        newTopic,
      ); // Menggunakan saveTopic untuk membuat file config
    } catch (e) {
      throw Exception('Gagal membuat topik kuis: $e');
    }
  }

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
      // Baca semua data sebelum rename
      final fullTopicData = await getTopic(oldTopic.name);
      await oldDir.rename(newPath);
      // Buat objek baru dengan nama baru dan simpan kembali
      final newTopicData = QuizTopic(
        name: newName,
        icon: fullTopicData.icon,
        position: fullTopicData.position,
        questions: fullTopicData.questions,
      );
      await saveTopic(newTopicData);
    } catch (e) {
      throw Exception('Gagal mengubah nama topik kuis: $e');
    }
  }

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
