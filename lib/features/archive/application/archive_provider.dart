// lib/features/archive/application/archive_provider.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_aplication/features/archive/application/archive_service.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';

class ArchiveProvider with ChangeNotifier {
  final ArchiveService _archiveService = ArchiveService();
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

  Future<void> fetchArchivedTopics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _topics = await _archiveService.fetchArchivedTopics();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchArchivedSubjects(String topicName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _subjects = await _archiveService.fetchArchivedSubjects(topicName);
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
    _error = null;
    notifyListeners();
    try {
      _discussions = await _archiveService.fetchArchivedDiscussions(
        topicName,
        subjectName,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openArchivedHtmlFile(
    Discussion discussion,
    String topicName,
    String subjectName,
  ) async {
    // Logika ini tetap sama karena masih mengandalkan path relatif dari data JSON
    final rawFilePath = discussion.filePath;
    if (rawFilePath == null || rawFilePath.isEmpty) {
      throw Exception("Diskusi ini tidak memiliki file tertaut.");
    }

    final fullRelativePath = path.join(
      topicName,
      subjectName,
      path.basename(rawFilePath),
    );

    final exportPath = await _pathService.finishedDiscussionsExportPath;
    final perpuskuArchivePath = path.join(
      exportPath,
      'PerpusKu_data',
      'topics',
    );
    final fullPath = path.join(perpuskuArchivePath, fullRelativePath);
    final file = File(fullPath);

    if (!await file.exists()) {
      throw Exception(
        "File HTML tidak ditemukan di dalam arsip lokal: $fullRelativePath",
      );
    }

    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception("Tidak dapat membuka file: ${result.message}");
    }
  }
}
