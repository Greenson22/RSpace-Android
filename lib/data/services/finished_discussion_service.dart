// lib/data/services/finished_discussion_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/discussion_model.dart';
import '../models/finished_discussion_model.dart';
import 'path_service.dart';

class FinishedDiscussionService {
  final PathService _pathService = PathService();

  Future<List<FinishedDiscussion>> getAllFinishedDiscussions() async {
    final List<FinishedDiscussion> finishedDiscussions = [];
    try {
      final topicsPath = await _pathService.topicsPath;
      final topicsDir = Directory(topicsPath);

      if (!await topicsDir.exists()) return [];

      final topicEntities = topicsDir.listSync().whereType<Directory>();

      for (final topicDir in topicEntities) {
        final subjectFiles = topicDir.listSync().whereType<File>().where(
          (file) =>
              file.path.endsWith('.json') &&
              !path.basename(file.path).contains('config'),
        );

        for (final subjectFile in subjectFiles) {
          final jsonString = await subjectFile.readAsString();
          if (jsonString.isEmpty) continue;

          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          final contentList = jsonData['content'] as List<dynamic>? ?? [];

          for (var item in contentList) {
            final discussion = Discussion.fromJson(item);
            if (discussion.finished) {
              finishedDiscussions.add(
                FinishedDiscussion(
                  discussion: discussion,
                  topicName: path.basename(topicDir.path),
                  subjectName: path.basenameWithoutExtension(subjectFile.path),
                  subjectJsonPath: subjectFile.path,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching finished discussions: $e");
      rethrow;
    }
    return finishedDiscussions;
  }
}
