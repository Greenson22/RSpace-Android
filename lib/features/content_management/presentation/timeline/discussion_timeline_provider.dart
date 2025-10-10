// lib/features/content_management/presentation/timeline/discussion_timeline_provider.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/discussion_model.dart';
import '../../domain/models/timeline_models.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';
import 'dialogs/reschedule_discussions_dialog.dart';
import '../../domain/services/discussion_service.dart';
import '../../../../core/services/user_data_service.dart';

class DiscussionTimelineProvider with ChangeNotifier {
  final String _subjectJsonPath;
  final DiscussionService _discussionService = DiscussionService();
  final UserDataService _userDataService = UserDataService();

  List<Discussion> _allDiscussions = [];
  TimelineData? _timelineData;
  TimelineData? get timelineData => _timelineData;
  List<Discussion> get discussions => _allDiscussions;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  DateTimeRange? _selectedDateRange;
  DateTimeRange? get selectedDateRange => _selectedDateRange;

  double _zoomLevel = 1.0;
  double get zoomLevel => _zoomLevel;

  double _discussionRadius = 6.0;
  double get discussionRadius => _discussionRadius;

  double _pointRadius = 4.0;
  double get pointRadius => _pointRadius;

  double _discussionSpacing = 10.0;
  double get discussionSpacing => _discussionSpacing;

  double _pointSpacing = 8.0;
  double get pointSpacing => _pointSpacing;

  final Set<TimelineEvent> _selectedEvents = {};
  Set<TimelineEvent> get selectedEvents => _selectedEvents;
  bool get isSelectionMode => _selectedEvents.isNotEmpty;

  DiscussionTimelineProvider(
    List<Discussion>? initialDiscussions,
    this._subjectJsonPath,
  ) {
    _allDiscussions = initialDiscussions ?? [];
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAppearanceSettings();
    processDiscussions();
  }

  Future<void> _loadAppearanceSettings() async {
    final settings = await _userDataService.loadTimelineAppearance();
    _discussionRadius = settings['discussionRadius']!;
    _pointRadius = settings['pointRadius']!;
    _discussionSpacing = settings['discussionSpacing']!;
    _pointSpacing = settings['pointSpacing']!;
    _zoomLevel = settings['zoomLevel']!;
    notifyListeners();
  }

  Future<void> updateAppearanceSettings({
    double? discussionRadius,
    double? pointRadius,
    double? discussionSpacing,
    double? pointSpacing,
    double? zoomLevel,
  }) async {
    if (discussionRadius != null) _discussionRadius = discussionRadius;
    if (pointRadius != null) _pointRadius = pointRadius;
    if (discussionSpacing != null) _discussionSpacing = discussionSpacing;
    if (pointSpacing != null) _pointSpacing = pointSpacing;
    if (zoomLevel != null) _zoomLevel = zoomLevel;

    await _userDataService.saveTimelineAppearance(
      discussionRadius: _discussionRadius,
      pointRadius: _pointRadius,
      discussionSpacing: _discussionSpacing,
      pointSpacing: _pointSpacing,
      zoomLevel: _zoomLevel,
    );
    notifyListeners();
  }

  void toggleEventSelection(TimelineEvent event) {
    if (_selectedEvents.contains(event)) {
      _selectedEvents.remove(event);
    } else {
      _selectedEvents.add(event);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedEvents.clear();
    notifyListeners();
  }

  Future<void> updateSelectedEventsDate(Duration dateOffset) async {
    if (_selectedEvents.isEmpty) return;

    for (final event in _selectedEvents) {
      final currentEventDate = DateTime.parse(event.effectiveDate);
      final newDate = currentEventDate.add(dateOffset);
      final formattedDate = DateFormat('yyyy-MM-dd').format(newDate);

      final parentDiscussion = _allDiscussions.firstWhere(
        (d) => d.discussion == event.parentDiscussion.discussion,
      );

      if (event.type == TimelineEventType.discussion) {
        parentDiscussion.date = formattedDate;
      } else if (event.type == TimelineEventType.point && event.point != null) {
        final pointToUpdate = parentDiscussion.points.firstWhere(
          (p) => p.pointText == event.point!.pointText,
        );
        pointToUpdate.date = formattedDate;
      }
    }

    await _discussionService.saveDiscussions(_subjectJsonPath, _allDiscussions);
    processDiscussions();
  }

  void zoomIn() {
    final newZoom = (_zoomLevel + 0.25).clamp(0.5, 5.0);
    updateAppearanceSettings(zoomLevel: newZoom);
  }

  void zoomOut() {
    final newZoom = (_zoomLevel - 0.25).clamp(0.5, 5.0);
    updateAppearanceSettings(zoomLevel: newZoom);
  }

  Future<void> updateEventDate(TimelineEvent event, DateTime newDate) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(newDate);

    final parentDiscussion = _allDiscussions.firstWhere(
      (d) => d.discussion == event.parentDiscussion.discussion,
    );

    if (event.type == TimelineEventType.discussion) {
      parentDiscussion.date = formattedDate;
    } else if (event.type == TimelineEventType.point && event.point != null) {
      final pointToUpdate = parentDiscussion.points.firstWhere(
        (p) => p.pointText == event.point!.pointText,
      );
      pointToUpdate.date = formattedDate;
    }

    await _discussionService.saveDiscussions(_subjectJsonPath, _allDiscussions);
    processDiscussions();
  }

