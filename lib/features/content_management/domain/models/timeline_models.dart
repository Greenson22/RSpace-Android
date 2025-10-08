// lib/features/content_management/domain/models/timeline_models.dart

import 'package:flutter/material.dart';
import 'discussion_model.dart';

/// Mewakili satu diskusi pada titik waktu tertentu di linimasa.
class TimelineDiscussion {
  final Discussion discussion;
  final Offset position; // Posisi x, y pada canvas
  final Color color;

  TimelineDiscussion({
    required this.discussion,
    required this.position,
    required this.color,
  });
}

/// Mewakili semua data yang telah diolah dan siap untuk digambar oleh TimelinePainter.
class TimelineData {
  final List<TimelineDiscussion> discussions;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final Map<DateTime, int> discussionCounts; // Jumlah diskusi per hari

  TimelineData({
    required this.discussions,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.discussionCounts,
  });
}
