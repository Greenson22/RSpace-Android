// lib/presentation/providers/finished_discussions_provider.dart

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../data/models/finished_discussion_model.dart';
import '../../data/services/discussion_service.dart';
import '../../data/services/finished_discussion_service.dart';
import '../../data/services/path_service.dart';

class FinishedDiscussionsProvider with ChangeNotifier {
  final FinishedDiscussionService _service = FinishedDiscussionService();
  final DiscussionService _discussionService = DiscussionService();
  final PathService _pathService = PathService();

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

  // >> FUNGSI EKSPOR DIPERBAIKI DI SINI
  Future<String> exportFinishedDiscussions() async {
    _isExporting = true;
    notifyListeners();

    // PERBAIKAN 1: Ganti variabel untuk menyimpan path subfolder, bukan folder /tmp
    Directory? stagingDir;
    try {
      // 1. Dapatkan direktori temporer sistem
      final tempDir = await getTemporaryDirectory();
      // Buat subfolder unik di dalamnya
      stagingDir = Directory(
        path.join(
          tempDir.path,
          'export_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await stagingDir.create(recursive: true);

      final rspaceDir = Directory(path.join(stagingDir.path, 'RSpace_Export'));
      final perpuskuDir = Directory(
        path.join(stagingDir.path, 'PerpusKu_Export'),
      );
      await rspaceDir.create();
      await perpuskuDir.create();

      final perpuskuBasePath = await _pathService.perpuskuDataPath;
      final perpuskuTopicsPath = path.join(
        perpuskuBasePath,
        'file_contents',
        'topics',
      );

      // 2. Kelompokkan diskusi (logika ini tetap sama)
      final Map<String, List<FinishedDiscussion>> discussionsByFile = {};
      for (final finished in _finishedDiscussions) {
        if (discussionsByFile.containsKey(finished.subjectJsonPath)) {
          discussionsByFile[finished.subjectJsonPath]!.add(finished);
        } else {
          discussionsByFile[finished.subjectJsonPath] = [finished];
        }
      }

      // 3. Salin dan strukturkan file (logika ini tetap sama)
      for (final entry in discussionsByFile.entries) {
        final discussions = entry.value;
        if (discussions.isEmpty) continue;

        final first = discussions.first;
        final topicName = first.topicName;
        final subjectName = first.subjectName;

        final rspaceTopicPath = path.join(rspaceDir.path, topicName);
        await Directory(rspaceTopicPath).create(recursive: true);
        final subjectJsonFile = File(
          path.join(rspaceTopicPath, '$subjectName.json'),
        );
        final jsonContent = {
          'metadata': {},
          'content': discussions.map((d) => d.discussion.toJson()).toList(),
        };
        await subjectJsonFile.writeAsString(jsonEncode(jsonContent));

        for (final discussion in discussions) {
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
              await sourceFile.copy(targetFile.path);
            }
          }
        }
      }

      // 4. Minta pengguna memilih lokasi penyimpanan (logika ini tetap sama)
      String? outputPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih Lokasi untuk Menyimpan File ZIP',
      );

      if (outputPath == null) {
        return 'Ekspor dibatalkan oleh pengguna.';
      }

      // 5. Buat file ZIP (logika ini tetap sama)
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final zipFilePath = path.join(
        outputPath,
        'Export-Finished-Discussions-$timestamp.zip',
      );
      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      await encoder.addDirectory(stagingDir);
      encoder.close();

      return 'Ekspor berhasil disimpan di: $zipFilePath';
    } catch (e) {
      rethrow;
    } finally {
      // PERBAIKAN 2: Hapus 'stagingDir' yang spesifik, bukan 'tempDir' utama
      if (stagingDir != null && await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
      _isExporting = false;
      notifyListeners();
    }
  }

  // ... (sisa fungsi lainnya tidak berubah)

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
