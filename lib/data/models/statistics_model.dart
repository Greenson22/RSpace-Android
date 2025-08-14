// lib/data/models/statistics_model.dart

class TopicStatistics {
  final String topicName;
  final String topicIcon;
  final int subjectCount;
  final int discussionCount;
  final int pointCount;

  TopicStatistics({
    required this.topicName,
    required this.topicIcon,
    this.subjectCount = 0,
    this.discussionCount = 0,
    this.pointCount = 0,
  });
}

class AppStatistics {
  final int topicCount;
  final int subjectCount;
  final int discussionCount;
  final int finishedDiscussionCount;
  final int pointCount;
  final int taskCategoryCount;
  final int taskCount;
  final int completedTaskCount;
  final List<TopicStatistics> perTopicStats;
  // ==> FIELD BARU UNTUK MENYIMPAN JUMLAH SETIAP REPETITION CODE <==
  final Map<String, int> repetitionCodeCounts;

  AppStatistics({
    this.topicCount = 0,
    this.subjectCount = 0,
    this.discussionCount = 0,
    this.finishedDiscussionCount = 0,
    this.pointCount = 0,
    this.taskCategoryCount = 0,
    this.taskCount = 0,
    this.completedTaskCount = 0,
    this.perTopicStats = const [],
    this.repetitionCodeCounts = const {}, // Default value
  });
}
