// lib/data/models/finished_discussion_model.dart

import '../../features/content_management/domain/models/discussion_model.dart';
import '../../features/content_management/domain/models/topic_model.dart'; // >> 1. IMPORT MODEL TOPIK

class FinishedDiscussion {
  final Discussion discussion;
  final String topicName;
  final Topic topic; // >> 2. TAMBAHKAN PROPERTI BARU
  final String subjectName;
  final String subjectJsonPath;

  FinishedDiscussion({
    required this.discussion,
    required this.topicName,
    required this.topic, // >> 3. TAMBAHKAN DI KONSTRUKTOR
    required this.subjectName,
    required this.subjectJsonPath,
  });
}
