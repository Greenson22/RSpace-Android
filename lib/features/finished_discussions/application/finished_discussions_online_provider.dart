// lib/features/finished_discussions/application/finished_discussions_online_provider.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/finished_discussions/domain/models/finished_discussion_model.dart';
import 'package:my_aplication/features/content_management/domain/services/discussion_service.dart';
import 'package:my_aplication/features/finished_discussions/application/finished_discussion_service.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_service.dart';

// ==> 1. IMPOR SERVICE BARU YANG TELAH DIBUAT <==
import 'package:my_aplication/features/archive/application/archive_service.dart';

class FinishedDiscussionsOnlineProvider with ChangeNotifier {
  final FinishedDiscussionService _service = FinishedDiscussionService();
  final DiscussionService _discussionService = DiscussionService();
  final PathService _pathService = PathService();
  final SubjectService _subjectService = SubjectService();
  // ==> 2. BUAT INSTANCE DARI SERVICE BARU <==
  final ArchiveService _archiveService = ArchiveService();

  // ... (properti dan metode lain seperti _isLoading, fetchFinishedDiscussions, dll tetap sama) ...
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  List<FinishedDiscussion> _finishedDiscussions = [];
  List<FinishedDiscussion> get finishedDiscussions => _finishedDiscussions;

  final Set<FinishedDiscussion> _selectedDiscussions = {};
  Set<FinishedDiscussion> get selectedDiscussions => _selectedDiscussions;
  bool get isSelectionMode => _selectedDiscussions.isNotEmpty;

  FinishedDiscussionsOnlineProvider() {
    fetchFinishedDiscussions();
  }

