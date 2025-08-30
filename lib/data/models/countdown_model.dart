// lib/data/models/countdown_model.dart
import 'package:uuid/uuid.dart';

class CountdownItem {
  final String id;
  String name;
  Duration initialDuration;
  bool isRunning;
  DateTime createdAt;

  CountdownItem({
    String? id,
    required this.name,
    required this.initialDuration,
    this.isRunning = false,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory CountdownItem.fromJson(Map<String, dynamic> json) {
    return CountdownItem(
      id: json['id'],
      name: json['name'],
      initialDuration: Duration(seconds: json['initialDurationSeconds']),
      isRunning: json['isRunning'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initialDurationSeconds': initialDuration.inSeconds,
      'isRunning': isRunning,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
