// lib/presentation/providers/unlinked_discussions_provider.dart

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../domain/models/unlinked_discussion_model.dart';
import '../../../content_management/domain/services/discussion_service.dart';
import '../../../../core/services/path_service.dart';
import '../../../content_management/domain/services/subject_service.dart';
import '../../../content_management/domain/services/topic_service.dart';

class UnlinkedDiscussionsProvider with ChangeNotifier {
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final DiscussionService _discussionService = DiscussionService();
  final PathService _pathService = PathService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<UnlinkedDiscussion> _unlinkedDiscussions = [];
  List<UnlinkedDiscussion> get unlinkedDiscussions => _unlinkedDiscussions;

  UnlinkedDiscussionsProvider() {
    fetchAllUnlinkedDiscussions();
  }

  Future<void> fetchAllUnlinkedDiscussions() async {
    _isLoading = true;
    notifyListeners();

    final List<UnlinkedDiscussion> results = [];
    try {
      final topics = await _topicService.getTopics();
      final topicsPath = await _pathService.topicsPath;

      for (final topic in topics) {
        final topicPath = path.join(topicsPath, topic.name);
        final subjects = await _subjectService.getSubjects(topicPath);

        for (final subject in subjects) {
          final subjectJsonPath = path.join(topicPath, '${subject.name}.json');
          final discussions = await _discussionService.loadDiscussions(
            subjectJsonPath,
          );

          for (final discussion in discussions) {
            if (discussion.filePath == null || discussion.filePath!.isEmpty) {
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
      _unlinkedDiscussions = results;
    } catch (e) {
      debugPrint("Error fetching unlinked discussions: $e");
      // Anda bisa menambahkan penanganan error di sini jika perlu
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
