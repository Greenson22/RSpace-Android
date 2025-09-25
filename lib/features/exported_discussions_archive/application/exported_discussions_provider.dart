// lib/presentation/providers/exported_discussions_provider.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../content_management/domain/models/discussion_model.dart';
import '../domain/models/exported_discussion_model.dart';
import '../../../core/services/path_service.dart';

class ExportedDiscussionsProvider with ChangeNotifier {
  final PathService _pathService = PathService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Directory? _archiveDir;
  Directory? get archiveDir => _archiveDir;

  DateTime? _lastModified;
  DateTime? get lastModified => _lastModified;

  List<ExportedTopic> _allExportedTopics = [];
  List<ExportedTopic> _exportedTopics = [];
  List<ExportedTopic> get exportedTopics => _exportedTopics;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  ExportedDiscussionsProvider() {
    loadExportedData();
  }

  Future<void> loadExportedData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final exportPath = await _pathService.finishedDiscussionsExportPath;
      final archiveTopicsPath = path.join(exportPath, 'topics');
      _archiveDir = Directory(archiveTopicsPath);

      if (!await _archiveDir!.exists()) {
        _allExportedTopics = [];
        _exportedTopics = [];
        _lastModified = null;
        return;
      }

      _lastModified = await _archiveDir!.stat().then((stat) => stat.modified);

      final Map<String, ExportedTopic> topicsMap = {};

      final topicDirs = _archiveDir!.listSync().whereType<Directory>();

      for (final topicDir in topicDirs) {
        final topicName = path.basename(topicDir.path);
        String topicIcon = '📁';

        final configFile = File(path.join(topicDir.path, 'topic_config.json'));
        if (await configFile.exists()) {
          final configContent = await configFile.readAsString();
          final configJson = jsonDecode(configContent) as Map<String, dynamic>;
          topicIcon = configJson['icon'] ?? '📁';
        }

        final topic = ExportedTopic(
          name: topicName,
          icon: topicIcon,
          subjects: [],
        );

        final subjectFiles = topicDir.listSync().whereType<File>().where(
          (file) =>
              file.path.endsWith('.json') &&
              !file.path.endsWith('topic_config.json'),
        );

        for (final subjectFile in subjectFiles) {
          final subjectName = path.basenameWithoutExtension(subjectFile.path);
          final content = await subjectFile.readAsString();
          final jsonData = jsonDecode(content) as Map<String, dynamic>;

          final discussions = (jsonData['content'] as List)
              .map((item) => Discussion.fromJson(item))
              .toList();

          final subjectIcon =
              (jsonData['metadata'] as Map<String, dynamic>?)?['icon'] ?? '📄';

          topic.subjects.add(
            ExportedSubject(
              name: subjectName,
              icon: subjectIcon,
              discussions: discussions,
            ),
          );
        }

        if (topic.subjects.isNotEmpty) {
          topicsMap[topicName] = topic;
        }
      }

      _allExportedTopics = topicsMap.values.toList();
      _allExportedTopics.sort((a, b) => a.name.compareTo(b.name));
      for (var topic in _allExportedTopics) {
        topic.subjects.sort((a, b) => a.name.compareTo(b.name));
      }

      _filterExportedData();
    } catch (e) {
      _error = "Gagal memuat atau membaca arsip: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filterExportedData();
  }

  void _filterExportedData() {
    if (_searchQuery.isEmpty) {
      _exportedTopics = List.from(_allExportedTopics);
    } else {
      final List<ExportedTopic> filteredTopics = [];
      for (final topic in _allExportedTopics) {
        final List<ExportedSubject> filteredSubjects = [];
        for (final subject in topic.subjects) {
          final List<Discussion> filteredDiscussions = subject.discussions
              .where((d) => d.discussion.toLowerCase().contains(_searchQuery))
              .toList();

          if (subject.name.toLowerCase().contains(_searchQuery) ||
              filteredDiscussions.isNotEmpty) {
            filteredSubjects.add(
              ExportedSubject(
                name: subject.name,
                icon: subject.icon,
                discussions: filteredDiscussions.isNotEmpty
                    ? filteredDiscussions
                    : subject.discussions,
              ),
            );
          }
        }

        if (topic.name.toLowerCase().contains(_searchQuery) ||
            filteredSubjects.isNotEmpty) {
          filteredTopics.add(
            ExportedTopic(
              name: topic.name,
              icon: topic.icon,
              subjects: filteredSubjects.isNotEmpty
                  ? filteredSubjects
                  : topic.subjects,
            ),
          );
        }
      }
      _exportedTopics = filteredTopics;
    }
    notifyListeners();
  }

  Future<void> openLinkedHtmlFile(Discussion discussion) async {
    if (discussion.filePath == null || discussion.filePath!.isEmpty) {
      throw Exception("Diskusi ini tidak memiliki file tertaut.");
    }

    // Karena ini adalah arsip, kita asumsikan path-nya relatif terhadap folder PerpusKu
    final perpuskuDataPath = await _pathService.perpuskuDataPath;
    final fullPath = path.join(
      perpuskuDataPath,
      'file_contents',
      'topics',
      discussion.filePath!,
    );
    final file = File(fullPath);

    if (!await file.exists()) {
      throw Exception(
        "File HTML tidak ditemukan di lokasi: ${discussion.filePath}",
      );
    }

    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception("Tidak dapat membuka file: ${result.message}");
    }
  }
}
