// lib/features/content_management/presentation/timeline/discussion_timeline_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/discussion_model.dart';
import '../../domain/models/timeline_models.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';

class DiscussionTimelineProvider with ChangeNotifier {
  // ==> PERUBAHAN DI SINI: Jadikan _allDiscussions non-final dan inisialisasi dengan list kosong <==
  List<Discussion> _allDiscussions = [];
  TimelineData? _timelineData;
  TimelineData? get timelineData => _timelineData;

  // Getter publik sekarang langsung mengembalikan list yang sudah diinisialisasi
  List<Discussion> get discussions => _allDiscussions;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  DateTimeRange? _selectedDateRange;
  DateTimeRange? get selectedDateRange => _selectedDateRange;

  // ==> PERUBAHAN DI SINI: Konstruktor sekarang lebih sederhana <==
  DiscussionTimelineProvider(List<Discussion>? initialDiscussions) {
    // Pastikan _allDiscussions tidak pernah null
    _allDiscussions = initialDiscussions ?? [];
    processDiscussions();
  }

  void processDiscussions() {
    _isLoading = true;
    notifyListeners();

    final activeDiscussions = _allDiscussions
        .where((d) => d.effectiveDate != null)
        .toList();

    if (activeDiscussions.isEmpty) {
      _timelineData = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    activeDiscussions.sort(
      (a, b) => DateTime.parse(
        a.effectiveDate!,
      ).compareTo(DateTime.parse(b.effectiveDate!)),
    );

    DateTime overallStartDate = DateTime.parse(
      activeDiscussions.first.effectiveDate!,
    );
    DateTime overallEndDate = DateTime.parse(
      activeDiscussions.last.effectiveDate!,
    );

    if (DateUtils.isSameDay(overallStartDate, overallEndDate)) {
      overallEndDate = overallStartDate.add(const Duration(days: 7));
    }

    final displayStartDate = _selectedDateRange?.start ?? overallStartDate;
    final displayEndDate = _selectedDateRange?.end ?? overallEndDate;

    final filteredDiscussions = activeDiscussions.where((d) {
      final date = DateTime.tryParse(d.effectiveDate!);
      if (date == null) return false;
      return !date.isBefore(DateUtils.dateOnly(displayStartDate)) &&
          !date.isAfter(DateUtils.dateOnly(displayEndDate));
    }).toList();

    final Map<DateTime, int> discussionCounts = {};
    for (var discussion in filteredDiscussions) {
      final dateOnly = DateUtils.dateOnly(
        DateTime.parse(discussion.effectiveDate!),
      );
      discussionCounts[dateOnly] = (discussionCounts[dateOnly] ?? 0) + 1;
    }

    final int totalDays = displayEndDate.difference(displayStartDate).inDays;

    _timelineData = TimelineData(
      discussions: [],
      startDate: displayStartDate,
      endDate: displayEndDate,
      totalDays: totalDays,
      discussionCounts: discussionCounts,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setDateRange(BuildContext context) async {
    final now = DateTime.now();
    final firstDate =
        _timelineData?.startDate ?? now.subtract(const Duration(days: 365));
    final lastDate =
        _timelineData?.endDate ?? now.add(const Duration(days: 365));

    final newRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate.subtract(const Duration(days: 365)),
      lastDate: lastDate.add(const Duration(days: 365)),
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: _timelineData!.startDate,
            end: _timelineData!.endDate,
          ),
    );

    if (newRange != null) {
      _selectedDateRange = newRange;
      processDiscussions();
    }
  }

  void clearDateRange() {
    _selectedDateRange = null;
    processDiscussions();
  }
}
