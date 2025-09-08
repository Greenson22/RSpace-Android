// lib/data/models/feedback_model.dart
import 'package:uuid/uuid.dart';

enum FeedbackType { idea, bug, suggestion }

enum FeedbackStatus { fresh, inProgress, done }

class FeedbackItem {
  final String id;
  String title;
  String description;
  FeedbackType type;
  FeedbackStatus status;
  DateTime createdAt;
  DateTime updatedAt;

  FeedbackItem({
    String? id,
    required this.title,
    this.description = '',
    required this.type,
    this.status = FeedbackStatus.fresh,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: FeedbackType.values[json['type'] as int],
      status: FeedbackStatus.values[json['status'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
