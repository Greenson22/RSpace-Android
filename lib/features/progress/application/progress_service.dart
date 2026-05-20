// lib/features/progress/application/progress_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import '../domain/models/progress_topic_model.dart';
import '../domain/models/progress_template_model.dart';

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

  // ==> BARU: Membaca daftar section kustom
  Future<List<String>> getTopicSections() async {
    final dirPath = await _progressPath;
    final file = File(path.join(dirPath, 'topic_sections.json'));
    if (!await file.exists()) return ['Umum'];

    try {
      final content = await file.readAsString();
      if (content.isEmpty) return ['Umum'];

      final List<dynamic> data = jsonDecode(content);
      return data.map((e) => e.toString()).toList();
    } catch (e) {
      return ['Umum'];
    }
  }

  // ==> BARU: Menyimpan daftar section kustom
  Future<void> saveTopicSections(List<String> sections) async {
    final dirPath = await _progressPath;
    final file = File(path.join(dirPath, 'topic_sections.json'));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(sections));
  }

  Future<List<ProgressTopic>> getAllTopics() async {
    final dirPath = await _progressPath;
    final directory = Directory(dirPath);
    final files = directory.listSync().whereType<File>().where(
      (file) => file.path.endsWith('.json'),
    );

    List<ProgressTopic> topics = [];
    for (final file in files) {
      final fileName = path.basename(file.path);

      // === Abaikan file konfigurasi lainnya ===
      if (fileName == 'custom_palettes.json' ||
          fileName == 'progress_templates.json' ||
          fileName == 'topic_sections.json') {
        continue;
      }

      try {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        topics.add(ProgressTopic.fromJson(jsonData));
      } catch (e) {
        print('Error parsing topic file $fileName: $e');
      }
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

  Future<void> addTopic(String topicName, {String section = 'Umum'}) async {
    final currentTopics = await getAllTopics();
    final newTopic = ProgressTopic(
      topics: topicName,
      subjects: [],
      position: currentTopics.length,
      section: section,
    );
    await saveTopic(newTopic);
  }

  Future<void> renameTopic(ProgressTopic oldTopic, String newName) async {
    final dirPath = await _progressPath;
    final oldFileName =
        '${oldTopic.topics.replaceAll(' ', '_').toLowerCase()}.json';
    final oldFile = File(path.join(dirPath, oldFileName));

    if (await oldFile.exists()) {
      oldTopic.topics = newName;
      await saveTopic(oldTopic);
      await oldFile.delete();
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

  Future<List<ProgressTemplate>> getTemplates() async {
    final dirPath = await _progressPath;
    final file = File(path.join(dirPath, 'progress_templates.json'));
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    if (content.isEmpty) return [];

    final List<dynamic> data = jsonDecode(content);
    return data.map((e) => ProgressTemplate.fromJson(e)).toList();
  }

  Future<void> saveTemplates(List<ProgressTemplate> templates) async {
    final dirPath = await _progressPath;
    final file = File(path.join(dirPath, 'progress_templates.json'));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      encoder.convert(templates.map((e) => e.toJson()).toList()),
    );
  }
}
