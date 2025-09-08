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

  // ==> FIELD BARU UNTUK JURNAL AKTIVITAS <==
  final Duration totalTimeLogged;
  final Duration averageTimePerDay;
  final String? mostActiveDay; // Format: "Senin, 1 Jan 2024"
  final int mostActiveDayMinutes;

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
    this.repetitionCodeCounts = const {},
    // ==> INISIALISASI NILAI DEFAULT <==
    this.totalTimeLogged = Duration.zero,
    this.averageTimePerDay = Duration.zero,
    this.mostActiveDay,
    this.mostActiveDayMinutes = 0,
  });
}