  void toggleSelection(FinishedDiscussion discussion) {
    if (_selectedDiscussions.contains(discussion)) {
      _selectedDiscussions.remove(discussion);
    } else {
      _selectedDiscussions.add(discussion);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedDiscussions.addAll(_finishedDiscussions);
    notifyListeners();
  }

  void clearSelection() {
    _selectedDiscussions.clear();
    notifyListeners();
  }

  Future<void> fetchFinishedDiscussions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _finishedDiscussions = await _service.getAllFinishedDiscussions();
      _finishedDiscussions.sort(
        (a, b) => (b.discussion.finish_date ?? '').compareTo(
          a.discussion.finish_date ?? '',
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSelected() async {
    final Map<String, List<String>> discussionsToDeleteByFile = {};

    for (final selected in _selectedDiscussions) {
      final path = selected.subjectJsonPath;
      final discussionName = selected.discussion.discussion;
      discussionsToDeleteByFile.putIfAbsent(path, () => []).add(discussionName);
    }

    for (final entry in discussionsToDeleteByFile.entries) {
      await _discussionService.deleteMultipleDiscussions(
        entry.key,
        entry.value,
      );
    }

    _finishedDiscussions.removeWhere((d) => _selectedDiscussions.contains(d));
    _selectedDiscussions.clear();
    notifyListeners();
  }

  // ==> 3. MODIFIKASI FUNGSI archiveSelectedDiscussions <==
  Future<String> archiveSelectedDiscussions({
    bool deleteAfterExport = false,
  }) async {
    _isExporting = true;
    notifyListeners();

    final discussionsToArchive = isSelectionMode
        ? _selectedDiscussions.toList()
        : _finishedDiscussions;

    if (discussionsToArchive.isEmpty) {
      _isExporting = false;
      notifyListeners();
      return "Tidak ada diskusi yang dipilih untuk diarsipkan.";
    }

    Directory? tempDir;
    try {
      // Membuat file zip di direktori sementara
      tempDir = await Directory.systemTemp.createTemp('archive_');

      // Logika untuk mengumpulkan dan menyusun file ke dalam tempDir tetap sama...
      final rspaceArchiveDir = Directory(
        path.join(tempDir.path, 'RSpace_data', 'topics'),
      );
      final perpuskuArchiveDir = Directory(
        path.join(tempDir.path, 'PerpusKu_data', 'topics'),
      );
      await rspaceArchiveDir.create(recursive: true);
      await perpuskuArchiveDir.create(recursive: true);

      final perpuskuSourcePath = await _pathService.perpuskuDataPath;
      final perpuskuSourceTopicsPath = path.join(
        perpuskuSourcePath,
        'file_contents',
        'topics',
      );

      final Map<String, List<FinishedDiscussion>> discussionsByFile = {};
      for (final finished in discussionsToArchive) {
        discussionsByFile
            .putIfAbsent(finished.subjectJsonPath, () => [])
            .add(finished);
      }

      for (final entry in discussionsByFile.entries) {
        final discussionsToAdd = entry.value;
        if (discussionsToAdd.isEmpty) continue;

        final first = discussionsToAdd.first;
        final topicName = first.topicName;
        final subjectName = first.subjectName;

        final targetTopicPath = path.join(rspaceArchiveDir.path, topicName);
        await Directory(targetTopicPath).create(recursive: true);
        final subjectJsonFile = File(
          path.join(targetTopicPath, '$subjectName.json'),
        );

        List<Discussion> existingDiscussions = [];
        if (await subjectJsonFile.exists()) {
          final jsonString = await subjectJsonFile.readAsString();
          if (jsonString.isNotEmpty) {
            final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
            existingDiscussions = (jsonData['content'] as List)
                .map((item) => Discussion.fromJson(item))
                .toList();
          }
        }

        final existingDiscussionNames = existingDiscussions
            .map((d) => d.discussion)
            .toSet();
        for (final discussionToAdd in discussionsToAdd) {
          if (!existingDiscussionNames.contains(
            discussionToAdd.discussion.discussion,
          )) {
            existingDiscussions.add(discussionToAdd.discussion);
          }
        }

        final subjectMetadata = await _subjectService.getSubjectMetadata(
          entry.key,
        );
        final jsonContent = {
          'metadata': subjectMetadata,
          'content': existingDiscussions.map((d) => d.toJson()).toList(),
        };
        await subjectJsonFile.writeAsString(jsonEncode(jsonContent));

        final topicConfigContent = first.topic.toConfigJson();
        final topicConfigFile = File(
          path.join(targetTopicPath, 'topic_config.json'),
        );
        await topicConfigFile.writeAsString(jsonEncode(topicConfigContent));

        for (final discussionWrapper in discussionsToAdd) {
          final discussion = discussionWrapper.discussion;
          final rawFilePath = discussion.filePath;

          if (rawFilePath != null && rawFilePath.isNotEmpty) {
            final fullRelativePath = path.join(
              discussionWrapper.topicName,
              discussionWrapper.subjectName,
              path.basename(rawFilePath),
            );

            final sourceFile = File(
              path.join(perpuskuSourceTopicsPath, fullRelativePath),
            );

            if (await sourceFile.exists()) {
              final targetFilePath = path.join(
                perpuskuArchiveDir.path,
                fullRelativePath,
              );
              final targetFile = File(targetFilePath);

              await targetFile.parent.create(recursive: true);
              await sourceFile.copy(targetFile.path);
            }
          }
        }
      }

      // Mengompres direktori sementara menjadi satu file zip
      final zipFilePath = path.join(
        tempDir.path,
        'finished_discussions_archive.zip',
      );
      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      // Menambahkan semua konten dari tempDir ke dalam zip
      await encoder.addDirectory(tempDir, includeDirName: false);
      encoder.close();

      final archiveFile = File(zipFilePath);

      // MENGGANTI LOGIKA LAMA: unggah file zip ke server
      final uploadMessage = await _archiveService.uploadArchive(archiveFile);

      if (deleteAfterExport) {
        if (!isSelectionMode) {
          selectAll();
        }
        await deleteSelected();
      }

      // Kembalikan pesan sukses dari server
      return uploadMessage;
    } catch (e) {
      // Jika terjadi error, lemparkan kembali agar bisa ditangkap oleh UI
      rethrow;
    } finally {
      _isExporting = false;
      // Selalu hapus direktori sementara setelah selesai
      if (tempDir != null && await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      notifyListeners();
    }
  }
}
