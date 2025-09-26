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

  FinishedDiscussionsOnlineProvider() {
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

  Future<String> exportFinishedDiscussionsOnline() async {
    _isExporting = true;
    notifyListeners();

    if (_finishedDiscussions.isEmpty) {
      _isExporting = false;
      notifyListeners();
      return "Tidak ada diskusi yang selesai untuk diarsipkan.";
    }

    try {
      final outputPath = await _pathService.finishedDiscussionsExportPath;

      // Definisikan path untuk data RSpace dan PerpusKu di dalam folder arsip
      final rspaceArchiveDir = Directory(
        path.join(outputPath, 'RSpace_data', 'topics'),
      );
      final perpuskuArchiveDir = Directory(
        path.join(outputPath, 'PerpusKu_data', 'topics'),
      );

      // Buat direktori jika belum ada
      if (!await rspaceArchiveDir.exists())
        await rspaceArchiveDir.create(recursive: true);
      if (!await perpuskuArchiveDir.exists())
        await perpuskuArchiveDir.create(recursive: true);

      // Dapatkan path sumber file HTML dari PerpusKu
      final perpuskuSourcePath = await _pathService.perpuskuDataPath;
      final perpuskuSourceTopicsPath = path.join(
        perpuskuSourcePath,
        'file_contents',
        'topics',
      );

      final Map<String, List<FinishedDiscussion>> newDiscussionsByFile = {};
      for (final finished in _finishedDiscussions) {
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

        // Salin file JSON (RSpace)
        final targetTopicPath = path.join(rspaceArchiveDir.path, topicName);
        await Directory(targetTopicPath).create(recursive: true);
        final subjectJsonFile = File(
          path.join(targetTopicPath, '$subjectName.json'),
        );

        List<Discussion> existingDiscussions = [];
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

        final subjectMetadata = await _subjectService.getSubjectMetadata(
          entry.key,
        );
        existingMetadata['icon'] = subjectMetadata['icon'];

        final jsonContent = {
          'metadata': existingMetadata,
          'content': existingDiscussions.map((d) => d.toJson()).toList(),
        };
        await subjectJsonFile.writeAsString(jsonEncode(jsonContent));

        final topicConfigContent = first.topic.toConfigJson();
        final topicConfigFile = File(
          path.join(targetTopicPath, 'topic_config.json'),
        );
        await topicConfigFile.writeAsString(jsonEncode(topicConfigContent));

        // Salin file HTML terkait (PerpusKu)
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

      return 'Arsip berhasil diperbarui di folder: finish_discussions';
    } catch (e) {
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}
