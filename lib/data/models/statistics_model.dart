// lib/data/models/statistics_model.dart

class AppStatistics {
  final int topicCount;
  final int subjectCount;
  final int discussionCount;
  final int finishedDiscussionCount;
  final int pointCount;
  final int taskCategoryCount;
  final int taskCount;
  final int completedTaskCount;

  AppStatistics({
    this.topicCount = 0,
    this.subjectCount = 0,
    this.discussionCount = 0,
    this.finishedDiscussionCount = 0,
    this.pointCount = 0,
    this.taskCategoryCount = 0,
    this.taskCount = 0,
    this.completedTaskCount = 0,
  });
}
