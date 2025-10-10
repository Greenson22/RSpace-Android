// lib/features/content_management/domain/models/timeline_models.dart

import 'package:flutter/material.dart';
import 'discussion_model.dart';

// Enum untuk membedakan tipe item di timeline
enum TimelineEventType { discussion, point }

/// Mewakili satu item (diskusi atau poin) pada titik waktu tertentu di linimasa.
class TimelineEvent {
  final Discussion parentDiscussion;
  final Point? point; // Null jika event ini adalah untuk diskusi utama
  final TimelineEventType type;
  final String title;
  final String effectiveDate;
  final String effectiveRepetitionCode;

  // Properti untuk painter
  Offset position = Offset.zero; // Posisi x, y pada canvas
  Color color = Colors.grey;

  TimelineEvent({
    required this.parentDiscussion,
    this.point,
    required this.type,
    required this.title,
    required this.effectiveDate,
    required this.effectiveRepetitionCode,
  });
}

/// Mewakili semua data yang telah diolah dan siap untuk digambar oleh TimelinePainter.
class TimelineData {
  final List<TimelineEvent> events; // Diubah dari List<TimelineDiscussion>
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final Map<DateTime, int> discussionCounts; // Jumlah diskusi per hari

  TimelineData({
    required this.events,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.discussionCounts,
  });
}