  // ==> FUNGSI INI DITULIS ULANG <==
  List<TimelineEvent> _getAllFutureEvents() {
    final today = DateUtils.dateOnly(DateTime.now());
    final allEvents = <TimelineEvent>[];

    for (final discussion in _allDiscussions) {
      if (discussion.finished) continue;

      if (discussion.points.isEmpty) {
        if (discussion.date != null) {
          final eventDate = DateTime.tryParse(discussion.date!);
          if (eventDate != null && !eventDate.isBefore(today)) {
            allEvents.add(
              TimelineEvent(
                parentDiscussion: discussion,
                type: TimelineEventType.discussion,
                title: discussion.discussion,
                effectiveDate: discussion.date!,
                effectiveRepetitionCode: discussion.repetitionCode,
              ),
            );
          }
        }
      } else {
        for (final point in discussion.points) {
          if (!point.finished) {
            final eventDate = DateTime.tryParse(point.date);
            if (eventDate != null && !eventDate.isBefore(today)) {
              allEvents.add(
                TimelineEvent(
                  parentDiscussion: discussion,
                  point: point,
                  type: TimelineEventType.point,
                  title: point.pointText,
                  effectiveDate: point.date,
                  effectiveRepetitionCode: point.repetitionCode,
                ),
              );
            }
          }
        }
      }
    }
    allEvents.sort(
      (a, b) => DateTime.parse(
        a.effectiveDate,
      ).compareTo(DateTime.parse(b.effectiveDate)),
    );
    return allEvents;
  }

  Future<String> rescheduleDiscussions(RescheduleDialogResult result) async {
    _isProcessing = true;
    notifyListeners();

    try {
      if (result.algorithm == RescheduleAlgorithm.balance) {
        return await _balanceSchedule(result.maxMoveDays);
      } else {
        return await _spreadSchedule();
      }
    } finally {
      _isProcessing = false;
    }
  }

  // ==> FUNGSI INI DITULIS ULANG TOTAL <==
  Future<String> _balanceSchedule(int maxMoveDays) async {
    final eventsToReschedule = _getAllFutureEvents();

    if (eventsToReschedule.length < 2) {
      return "Tidak cukup item di masa depan untuk dijadwalkan ulang.";
    }

    final startDate = DateUtils.dateOnly(DateTime.now());
    final endDate = DateTime.parse(eventsToReschedule.last.effectiveDate);
    final totalDays = endDate.difference(startDate).inDays;

    if (totalDays <= 0) {
      return "Rentang waktu tidak cukup untuk penjadwalan ulang.";
    }

    final double idealInterval = totalDays / (eventsToReschedule.length - 1);
    int updatedCount = 0;

    for (int i = 0; i < eventsToReschedule.length; i++) {
      final event = eventsToReschedule[i];
      final originalDate = DateTime.parse(event.effectiveDate);
      final idealDate = startDate.add(
        Duration(days: (i * idealInterval).round()),
      );

      final minAllowedDate = originalDate.subtract(Duration(days: maxMoveDays));
      final maxAllowedDate = originalDate.add(Duration(days: maxMoveDays));

      DateTime newDate;
      if (idealDate.isBefore(minAllowedDate)) {
        newDate = minAllowedDate;
      } else if (idealDate.isAfter(maxAllowedDate)) {
        newDate = maxAllowedDate;
      } else {
        newDate = idealDate;
      }

      if (newDate.isBefore(startDate)) newDate = startDate;

      // Perbarui tanggal di objek yang sebenarnya
      await updateEventDate(event, newDate);
      updatedCount++;
    }

    // Panggil processDiscussions setelah semua pembaruan selesai
    processDiscussions();
    return "$updatedCount item berhasil diseimbangkan jadwalnya.";
  }

