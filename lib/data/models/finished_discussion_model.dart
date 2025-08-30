// lib/data/models/finished_discussion_model.dart

import 'discussion_model.dart';

class FinishedDiscussion {
  final Discussion discussion;
  final String topicName;
  final String subjectName;
  final String subjectJsonPath;

  FinishedDiscussion({
    required this.discussion,
    required this.topicName,
    required this.subjectName,
    required this.subjectJsonPath,
  });
}
