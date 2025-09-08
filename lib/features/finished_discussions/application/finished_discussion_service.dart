// lib/data/services/finished_discussion_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../../content_management/domain/models/discussion_model.dart';
import '../domain/models/finished_discussion_model.dart';
import '../../../data/services/path_service.dart';
import '../../content_management/domain/services/topic_service.dart';

class FinishedDiscussionService {
  final PathService _pathService = PathService();
  final TopicService _topicService = TopicService();

  Future<List<FinishedDiscussion>> getAllFinishedDiscussions() async {
    final List<FinishedDiscussion> finishedDiscussions = [];
    try {
      final topicsPath = await _pathService.topicsPath;
      final topics = await _topicService.getTopics();

      for (final topic in topics) {
        final topicDir = Directory(path.join(topicsPath, topic.name));
        if (!await topicDir.exists()) continue;

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
                // >> PERBAIKAN DI SINI: Tambahkan parameter 'topic' yang hilang
                FinishedDiscussion(
                  discussion: discussion,
                  topicName: topic.name,
                  topic: topic, // <-- Ini yang ditambahkan
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
