// lib/data/models/unlinked_discussion_model.dart

import '../../features/content_management/domain/models/discussion_model.dart';
import '../../features/content_management/domain/models/topic_model.dart';
import '../../features/content_management/domain/models/subject_model.dart';

class UnlinkedDiscussion {
  final Discussion discussion;
  final Topic topic;
  final Subject subject;
  final String topicName;
  final String subjectName;
  final String subjectJsonPath; // Path lengkap ke file json subject
  final String? subjectLinkedPath; // Path tautan PerpusKu milik subject

  UnlinkedDiscussion({
    required this.discussion,
    required this.topic,
    required this.subject,
    required this.topicName,
    required this.subjectName,
    required this.subjectJsonPath,
    this.subjectLinkedPath,
  });
}
