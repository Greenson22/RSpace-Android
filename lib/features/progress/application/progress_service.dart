// lib/features/progress/application/progress_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import '../domain/models/progress_topic_model.dart';

class ProgressService {
  final PathService _pathService = PathService();

  Future<String> get _progressPath async {
    final dirPath = await _pathService.progressPath;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dirPath;
  }

  Future<List<ProgressTopic>> getAllTopics() async {
    final dirPath = await _progressPath;
    final directory = Directory(dirPath);
    final files = directory.listSync().whereType<File>().where(
      (file) => file.path.endsWith('.json'),
    );

    List<ProgressTopic> topics = [];
    for (final file in files) {
      if (path.basename(file.path) == 'custom_palettes.json') {
        continue;
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      topics.add(ProgressTopic.fromJson(jsonData));
    }

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

  Future<void> saveTopicsOrder(List<ProgressTopic> topics) async {
    for (int i = 0; i < topics.length; i++) {
      final topic = topics[i];
      topic.position = i;
      await saveTopic(topic);
    }
  }

  Future<void> saveTopic(ProgressTopic topic) async {
    final dirPath = await _progressPath;
    final fileName = '${topic.topics.replaceAll(' ', '_').toLowerCase()}.json';
    final file = File(path.join(dirPath, fileName));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(topic.toJson()));
  }

  Future<void> addTopic(String topicName) async {
    final currentTopics = await getAllTopics();
    final newTopic = ProgressTopic(
      topics: topicName,
      subjects: [],
      position: currentTopics.length,
    );
    await saveTopic(newTopic);
  }

  // Fungsi baru untuk mengubah nama file dan isinya
  Future<void> renameTopic(ProgressTopic oldTopic, String newName) async {
    final dirPath = await _progressPath;
    final oldFileName =
        '${oldTopic.topics.replaceAll(' ', '_').toLowerCase()}.json';
    final oldFile = File(path.join(dirPath, oldFileName));

    if (await oldFile.exists()) {
      oldTopic.topics = newName; // Update nama di dalam objek
      await saveTopic(
        oldTopic,
      ); // Simpan ke file baru (saveTopic akan membuat nama file baru)
      await oldFile.delete(); // Hapus file lama
    } else {
      throw Exception("File topik lama tidak ditemukan.");
    }
  }

  Future<void> deleteTopic(ProgressTopic topic) async {
    final dirPath = await _progressPath;
    final fileName = '${topic.topics.replaceAll(' ', '_').toLowerCase()}.json';
    final file = File(path.join(dirPath, fileName));
    if (await file.exists()) {
      await file.delete();
    }
    final remainingTopics = await getAllTopics();
    await saveTopicsOrder(remainingTopics);
  }
}
