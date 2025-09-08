// lib/data/models/countdown_model.dart
import 'package:uuid/uuid.dart';

class CountdownItem {
  final String id;
  String name;
  Duration remainingDuration; // Durasi yang tersisa (akan berkurang)
  final Duration originalDuration; // Durasi asli (tidak akan berubah)
  bool isRunning;
  DateTime createdAt;

  CountdownItem({
    String? id,
    required this.name,
    required this.remainingDuration,
    required this.originalDuration,
    this.isRunning = false,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  factory CountdownItem.fromJson(Map<String, dynamic> json) {
    // Untuk kompatibilitas mundur dengan data lama, jika 'originalDurationSeconds'
    // tidak ada, gunakan 'initialDurationSeconds' untuk keduanya.
    final originalSeconds =
        json['originalDurationSeconds'] ?? json['initialDurationSeconds'];
    return CountdownItem(
      id: json['id'],
      name: json['name'],
      remainingDuration: Duration(seconds: json['initialDurationSeconds']),
      originalDuration: Duration(seconds: originalSeconds),
      isRunning: json['isRunning'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'initialDurationSeconds': remainingDuration.inSeconds,
      'originalDurationSeconds': originalDuration.inSeconds,
      'isRunning': isRunning,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
