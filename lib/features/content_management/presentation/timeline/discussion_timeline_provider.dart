// lib/features/content_management/presentation/timeline/discussion_timeline_provider.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/discussion_model.dart';
import '../../domain/models/timeline_models.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';
import 'dialogs/reschedule_discussions_dialog.dart';
// ==> IMPORT SERVICE YANG DIPERLUKAN <==
import '../../domain/services/discussion_service.dart';

class DiscussionTimelineProvider with ChangeNotifier {
  // ==> TAMBAHKAN SERVICE DAN PATH <==
  final String _subjectJsonPath;
  final DiscussionService _discussionService = DiscussionService();

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

  // ==> PERBARUI KONSTRUKTOR <==
  DiscussionTimelineProvider(
    List<Discussion>? initialDiscussions,
    this._subjectJsonPath,
  ) {
    _allDiscussions = initialDiscussions ?? [];
    processDiscussions();
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
      // Jangan panggil notifyListeners di sini agar tidak rebuild saat proses masih berjalan
    }
  }

  Future<String> _balanceSchedule(int maxMoveDays) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final discussionsToReschedule =
        _allDiscussions.where((d) {
          if (d.effectiveDate == null) return false;
          final date = DateTime.tryParse(d.effectiveDate!);
          return date != null && !date.isBefore(today);
        }).toList()..sort(
          (a, b) => DateTime.parse(
            a.effectiveDate!,
          ).compareTo(DateTime.parse(b.effectiveDate!)),
        );

    if (discussionsToReschedule.length < 2) {
      return "Tidak cukup diskusi di masa depan untuk dijadwalkan ulang.";
    }

    final startDate = today;
    final endDate = DateTime.parse(discussionsToReschedule.last.effectiveDate!);
    final totalDays = endDate.difference(startDate).inDays;

    if (totalDays <= 0) {
      return "Rentang waktu tidak cukup untuk penjadwalan ulang.";
    }

    final double idealInterval =
        totalDays / (discussionsToReschedule.length - 1);
    int updatedCount = 0;

    for (int i = 0; i < discussionsToReschedule.length; i++) {
      final discussion = discussionsToReschedule[i];
      final originalDate = DateTime.parse(discussion.effectiveDate!);

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

      if (newDate.isBefore(today)) {
        newDate = today;
      }

      // ==> PERBAIKAN LOGIKA UPDATE TANGGAL <==
      // Langsung ubah tanggal pada objek discussion atau point
      if (discussion.points.isEmpty) {
        discussion.date = DateFormat('yyyy-MM-dd').format(newDate);
      } else {
        try {
          final pointToUpdate = discussion.points.firstWhere(
            (p) => p.date == discussion.effectiveDate,
          );
          pointToUpdate.date = DateFormat('yyyy-MM-dd').format(newDate);
        } catch (e) {
          // Fallback jika point tidak ditemukan (seharusnya tidak terjadi)
          discussion.date = DateFormat('yyyy-MM-dd').format(newDate);
        }
      }
      updatedCount++;
    }

    // ==> SIMPAN PERUBAHAN KE FILE <==
    await _discussionService.saveDiscussions(_subjectJsonPath, _allDiscussions);
    // Muat ulang data di provider ini setelah menyimpan
    processDiscussions();

    return "$updatedCount diskusi berhasil diseimbangkan jadwalnya.";
  }

  Future<String> _spreadSchedule() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final discussionsToReschedule =
        _allDiscussions.where((d) {
          if (d.effectiveDate == null) return false;
          final date = DateTime.tryParse(d.effectiveDate!);
          return date != null && !date.isBefore(today);
        }).toList()..sort(
          (a, b) => DateTime.parse(
            a.effectiveDate!,
          ).compareTo(DateTime.parse(b.effectiveDate!)),
        );

    if (discussionsToReschedule.length < 2) {
      return "Tidak cukup diskusi di masa depan untuk dijadwalkan ulang.";
    }

    final startDate = today;
    final endDate = DateTime.parse(discussionsToReschedule.last.effectiveDate!);
    final totalDays = endDate.difference(startDate).inDays;

    if (totalDays <= 0) {
      return "Rentang waktu tidak cukup untuk penjadwalan ulang.";
    }

    final double evenInterval =
        totalDays / (discussionsToReschedule.length - 1);
    int updatedCount = 0;

    for (int i = 0; i < discussionsToReschedule.length; i++) {
      final discussion = discussionsToReschedule[i];
      final newDate = startDate.add(Duration(days: (i * evenInterval).round()));

      // ==> PERBAIKAN LOGIKA UPDATE TANGGAL <==
      if (discussion.points.isEmpty) {
        discussion.date = DateFormat('yyyy-MM-dd').format(newDate);
      } else {
        try {
          final pointToUpdate = discussion.points.firstWhere(
            (p) => p.date == discussion.effectiveDate,
          );
          pointToUpdate.date = DateFormat('yyyy-MM-dd').format(newDate);
        } catch (e) {
          discussion.date = DateFormat('yyyy-MM-dd').format(newDate);
        }
      }
      updatedCount++;
    }

    // ==> SIMPAN PERUBAHAN KE FILE <==
    await _discussionService.saveDiscussions(_subjectJsonPath, _allDiscussions);
    processDiscussions();

    return "$updatedCount diskusi berhasil diratakan jadwalnya.";
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
