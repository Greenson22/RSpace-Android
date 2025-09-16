// lib/presentation/providers/finished_discussions_provider.dart

import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../content_management/domain/models/discussion_model.dart';
import '../domain/models/finished_discussion_model.dart';
import '../../content_management/domain/services/discussion_service.dart';
import 'finished_discussion_service.dart';
import '../../../core/services/path_service.dart';
// >> BARU: Import SubjectService untuk membaca metadata
import '../../content_management/domain/services/subject_service.dart';

class FinishedDiscussionsProvider with ChangeNotifier {
  final FinishedDiscussionService _service = FinishedDiscussionService();
  final DiscussionService _discussionService = DiscussionService();
  final PathService _pathService = PathService();
  final SubjectService _subjectService = SubjectService(); // >> BARU

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  List<FinishedDiscussion> _finishedDiscussions = [];
  List<FinishedDiscussion> get finishedDiscussions => _finishedDiscussions;

  final Set<FinishedDiscussion> _selectedDiscussions = {};
  Set<FinishedDiscussion> get selectedDiscussions => _selectedDiscussions;
  bool get isSelectionMode => _selectedDiscussions.isNotEmpty;

  FinishedDiscussionsProvider() {
    fetchFinishedDiscussions();
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

  Future<String> exportFinishedDiscussions({
    bool deleteAfterExport = false,
  }) async {
    _isExporting = true;
    notifyListeners();

    final discussionsToExport = isSelectionMode
        ? _selectedDiscussions.toList()
        : _finishedDiscussions;

    if (discussionsToExport.isEmpty) {
      _isExporting = false;
      notifyListeners();
      return "Tidak ada diskusi yang dipilih untuk diekspor.";
    }

    Directory? stagingDir;
    try {
      final outputPath = await _pathService.finishedDiscussionsExportPath;
      final zipFilePath = path.join(
        outputPath,
        'Export-Finished-Discussions.zip',
      );
      final zipFile = File(zipFilePath);

      final tempDir = await getTemporaryDirectory();
      stagingDir = Directory(
        path.join(
          tempDir.path,
          'export_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await stagingDir.create(recursive: true);

      if (await zipFile.exists()) {
        await extractFileToDisk(zipFilePath, stagingDir.path);
      }

      final rspaceDir = Directory(path.join(stagingDir.path, 'RSpace'));
      final perpuskuDir = Directory(path.join(stagingDir.path, 'PerpusKu'));
      if (!await rspaceDir.exists()) await rspaceDir.create();
      if (!await perpuskuDir.exists()) await perpuskuDir.create();

      final perpuskuBasePath = await _pathService.perpuskuDataPath;
      final perpuskuTopicsPath = path.join(
        perpuskuBasePath,
        'file_contents',
        'topics',
      );

      final Map<String, List<FinishedDiscussion>> newDiscussionsByFile = {};
      for (final finished in discussionsToExport) {
        if (newDiscussionsByFile.containsKey(finished.subjectJsonPath)) {
          newDiscussionsByFile[finished.subjectJsonPath]!.add(finished);
        } else {
          newDiscussionsByFile[finished.subjectJsonPath] = [finished];
        }
      }

      for (final entry in newDiscussionsByFile.entries) {
        final discussionsToAdd = entry.value;
        if (discussionsToAdd.isEmpty) continue;

        final first = discussionsToAdd.first;
        final topicName = first.topicName;
        final subjectName = first.subjectName;

        final rspaceTopicPath = path.join(rspaceDir.path, topicName);
        await Directory(rspaceTopicPath).create(recursive: true);
        final subjectJsonFile = File(
          path.join(rspaceTopicPath, '$subjectName.json'),
        );

        List<Discussion> existingDiscussions = [];
        // >> BARU: Simpan metadata yang ada
        Map<String, dynamic> existingMetadata = {};

        if (await subjectJsonFile.exists()) {
          final jsonString = await subjectJsonFile.readAsString();
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          existingMetadata = jsonData['metadata'] ?? {};
          existingDiscussions = (jsonData['content'] as List)
              .map((item) => Discussion.fromJson(item))
              .toList();
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

        // ==> PERBAIKAN UTAMA DI SINI <==
        // Memanggil metode yang benar dari SubjectService.
        final subjectMetadata = await _subjectService.getSubjectMetadata(
          entry.key,
        );
        existingMetadata['icon'] =
            subjectMetadata['icon']; // Tambahkan ikon ke metadata

        final jsonContent = {
          'metadata': existingMetadata, // Simpan metadata yang diperbarui
          'content': existingDiscussions.map((d) => d.toJson()).toList(),
        };
        await subjectJsonFile.writeAsString(jsonEncode(jsonContent));

        // >> BARU: Simpan juga topic_config.json
        final topicConfigContent = first.topic.toConfigJson();
        final topicConfigFile = File(
          path.join(rspaceTopicPath, 'topic_config.json'),
        );
        await topicConfigFile.writeAsString(jsonEncode(topicConfigContent));

        for (final discussion in discussionsToAdd) {
          if (discussion.discussion.filePath != null &&
              discussion.discussion.filePath!.isNotEmpty) {
            final sourceFile = File(
              path.join(perpuskuTopicsPath, discussion.discussion.filePath!),
            );
            if (await sourceFile.exists()) {
              final perpuskuTopicPath = path.join(perpuskuDir.path, topicName);
              final perpuskuSubjectPath = path.join(
                perpuskuTopicPath,
                subjectName,
              );
              await Directory(perpuskuSubjectPath).create(recursive: true);

              final targetFile = File(
                path.join(perpuskuSubjectPath, path.basename(sourceFile.path)),
              );
              if (!await targetFile.exists()) {
                await sourceFile.copy(targetFile.path);
              }
            }
          }
        }
      }

      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      await encoder.addDirectory(stagingDir, includeDirName: false);
      encoder.close();

      if (deleteAfterExport) {
        if (!isSelectionMode) {
          selectAll();
        }
        await deleteSelected();
      }

      return 'Ekspor berhasil diperbarui di: $outputPath';
    } catch (e) {
      rethrow;
    } finally {
      if (stagingDir != null && await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
      _isExporting = false;
      notifyListeners();
    }
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

  Future<void> deleteSelected() async {
    for (final selected in _selectedDiscussions) {
      if (selected.discussion.filePath != null &&
          selected.discussion.filePath!.isNotEmpty) {
        try {
          await _discussionService.deleteLinkedFile(
            selected.discussion.filePath,
          );
        } catch (e) {
          debugPrint("Gagal menghapus file HTML tertaut: ${e.toString()}");
          throw Exception(
            'Gagal menghapus file: ${selected.discussion.filePath}. Proses dibatalkan.',
          );
        }
      }
    }

    final Map<String, List<String>> discussionsToDeleteByFile = {};

    for (final selected in _selectedDiscussions) {
      final path = selected.subjectJsonPath;
      final discussionName = selected.discussion.discussion;
      if (discussionsToDeleteByFile.containsKey(path)) {
        discussionsToDeleteByFile[path]!.add(discussionName);
      } else {
        discussionsToDeleteByFile[path] = [discussionName];
      }
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
}
