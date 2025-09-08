// lib/data/models/broken_link_model.dart

import '../../../content_management/domain/models/discussion_model.dart';
import '../../../content_management/domain/models/subject_model.dart';
import '../../../content_management/domain/models/topic_model.dart';

class BrokenLink {
  final Discussion discussion;
  final Topic topic;
  final Subject subject;
  final String invalidPath; // Path yang tidak valid

  BrokenLink({
    required this.discussion,
    required this.topic,
    required this.subject,
    required this.invalidPath,
  });
}
