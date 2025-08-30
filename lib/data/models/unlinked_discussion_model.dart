// lib/data/models/unlinked_discussion_model.dart

import 'discussion_model.dart';
import 'topic_model.dart';
import 'subject_model.dart';

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
