// lib/features/archive/application/archive_provider.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:path/path.dart' as path;

class ArchiveProvider with ChangeNotifier {
  final PathService _pathService = PathService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<Topic> _topics = [];
  List<Topic> get topics => _topics;

  List<Subject> _subjects = [];
  List<Subject> get subjects => _subjects;

  List<Discussion> _discussions = [];
  List<Discussion> get discussions => _discussions;

  Future<String> get _archiveBasePath async {
    final exportPath = await _pathService.finishedDiscussionsExportPath;
    return path.join(exportPath, 'topics');
  }

  Future<void> fetchArchivedTopics() async {
    _isLoading = true;
    notifyListeners();
    try {
      final basePath = await _archiveBasePath;
      final directory = Directory(basePath);
      if (!await directory.exists()) {
        _topics = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final topicDirs = directory.listSync().whereType<Directory>();
      final List<Topic> loadedTopics = [];
      for (final dir in topicDirs) {
        final topicName = path.basename(dir.path);
        String icon = '📁';
        int position = -1;

        final configFile = File(path.join(dir.path, 'topic_config.json'));
        if (await configFile.exists()) {
          final jsonString = await configFile.readAsString();
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          icon = jsonData['icon'] ?? '📁';
          position = jsonData['position'] ?? -1;
        }
        loadedTopics.add(
          Topic(name: topicName, icon: icon, position: position),
        );
      }
      loadedTopics.sort((a, b) => a.position.compareTo(b.position));
      _topics = loadedTopics;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchArchivedSubjects(String topicName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final topicPath = path.join(await _archiveBasePath, topicName);
      final directory = Directory(topicPath);
      if (!await directory.exists()) {
        _subjects = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final subjectFiles = directory.listSync().whereType<File>().where(
        (file) =>
            file.path.endsWith('.json') &&
            !file.path.endsWith('topic_config.json'),
      );

      final List<Subject> loadedSubjects = [];
      for (final file in subjectFiles) {
        final subjectName = path.basenameWithoutExtension(file.path);
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        loadedSubjects.add(Subject.fromJson(topicName, subjectName, jsonData));
      }
      loadedSubjects.sort((a, b) => a.position.compareTo(b.position));
      _subjects = loadedSubjects;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchArchivedDiscussions(
    String topicName,
    String subjectName,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final subjectPath = path.join(
        await _archiveBasePath,
        topicName,
        '$subjectName.json',
      );
      final file = File(subjectPath);
      if (!await file.exists()) {
        _discussions = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final contentList = jsonData['content'] as List<dynamic>? ?? [];
      _discussions = contentList
          .map((item) => Discussion.fromJson(item))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
