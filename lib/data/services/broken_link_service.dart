// lib/data/services/broken_link_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/broken_link_model.dart';
import '../../features/content_management/domain/models/discussion_model.dart';
import '../../features/content_management/domain/models/subject_model.dart';
import '../../features/content_management/domain/models/topic_model.dart';
import 'path_service.dart';
import '../../features/content_management/domain/services/subject_service.dart';
import '../../features/content_management/domain/services/topic_service.dart';
import '../../features/content_management/domain/services/discussion_service.dart';

class BrokenLinkService {
  final PathService _pathService = PathService();
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final DiscussionService _discussionService = DiscussionService();

  Future<List<BrokenLink>> findBrokenLinks() async {
    final List<BrokenLink> brokenLinks = [];
    try {
      final perpuskuBasePath = await _pathService.perpuskuDataPath;
      final topicsPath = await _pathService.topicsPath;

      final topics = await _topicService.getTopics();

      for (final topic in topics) {
        final topicPath = path.join(topicsPath, topic.name);
        final subjects = await _subjectService.getSubjects(topicPath);

        for (final subject in subjects) {
          final subjectJsonPath = path.join(topicPath, '${subject.name}.json');
          final discussions = await _discussionService.loadDiscussions(
            subjectJsonPath,
          );

          for (final discussion in discussions) {
            final filePath = discussion.filePath;
            if (filePath != null && filePath.isNotEmpty) {
              // Bentuk path absolut ke file yang seharusnya ada
              final fullPath = path.join(
                perpuskuBasePath,
                'file_contents',
                'topics',
                filePath,
              );
              final file = File(fullPath);

              // Cek apakah file tersebut tidak ada
              if (!await file.exists()) {
                brokenLinks.add(
                  BrokenLink(
                    discussion: discussion,
                    topic: topic,
                    subject: subject,
                    invalidPath: filePath,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error finding broken links: $e");
      rethrow;
    }
    return brokenLinks;
  }
}
