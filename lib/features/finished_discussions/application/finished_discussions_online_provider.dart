// lib/features/finished_discussions/application/finished_discussions_online_provider.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/finished_discussions/domain/models/finished_discussion_model.dart';
import 'package:my_aplication/features/finished_discussions/application/finished_discussion_service.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_service.dart';

class FinishedDiscussionsOnlineProvider with ChangeNotifier {
  final FinishedDiscussionService _service = FinishedDiscussionService();
  final PathService _pathService = PathService();
  final SubjectService _subjectService = SubjectService();

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

  Future<String> archiveSelectedDiscussions() async {
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

    try {
      final outputPath = await _pathService.finishedDiscussionsExportPath;
      final rspaceArchiveDir = Directory(
        path.join(outputPath, 'RSpace_data', 'topics'),
      );
      final perpuskuArchiveDir = Directory(
        path.join(outputPath, 'PerpusKu_data', 'topics'),
      );

      if (!await rspaceArchiveDir.exists())
        await rspaceArchiveDir.create(recursive: true);
      if (!await perpuskuArchiveDir.exists())
        await perpuskuArchiveDir.create(recursive: true);

      final perpuskuSourcePath = await _pathService.perpuskuDataPath;
      final perpuskuSourceTopicsPath = path.join(
        perpuskuSourcePath,
        'file_contents',
        'topics',
      );

      final Map<String, List<FinishedDiscussion>> newDiscussionsByFile = {};
      for (final finished in discussionsToArchive) {
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

        // ==> PERUBAHAN UTAMA DI SINI <==
        // Ambil seluruh metadata dari file subjek asli.
        final subjectMetadata = await _subjectService.getSubjectMetadata(
          entry.key,
        );

        final jsonContent = {
          // Gunakan seluruh metadata yang diambil, bukan hanya ikon.
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
          if (discussion.filePath != null && discussion.filePath!.isNotEmpty) {
            final sourceFile = File(
              path.join(perpuskuSourceTopicsPath, discussion.filePath!),
            );
            if (await sourceFile.exists()) {
              final targetFileDir = Directory(
                path.join(
                  perpuskuArchiveDir.path,
                  path.dirname(discussion.filePath!),
                ),
              );
              if (!await targetFileDir.exists()) {
                await targetFileDir.create(recursive: true);
              }
              final targetFilePath = path.join(
                targetFileDir.path,
                path.basename(discussion.filePath!),
              );
              await sourceFile.copy(targetFilePath);
            }
          }
        }
      }

      final count = discussionsToArchive.length;
      return '$count diskusi berhasil diarsipkan.';
    } catch (e) {
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}
