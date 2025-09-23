// lib/features/finished_discussions/application/finished_discussions_online_provider.dart

import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/finished_discussions/domain/models/finished_discussion_model.dart';
import 'package:my_aplication/features/content_management/domain/services/discussion_service.dart';
import 'package:my_aplication/features/finished_discussions/application/finished_discussion_service.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_service.dart';

class FinishedDiscussionsOnlineProvider with ChangeNotifier {
  final FinishedDiscussionService _service = FinishedDiscussionService();
  final DiscussionService _discussionService = DiscussionService();
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
      return "Tidak ada diskusi yang selesai untuk diekspor.";
    }

    Directory? stagingDir;
    try {
      final outputPath = await _pathService.finishedDiscussionsExportPath;
      final zipFilePath = path.join(
        outputPath,
        'Export-Finished-Discussions-Online.zip',
      );
      final zipFile = File(zipFilePath);

      final tempDir = await getTemporaryDirectory();
      stagingDir = Directory(
        path.join(
          tempDir.path,
          'export_online_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await stagingDir.create(recursive: true);

      if (await zipFile.exists()) {
        await extractFileToDisk(zipFilePath, stagingDir.path);
      }

      final rspaceDir = Directory(path.join(stagingDir.path, 'RSpace'));
      if (!await rspaceDir.exists()) await rspaceDir.create();

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

        final rspaceTopicPath = path.join(rspaceDir.path, topicName);
        await Directory(rspaceTopicPath).create(recursive: true);
        final subjectJsonFile = File(
          path.join(rspaceTopicPath, '$subjectName.json'),
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
          path.join(rspaceTopicPath, 'topic_config.json'),
        );
        await topicConfigFile.writeAsString(jsonEncode(topicConfigContent));
      }

      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      await encoder.addDirectory(stagingDir, includeDirName: false);
      encoder.close();

      return 'Ekspor online berhasil diperbarui di: $outputPath';
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
}