  // ==> FUNGSI INI DITULIS ULANG TOTAL <==
  Future<String> _spreadSchedule() async {
    final eventsToReschedule = _getAllFutureEvents();

    if (eventsToReschedule.length < 2) {
      return "Tidak cukup item di masa depan untuk dijadwalkan ulang.";
    }

    final startDate = DateUtils.dateOnly(DateTime.now());
    final endDate = DateTime.parse(eventsToReschedule.last.effectiveDate);
    final totalDays = endDate.difference(startDate).inDays;

    if (totalDays <= 0) {
      return "Rentang waktu tidak cukup untuk penjadwalan ulang.";
    }

    final double evenInterval = totalDays / (eventsToReschedule.length - 1);
    int updatedCount = 0;

    for (int i = 0; i < eventsToReschedule.length; i++) {
      final event = eventsToReschedule[i];
      final newDate = startDate.add(Duration(days: (i * evenInterval).round()));

      // Perbarui tanggal di objek yang sebenarnya
      await updateEventDate(event, newDate);
      updatedCount++;
    }

    processDiscussions();
    return "$updatedCount item berhasil diratakan jadwalnya.";
  }

  void processDiscussions() {
    _isLoading = true;
    notifyListeners();

    final allEvents = <TimelineEvent>[];
    for (final discussion in _allDiscussions) {
      if (discussion.finished) continue;

      if (discussion.points.isEmpty) {
        if (discussion.date != null) {
          allEvents.add(
            TimelineEvent(
              parentDiscussion: discussion,
              type: TimelineEventType.discussion,
              title: discussion.discussion,
              effectiveDate: discussion.date!,
              effectiveRepetitionCode: discussion.repetitionCode,
            ),
          );
        }
      } else {
        for (final point in discussion.points) {
          if (!point.finished) {
            allEvents.add(
              TimelineEvent(
                parentDiscussion: discussion,
                point: point,
                type: TimelineEventType.point,
                title: point.pointText,
                effectiveDate: point.date,
                effectiveRepetitionCode: point.repetitionCode,
              ),
            );
          }
        }
      }
    }

    if (allEvents.isEmpty) {
      _timelineData = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    allEvents.sort(
      (a, b) => DateTime.parse(
        a.effectiveDate,
      ).compareTo(DateTime.parse(b.effectiveDate)),
    );

    DateTime overallStartDate = DateTime.parse(allEvents.first.effectiveDate);
    DateTime overallEndDate = DateTime.parse(allEvents.last.effectiveDate);

    if (DateUtils.isSameDay(overallStartDate, overallEndDate)) {
      overallEndDate = overallStartDate.add(const Duration(days: 7));
    }

    final displayStartDate = _selectedDateRange?.start ?? overallStartDate;
    final displayEndDate = _selectedDateRange?.end ?? overallEndDate;

    final filteredEvents = allEvents.where((e) {
      final date = DateTime.tryParse(e.effectiveDate);
      if (date == null) return false;
      return !date.isBefore(DateUtils.dateOnly(displayStartDate)) &&
          !date.isAfter(DateUtils.dateOnly(displayEndDate));
    }).toList();

    for (final event in filteredEvents) {
      event.color = getColorForRepetitionCode(event.effectiveRepetitionCode);
    }

    final Map<DateTime, int> discussionCounts = {};
    for (var event in filteredEvents) {
      final dateOnly = DateUtils.dateOnly(DateTime.parse(event.effectiveDate));
      discussionCounts[dateOnly] = (discussionCounts[dateOnly] ?? 0) + 1;
    }

    final int totalDays = displayEndDate.difference(displayStartDate).inDays;

    _timelineData = TimelineData(
      events: filteredEvents,
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
