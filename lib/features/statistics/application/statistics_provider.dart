// lib/features/statistics/application/statistics_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../domain/models/statistics_model.dart';
import '../../time_management/domain/models/time_log_model.dart';
import '../../content_management/domain/services/discussion_service.dart';
import '../../my_tasks/application/my_task_service.dart';
import '../../../core/services/path_service.dart';
import '../../content_management/domain/services/subject_service.dart';
import '../../time_management/application/services/time_log_service.dart';
import '../../content_management/domain/services/topic_service.dart';

class StatisticsProvider with ChangeNotifier {
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final DiscussionService _discussionService = DiscussionService();
  final MyTaskService _myTaskService = MyTaskService();
  final PathService _pathService = PathService();
  final TimeLogService _timeLogService = TimeLogService();

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
      int totalSubjectCount = 0;
      int totalDiscussionCount = 0;
      int totalFinishedDiscussionCount = 0;
      int totalPointCount = 0;
      List<TopicStatistics> perTopicStats = [];
      Map<String, int> repetitionCodeCounts = {};

      final topics = await _topicService.getTopics();
      final topicsPath = await _pathService.topicsPath;

      for (final topic in topics) {
        int currentTopicSubjectCount = 0;
        int currentTopicDiscussionCount = 0;
        int currentTopicPointCount = 0;

        final topicPath = path.join(topicsPath, topic.name);
        try {
          final subjects = await _subjectService.getSubjects(topicPath);
          currentTopicSubjectCount = subjects.length;

          for (final subject in subjects) {
            final subjectJsonPath = path.join(
              topicPath,
              '${subject.name}.json',
            );
            final discussions = await _discussionService.loadDiscussions(
              subjectJsonPath,
            );
            currentTopicDiscussionCount += discussions.length;

            for (final discussion in discussions) {
              if (discussion.finished) {
                totalFinishedDiscussionCount++;
              }
              currentTopicPointCount += discussion.points.length;

              final code = discussion.effectiveRepetitionCode;
              repetitionCodeCounts[code] =
                  (repetitionCodeCounts[code] ?? 0) + 1;
            }
          }
        } catch (e) {
          debugPrint('Could not process topic "${topic.name}": $e');
        }

        perTopicStats.add(
          TopicStatistics(
            topicName: topic.name,
            topicIcon: topic.icon,
            subjectCount: currentTopicSubjectCount,
            discussionCount: currentTopicDiscussionCount,
            pointCount: currentTopicPointCount,
          ),
        );

        totalSubjectCount += currentTopicSubjectCount;
        totalDiscussionCount += currentTopicDiscussionCount;
        totalPointCount += currentTopicPointCount;
      }

      int taskCategoryCount = 0;
      int taskCount = 0;
      int completedTaskCount = 0;
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

      Duration totalTimeLogged = Duration.zero;
      Duration averageTimePerDay = Duration.zero;
      String? mostActiveDay;
      int mostActiveDayMinutes = 0;

      final List<TimeLogEntry> timeLogs = await _timeLogService.loadTimeLogs();
      if (timeLogs.isNotEmpty) {
        int totalMinutes = 0;
        TimeLogEntry? mostActiveEntry;

        for (final log in timeLogs) {
          final dailyMinutes = log.tasks.fold<int>(
            0,
            (sum, task) => sum + task.durationMinutes,
          );
          totalMinutes += dailyMinutes;

          if (dailyMinutes > mostActiveDayMinutes) {
            mostActiveDayMinutes = dailyMinutes;
            mostActiveEntry = log;
          }
        }

        totalTimeLogged = Duration(minutes: totalMinutes);
        averageTimePerDay = Duration(
          minutes: (totalMinutes / timeLogs.length).round(),
        );
        if (mostActiveEntry != null) {
          mostActiveDay = DateFormat(
            'EEEE, d MMM yyyy',
            'id_ID',
          ).format(mostActiveEntry.date);
        }
      }

      _stats = AppStatistics(
        topicCount: topics.length,
        subjectCount: totalSubjectCount,
        discussionCount: totalDiscussionCount,
        finishedDiscussionCount: totalFinishedDiscussionCount,
        pointCount: totalPointCount,
        taskCategoryCount: taskCategoryCount,
        taskCount: taskCount,
        completedTaskCount: completedTaskCount,
        perTopicStats: perTopicStats,
        repetitionCodeCounts: repetitionCodeCounts,
        totalTimeLogged: totalTimeLogged,
        averageTimePerDay: averageTimePerDay,
        mostActiveDay: mostActiveDay,
        mostActiveDayMinutes: mostActiveDayMinutes,
      );
    } catch (e) {
      debugPrint("Error generating statistics: $e");
      _stats = AppStatistics();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
