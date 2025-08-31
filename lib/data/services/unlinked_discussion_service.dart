// lib/data/services/unlinked_discussion_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/unlinked_discussion_model.dart';
import '../models/topic_model.dart';
import '../models/subject_model.dart';
import '../models/discussion_model.dart';
import 'path_service.dart';
import 'topic_service.dart';
import 'subject_service.dart';
import 'discussion_service.dart';

class UnlinkedDiscussionService {
  final PathService _pathService = PathService();
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final DiscussionService _discussionService = DiscussionService();

  /// Memindai semua topik dan subjek untuk menemukan diskusi yang belum
  /// memiliki tautan file (`filePath`).
  Future<List<UnlinkedDiscussion>> fetchAllUnlinkedDiscussions() async {
    final List<UnlinkedDiscussion> results = [];
    try {
      final topics = await _topicService.getTopics();
      final topicsPath = await _pathService.topicsPath;

      for (final topic in topics) {
        if (topic.isHidden) continue; // Lewati topik yang disembunyikan

        final topicPath = path.join(topicsPath, topic.name);
        final subjects = await _subjectService.getSubjects(topicPath);

        for (final subject in subjects) {
          if (subject.isHidden) continue; // Lewati subjek yang disembunyikan

          final subjectJsonPath = path.join(topicPath, '${subject.name}.json');
          final discussions = await _discussionService.loadDiscussions(
            subjectJsonPath,
          );

          for (final discussion in discussions) {
            // Kondisi utama: belum selesai DAN path file kosong atau null
            if (!discussion.finished &&
                (discussion.filePath == null || discussion.filePath!.isEmpty)) {
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
      // Lemparkan kembali error agar bisa ditangani oleh provider/UI
      rethrow;
    }
    return results;
  }
}
