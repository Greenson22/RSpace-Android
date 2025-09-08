// lib/data/services/unlinked_discussion_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../domain/models/unlinked_discussion_model.dart';
import '../../../../core/services/path_service.dart';
import '../../../content_management/domain/services/topic_service.dart';
import '../../../content_management/domain/services/subject_service.dart';
import '../../../content_management/domain/services/discussion_service.dart';

class UnlinkedDiscussionService {
  final PathService _pathService = PathService();
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final DiscussionService _discussionService = DiscussionService();

  /// Memindai semua atau topik spesifik untuk menemukan diskusi yang belum
  /// memiliki tautan file (`filePath`).
  ///
  /// [topicName] - Jika null, akan memindai semua topik. Jika diisi,
  /// hanya akan memindai topik dengan nama tersebut.
  /// [includeFinished] - Jika true, akan menyertakan diskusi yang sudah selesai.
  Future<List<UnlinkedDiscussion>> fetchAllUnlinkedDiscussions({
    String? topicName,
    bool includeFinished = false,
  }) async {
    final List<UnlinkedDiscussion> results = [];
    try {
      final allTopics = await _topicService.getTopics();
      final topicsPath = await _pathService.topicsPath;

      final topicsToScan = topicName != null
          ? allTopics.where((t) => t.name == topicName).toList()
          : allTopics;

      for (final topic in topicsToScan) {
        if (topic.isHidden) continue;

        final topicPath = path.join(topicsPath, topic.name);
        final subjects = await _subjectService.getSubjects(topicPath);

        for (final subject in subjects) {
          if (subject.isHidden) continue;

          final subjectJsonPath = path.join(topicPath, '${subject.name}.json');
          final discussions = await _discussionService.loadDiscussions(
            subjectJsonPath,
          );

          for (final discussion in discussions) {
            // Kondisi utama: path file kosong atau null
            bool needsLinking =
                discussion.filePath == null || discussion.filePath!.isEmpty;

            // Kondisi tambahan: status 'finished'
            bool matchesFinishedStatus = includeFinished
                ? true
                : !discussion.finished;

            if (needsLinking && matchesFinishedStatus) {
              results.add(
                UnlinkedDiscussion(
                  discussion: discussion,
                  topic: topic,
                  subject: subject,
                  topicName: topic.name,
                  subjectName: subject.name,
                  subjectJsonPath: subjectJsonPath,
                  subjectLinkedPath: subject.linkedPath,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching unlinked discussions: $e");
      rethrow;
    }
    return results;
  }
}
