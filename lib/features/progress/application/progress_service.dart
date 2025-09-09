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

    final List<ProgressTopic> topics = [];
    for (final file in files) {
      // ==> PERBAIKAN: Tambahkan kondisi untuk mengabaikan file palet
      if (path.basename(file.path) == 'custom_palettes.json') {
        continue; // Lewati file ini dan lanjutkan ke file berikutnya
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      topics.add(ProgressTopic.fromJson(jsonData));
    }
    return topics;
  }

  Future<void> saveTopic(ProgressTopic topic) async {
    final dirPath = await _progressPath;
    final fileName = '${topic.topics.replaceAll(' ', '_').toLowerCase()}.json';
    final file = File(path.join(dirPath, fileName));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(topic.toJson()));
  }

  Future<void> addTopic(String topicName) async {
    final newTopic = ProgressTopic(topics: topicName, subjects: []);
    await saveTopic(newTopic);
  }

  Future<void> deleteTopic(ProgressTopic topic) async {
    final dirPath = await _progressPath;
    final fileName = '${topic.topics.replaceAll(' ', '_').toLowerCase()}.json';
    final file = File(path.join(dirPath, fileName));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
