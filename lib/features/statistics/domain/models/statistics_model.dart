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
  final int totalTaskCount;
  final int dailyTargetTaskCount;
  final int dailyTargetsCompleted;
  final List<TopicStatistics> perTopicStats;
  final Map<String, int> repetitionCodeCounts;

  final Duration totalTimeLogged;
  final Duration averageTimePerDay;
  final String? mostActiveDay;
  final int mostActiveDayMinutes;

  final int quizCategoryCount;
  final int quizTopicCount;
  final int quizSetCount;
  final int quizQuestionCount;

  // ==> PROPERTI BARU DITAMBAHKAN <==
  final int noteTopicCount;
  final int totalNotesCount;
  final int neuronCount;

  AppStatistics({
    this.topicCount = 0,
    this.subjectCount = 0,
    this.discussionCount = 0,
    this.finishedDiscussionCount = 0,
    this.pointCount = 0,
    this.taskCategoryCount = 0,
    this.totalTaskCount = 0,
    this.dailyTargetTaskCount = 0,
    this.dailyTargetsCompleted = 0,
    this.perTopicStats = const [],
    this.repetitionCodeCounts = const {},
    this.totalTimeLogged = Duration.zero,
    this.averageTimePerDay = Duration.zero,
    this.mostActiveDay,
    this.mostActiveDayMinutes = 0,
    this.quizCategoryCount = 0,
    this.quizTopicCount = 0,
    this.quizSetCount = 0,
    this.quizQuestionCount = 0,
    // ==> INISIALISASI PROPERTI BARU <==
    this.noteTopicCount = 0,
    this.totalNotesCount = 0,
    this.neuronCount = 0,
  });
}
