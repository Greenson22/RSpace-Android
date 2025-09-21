// lib/features/perpusku/infrastructure/perpusku_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:path/path.dart' as path;
import '../domain/models/perpusku_models.dart';

class PerpuskuService {
  final PathService _pathService = PathService();
  static const String _defaultIcon = '📁'; // Default ikon jika config tidak ada

  Future<String> get _perpuskuBasePath async {
    final perpuskuDataPath = await _pathService.perpuskuDataPath;
    return path.join(perpuskuDataPath, 'file_contents', 'topics');
  }

  // >> FUNGSI INI DIPERBARUI TOTAL <<
  Future<List<PerpuskuTopic>> getTopics() async {
    final basePath = await _perpuskuBasePath;
    final directory = Directory(basePath);
    if (!await directory.exists()) {
      return [];
    }

    final entities = directory.listSync().whereType<Directory>().toList();
    final List<PerpuskuTopic> topics = [];

    for (final dir in entities) {
      final topicName = path.basename(dir.path);
      String topicIcon = _defaultIcon;

      // Coba baca file config dari direktori RSpace
      try {
        final configPath = await _pathService.getTopicConfigPath(topicName);
        final configFile = File(configPath);
        if (await configFile.exists()) {
          final jsonString = await configFile.readAsString();
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          topicIcon = jsonData['icon'] ?? _defaultIcon;
        }
      } catch (e) {
        // Abaikan jika gagal membaca, gunakan ikon default
      }

      topics.add(
        PerpuskuTopic(name: topicName, path: dir.path, icon: topicIcon),
      );
    }

    topics.sort((a, b) => a.name.compareTo(b.name));
    return topics;
  }

  Future<List<PerpuskuSubject>> getSubjects(String topicPath) async {
    final directory = Directory(topicPath);
    if (!await directory.exists()) {
      return [];
    }

    final entities = directory.listSync().whereType<Directory>().toList();
    return entities
        .map(
          (dir) =>
              PerpuskuSubject(name: path.basename(dir.path), path: dir.path),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<PerpuskuFile>> getFiles(String subjectPath) async {
    final directory = Directory(subjectPath);
    if (!await directory.exists()) {
      return [];
    }

    // Baca metadata untuk mendapatkan judul file
    final metadataFile = File(path.join(subjectPath, 'metadata.json'));
    Map<String, String> titles = {};
    if (await metadataFile.exists()) {
      final jsonString = await metadataFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final content = jsonData['content'] as List<dynamic>? ?? [];
      titles = {
        for (var item in content)
          item['nama_file'] as String: item['judul'] as String,
      };
    }

    final files = directory
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              file.path.toLowerCase().endsWith('.html') &&
              path.basename(file.path).toLowerCase() != 'index.html',
        )
        .toList();

    return files.map((file) {
      final fileName = path.basename(file.path);
      return PerpuskuFile(
        fileName: fileName,
        title: titles[fileName] ?? fileName,
        path: file.path,
      );
    }).toList()..sort((a, b) => a.title.compareTo(b.title));
  }
}
