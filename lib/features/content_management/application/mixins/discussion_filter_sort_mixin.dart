// lib/presentation/providers/mixins/discussion_filter_sort_mixin.dart

import 'package:flutter/material.dart';
import '../../domain/models/discussion_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';

mixin DiscussionFilterSortMixin on ChangeNotifier {
  // DEPENDENCIES
  SharedPreferencesService get prefsService;
  List<Discussion> get allDiscussions;
  List<Discussion> get filteredDiscussions;
  set filteredDiscussions(List<Discussion> value);

  // STATE
  String _searchQuery = '';
  set searchQuery(String value) {
    _searchQuery = value;
    filterAndSortDiscussions();
  }

  String? _activeFilterType;
  String? get activeFilterType => _activeFilterType;

  String? _selectedRepetitionCode;
  DateTimeRange? _selectedDateRange;

  String _sortType = 'date';
  String get sortType => _sortType;

  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;

  bool _showFinishedDiscussions = false;
  bool get showFinishedDiscussions => _showFinishedDiscussions;

  // METHODS
  Future<void> loadPreferences() async {
    final sortPrefs = await prefsService.loadSortPreferences();
    _sortType = sortPrefs['sortType'];
    _sortAscending = sortPrefs['sortAscending'];

    final filterPrefs = await prefsService.loadFilterPreference();
    _activeFilterType = filterPrefs['filterType'];

    if (_activeFilterType == 'date_today_and_before') {
      _activeFilterType = 'date';
      final now = DateTime.now();
      _selectedDateRange = DateTimeRange(
        start: DateTime(2000),
        end: DateTime(now.year, now.month, now.day),
      );
    } else if (_activeFilterType == 'code') {
      _selectedRepetitionCode = filterPrefs['filterValue'];
    } else if (_activeFilterType == 'date' &&
        filterPrefs['filterValue'] != null) {
      final dates = filterPrefs['filterValue']!.split('/');
      _selectedDateRange = DateTimeRange(
        start: DateTime.parse(dates[0]),
        end: DateTime.parse(dates[1]),
      );
    }
    notifyListeners();
  }

  void filterAndSortDiscussions() {
    final query = _searchQuery.toLowerCase();
    final activeDiscussions = allDiscussions.where((d) => !d.finished).toList();
    final finishedDiscussions = allDiscussions
        .where((d) => d.finished)
        .toList();

    List<Discussion> filteredActive = activeDiscussions.where((discussion) {
      if (!discussion.discussion.toLowerCase().contains(query)) return false;

      final info = _getEffectiveDiscussionInfoForSorting(discussion);
      final date = info['date'];
      final code = info['code'];

      if (_activeFilterType == 'code' && _selectedRepetitionCode != null) {
        return code == _selectedRepetitionCode;
      } else if (_activeFilterType == 'date' && _selectedDateRange != null) {
        if (date == null) return false;
        try {
          final dDate = DateTime.parse(date);
          return !dDate.isBefore(_selectedDateRange!.start) &&
              !dDate.isAfter(_selectedDateRange!.end);
        } catch (e) {
          return false;
        }
      }
      return true;
    }).toList();

    filteredActive.sort((a, b) {
      final infoA = _getEffectiveDiscussionInfoForSorting(a);
      final infoB = _getEffectiveDiscussionInfoForSorting(b);
      int result;
      switch (_sortType) {
        case 'name':
          result = a.discussion.toLowerCase().compareTo(
            b.discussion.toLowerCase(),
          );
          break;
        case 'code':
          result = getRepetitionCodeIndex(
            infoA['code'] ?? '',
          ).compareTo(getRepetitionCodeIndex(infoB['code'] ?? ''));
          break;
        default:
          final dateA = infoA['date'];
          final dateB = infoB['date'];
          if (dateA == null && dateB == null)
            result = 0;
          else if (dateA == null)
            result = 1;
          else if (dateB == null)
            result = -1;
          else
            result = DateTime.parse(dateA).compareTo(DateTime.parse(dateB));
          break;
      }
      return result;
    });

    if (!_sortAscending) {
      filteredActive = filteredActive.reversed.toList();
    }

    filteredDiscussions = filteredActive;

    if (_showFinishedDiscussions &&
        (_activeFilterType != 'code' || _selectedRepetitionCode == 'Finish')) {
      final filteredFinished = finishedDiscussions
          .where((d) => d.discussion.toLowerCase().contains(query))
          .toList();
      if (_selectedRepetitionCode == 'Finish') {
        filteredDiscussions = filteredFinished;
      } else {
        filteredDiscussions.addAll(filteredFinished);
      }
    }

    notifyListeners();
  }

  Map<String, String?> _getEffectiveDiscussionInfoForSorting(
    Discussion discussion,
  ) {
    if (discussion.finished)
      return {'date': discussion.finish_date, 'code': 'Finish'};

    final visiblePoints = discussion.points
        .where((p) => !p.finished && doesPointMatchFilter(p))
        .toList();

    if (visiblePoints.isNotEmpty) {
      visiblePoints.sort((a, b) {
        int codeComp = getRepetitionCodeIndex(
          a.repetitionCode,
        ).compareTo(getRepetitionCodeIndex(b.repetitionCode));
        if (codeComp != 0) return codeComp;
        try {
          return DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
        } catch (e) {
          return 0;
        }
      });
      final relevantPoint = visiblePoints.first;
      return {'date': relevantPoint.date, 'code': relevantPoint.repetitionCode};
    }
    return {
      'date': discussion.effectiveDate,
      'code': discussion.effectiveRepetitionCode,
    };
  }

  bool doesPointMatchFilter(Point point) {
    if (point.finished) return false;
    if (_activeFilterType == 'code') {
      return point.repetitionCode == _selectedRepetitionCode;
    } else if (_activeFilterType == 'date' && _selectedDateRange != null) {
      try {
        final pDate = DateTime.parse(point.date);
        return !pDate.isBefore(_selectedDateRange!.start) &&
            !pDate.isAfter(_selectedDateRange!.end);
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  void applySort(String sortType, bool sortAscending) {
    _sortType = sortType;
    _sortAscending = sortAscending;
    prefsService.saveSortPreferences(_sortType, _sortAscending);
    filterAndSortDiscussions();
  }

  void applyCodeFilter(String code) {
    _activeFilterType = 'code';
    _selectedRepetitionCode = code;
    _selectedDateRange = null;
    prefsService.saveFilterPreference('code', code);
    filterAndSortDiscussions();
  }

  void applyDateFilter(DateTimeRange range) {
    _activeFilterType = 'date';
    _selectedDateRange = range;
    _selectedRepetitionCode = null;
    final dateRangeString =
        '${range.start.toIso8601String()}/${range.end.toIso8601String()}';
    prefsService.saveFilterPreference('date', dateRangeString);
    filterAndSortDiscussions();
  }

  void applyTodayAndBeforeFilter() {
    _activeFilterType = 'date';
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(2000),
      end: DateTime(now.year, now.month, now.day),
    );
    _selectedRepetitionCode = null;
    prefsService.saveFilterPreference('date_today_and_before', null);
    filterAndSortDiscussions();
  }

  void clearFilters() {
    _activeFilterType = null;
    _selectedRepetitionCode = null;
    _selectedDateRange = null;
    _showFinishedDiscussions = false;
    prefsService.saveFilterPreference(null, null);
    filterAndSortDiscussions();
  }

  void toggleShowFinished() {
    _showFinishedDiscussions = !_showFinishedDiscussions;
    filterAndSortDiscussions();
  }
}
