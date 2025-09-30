// lib/features/archive/application/archive_provider.dart

// ... (import-import yang ada tetap sama)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/archive/application/archive_service.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class ArchiveProvider with ChangeNotifier {
  final ArchiveService _archiveService = ArchiveService();
  // Hapus _pathService yang tidak lagi digunakan di sini

  // ... (properti _isLoading, _error, _topics, dll. tidak berubah)
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

  // ... (fungsi fetchArchivedTopics, fetchArchivedSubjects, fetchArchivedDiscussions tidak berubah)
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

  // ==> LOGIKA FUNGSI INI DIPERBARUI TOTAL <==
  Future<void> openArchivedHtmlFile(
    Discussion discussion,
    String topicName,
    String subjectName,
  ) async {
    final rawFilePath = discussion.filePath;
    if (rawFilePath == null || rawFilePath.isEmpty) {
      throw Exception("Diskusi ini tidak memiliki file tertaut.");
    }

    // Rekonstruksi path relatif yang benar dari konteks
    final fullRelativePath = path.join(
      topicName,
      subjectName,
      path.basename(rawFilePath),
    );

    try {
      // Panggil service untuk mengunduh file
      final File tempFile = await _archiveService.downloadArchivedFile(
        fullRelativePath,
      );

      // Buka file yang sudah diunduh ke direktori temporer
      final result = await OpenFile.open(tempFile.path);
      if (result.type != ResultType.done) {
        throw Exception("Tidak dapat membuka file: ${result.message}");
      }
    } catch (e) {
      // Lemparkan kembali error agar bisa ditangkap oleh UI
      rethrow;
    }
  }
}
