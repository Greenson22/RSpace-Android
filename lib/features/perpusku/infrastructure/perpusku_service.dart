// lib/features/perpusku/infrastructure/perpusku_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:path/path.dart' as path;
import '../domain/models/perpusku_models.dart';

class PerpuskuService {
  final PathService _pathService = PathService();
  static const String _defaultIcon = '📁';
  static const String _defaultSubjectIcon = '📄';

  Future<String> get _perpuskuBasePath async {
    final perpuskuDataPath = await _pathService.perpuskuDataPath;
    return path.join(perpuskuDataPath, 'file_contents', 'topics');
  }

  Future<List<PerpuskuFile>> searchFilesInTopic(
    String topicPath,
    String query,
  ) async {
    final List<PerpuskuFile> results = [];
    final topicDir = Directory(topicPath);
    final lowerCaseQuery = query.toLowerCase();

    if (!await topicDir.exists()) return [];

    final subjectDirs = topicDir.listSync().whereType<Directory>();

    for (final subjectDir in subjectDirs) {
      final metadataFile = File(path.join(subjectDir.path, 'metadata.json'));
      Map<String, String> currentTitles = {};
      if (await metadataFile.exists()) {
        final jsonString = await metadataFile.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        final content = jsonData['content'] as List<dynamic>? ?? [];
        currentTitles = {
          for (var item in content)
            item['nama_file'] as String: item['judul'] as String,
        };
      }

      final htmlFiles = subjectDir.listSync().whereType<File>().where(
        (f) => f.path.toLowerCase().endsWith('.html'),
      );

      for (final file in htmlFiles) {
        final fileName = path.basename(file.path);
        final title = currentTitles[fileName] ?? fileName;

        if (fileName.toLowerCase().contains(lowerCaseQuery) ||
            title.toLowerCase().contains(lowerCaseQuery)) {
          results.add(
            PerpuskuFile(fileName: fileName, title: title, path: file.path),
          );
        }
      }
    }
    return results;
  }

  Future<List<PerpuskuFile>> searchAllFiles(String query) async {
    final List<PerpuskuFile> results = [];
    final basePath = await _perpuskuBasePath;
    final topicsDir = Directory(basePath);
    final lowerCaseQuery = query.toLowerCase();

    if (!await topicsDir.exists()) return [];

    final topicDirs = topicsDir.listSync().whereType<Directory>();

    for (final topicDir in topicDirs) {
      final subjectDirs = topicDir.listSync().whereType<Directory>();
      for (final subjectDir in subjectDirs) {
        final metadataFile = File(path.join(subjectDir.path, 'metadata.json'));
        Map<String, String> currentTitles = {};
        if (await metadataFile.exists()) {
          final jsonString = await metadataFile.readAsString();
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          final content = jsonData['content'] as List<dynamic>? ?? [];
          currentTitles = {
            for (var item in content)
              item['nama_file'] as String: item['judul'] as String,
          };
        }

        final htmlFiles = subjectDir.listSync().whereType<File>().where(
          (f) => f.path.toLowerCase().endsWith('.html'),
        );

        for (final file in htmlFiles) {
          final fileName = path.basename(file.path);
          final title = currentTitles[fileName] ?? fileName;

          if (fileName.toLowerCase().contains(lowerCaseQuery) ||
              title.toLowerCase().contains(lowerCaseQuery)) {
            results.add(
              PerpuskuFile(fileName: fileName, title: title, path: file.path),
            );
          }
        }
      }
    }
    return results;
  }

  // >> FUNGSI INI DIPERBARUI UNTUK MENERIMA PARAMETER showHidden <<
  Future<List<PerpuskuTopic>> getTopics({bool showHidden = false}) async {
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
      bool isHidden = false;

      try {
        final configPath = await _pathService.getTopicConfigPath(topicName);
        final configFile = File(configPath);
        if (await configFile.exists()) {
          final jsonString = await configFile.readAsString();
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          topicIcon = jsonData['icon'] ?? _defaultIcon;
          isHidden = jsonData['isHidden'] ?? false;
        }
      } catch (e) {
        // Abaikan
      }

      // >> LOGIKA FILTER DITERAPKAN DI SINI <<
      if (showHidden || !isHidden) {
        topics.add(
          PerpuskuTopic(name: topicName, path: dir.path, icon: topicIcon),
        );
      }
    }

    topics.sort((a, b) => a.name.compareTo(b.name));
    return topics;
  }

  Future<List<PerpuskuSubject>> getSubjects(String topicPath) async {
    final directory = Directory(topicPath);
    if (!await directory.exists()) {
      return [];
    }

    final entities = directory.listSync().whereType<Directory>();
    final List<PerpuskuSubject> subjects = [];

    for (final dir in entities) {
      final subjectName = path.basename(dir.path);
      String subjectIcon = _defaultSubjectIcon;

      try {
        final topicName = path.basename(topicPath);
        final subjectJsonPath = await _pathService.getSubjectPath(
          await _pathService.getTopicPath(topicName),
          subjectName,
        );
        final subjectFile = File(subjectJsonPath);
        if (await subjectFile.exists()) {
          final jsonString = await subjectFile.readAsString();
          if (jsonString.isNotEmpty) {
            final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
            final metadata = jsonData['metadata'] as Map<String, dynamic>?;
            subjectIcon = metadata?['icon'] ?? _defaultSubjectIcon;
          }
        }
      } catch (e) {
        // Abaikan
      }

      subjects.add(
        PerpuskuSubject(name: subjectName, path: dir.path, icon: subjectIcon),
      );
    }

    subjects.sort((a, b) => a.name.compareTo(b.name));
    return subjects;
  }

  Future<List<PerpuskuFile>> getFiles(String subjectPath) async {
    final directory = Directory(subjectPath);
    if (!await directory.exists()) {
      return [];
    }

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
