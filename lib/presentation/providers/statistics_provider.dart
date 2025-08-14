// lib/presentation/providers/statistics_provider.dart

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../data/models/statistics_model.dart';
import '../../data/services/discussion_service.dart';
import '../../data/services/my_task_service.dart';
import '../../data/services/path_service.dart';
import '../../data/services/subject_service.dart';
import '../../data/services/topic_service.dart';

class StatisticsProvider with ChangeNotifier {
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final DiscussionService _discussionService = DiscussionService();
  final MyTaskService _myTaskService = MyTaskService();
  final PathService _pathService = PathService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AppStatistics _stats = AppStatistics();
  AppStatistics get stats => _stats;

  StatisticsProvider() {
    generateStatistics();
  }

  Future<void> generateStatistics() async {
    _isLoading = true;
    notifyListeners();

    try {
      int topicCount = 0;
      int subjectCount = 0;
      int discussionCount = 0;
      int finishedDiscussionCount = 0;
      int pointCount = 0;
      int taskCategoryCount = 0;
      int taskCount = 0;
      int completedTaskCount = 0;

      // 1. Dapatkan Topik
      final topics = await _topicService.getTopics();
      topicCount = topics.length;

      final topicsPath = await _pathService.topicsPath;

      // 2. Iterasi setiap topik untuk mendapatkan subjek dan diskusi
      for (final topic in topics) {
        final topicPath = path.join(topicsPath, topic.name);
        try {
          final subjects = await _subjectService.getSubjects(topicPath);
          subjectCount += subjects.length;

          for (final subject in subjects) {
            final subjectJsonPath = path.join(
              topicPath,
              '${subject.name}.json',
            );
            final discussions = await _discussionService.loadDiscussions(
              subjectJsonPath,
            );
            discussionCount += discussions.length;

            for (final discussion in discussions) {
              if (discussion.finished) {
                finishedDiscussionCount++;
              }
              pointCount += discussion.points.length;
            }
          }
        } catch (e) {
          debugPrint('Could not process topic "${topic.name}": $e');
        }
      }

      // 3. Dapatkan statistik MyTasks
      final taskCategories = await _myTaskService.loadMyTasks();
      taskCategoryCount = taskCategories.length;
      for (final category in taskCategories) {
        taskCount += category.tasks.length;
        for (final task in category.tasks) {
          if (task.checked) {
            completedTaskCount++;
          }
        }
      }

      _stats = AppStatistics(
        topicCount: topicCount,
        subjectCount: subjectCount,
        discussionCount: discussionCount,
        finishedDiscussionCount: finishedDiscussionCount,
        pointCount: pointCount,
        taskCategoryCount: taskCategoryCount,
        taskCount: taskCount,
        completedTaskCount: completedTaskCount,
      );
    } catch (e) {
      debugPrint("Error generating statistics: $e");
      _stats = AppStatistics(); // Reset jika ada error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
