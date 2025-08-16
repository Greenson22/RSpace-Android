import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/discussion_model.dart';
import '../../data/services/discussion_service.dart';
import '../../data/services/shared_preferences_service.dart';
import '../pages/3_discussions_page/utils/repetition_code_utils.dart';

class DiscussionProvider with ChangeNotifier {
  final DiscussionService _discussionService = DiscussionService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  final String _jsonFilePath;

  DiscussionProvider(this._jsonFilePath) {
    loadInitialData();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Discussion> _allDiscussions = [];
  List<Discussion> get allDiscussions => _allDiscussions;

  List<Discussion> _filteredDiscussions = [];
  List<Discussion> get filteredDiscussions => _filteredDiscussions;

  String _searchQuery = '';
  set searchQuery(String value) {
    _searchQuery = value;
    _filterAndSortDiscussions();
  }

  String? _activeFilterType;
  String? get activeFilterType => _activeFilterType;

  String? _selectedRepetitionCode;
  DateTimeRange? _selectedDateRange;

  String _sortType = 'date';
  String get sortType => _sortType;

  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;

  final List<String> repetitionCodes = kRepetitionCodes;

  // --- DATA LOGIC ---

  Future<void> loadInitialData() async {
    await _loadPreferences();
    await _loadDiscussions();
  }

  Future<void> _loadPreferences() async {
    final sortPrefs = await _prefsService.loadSortPreferences();
    _sortType = sortPrefs['sortType'];
    _sortAscending = sortPrefs['sortAscending'];

    final filterPrefs = await _prefsService.loadFilterPreference();
    _activeFilterType = filterPrefs['filterType'];
    if (_activeFilterType == 'code') {
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

  Future<void> _loadDiscussions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allDiscussions = await _discussionService.loadDiscussions(_jsonFilePath);
      _filterAndSortDiscussions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveDiscussions() async {
    await _discussionService.saveDiscussions(_jsonFilePath, _allDiscussions);
  }

  Map<String, String?> _getEffectiveDiscussionInfoForSorting(
    Discussion discussion,
  ) {
    if (discussion.finished) {
      return {'date': discussion.finish_date, 'code': 'Finish'};
    }

    // ==> Diubah: Filter poin yang belum selesai dan sesuai filter UI <==
    final visiblePoints = discussion.points
        .where((point) => !point.finished && doesPointMatchFilter(point))
        .toList();

    if (visiblePoints.isNotEmpty) {
      int minCodeIndex = 999;
      for (var point in visiblePoints) {
        final codeIndex = getRepetitionCodeIndex(point.repetitionCode);
        if (codeIndex < minCodeIndex) {
          minCodeIndex = codeIndex;
        }
      }

      final lowestCodePoints = visiblePoints
          .where(
            (point) =>
                getRepetitionCodeIndex(point.repetitionCode) == minCodeIndex,
          )
          .toList();

      lowestCodePoints.sort((a, b) {
        final dateA = DateTime.tryParse(a.date);
        final dateB = DateTime.tryParse(b.date);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });

      if (lowestCodePoints.isNotEmpty) {
        final relevantPoint = lowestCodePoints.first;
        return {
          'date': relevantPoint.date,
          'code': relevantPoint.repetitionCode,
        };
      }
    }

    return {
      'date': discussion.effectiveDate,
      'code': discussion.effectiveRepetitionCode,
    };
  }

  void _filterAndSortDiscussions() {
    final query = _searchQuery.toLowerCase();
    _filteredDiscussions = _allDiscussions.where((discussion) {
      final matchesSearchQuery = discussion.discussion.toLowerCase().contains(
        query,
      );
      if (!matchesSearchQuery) return false;

      bool matchesFilter = true;
      final effectiveInfo = _getEffectiveDiscussionInfoForSorting(discussion);
      final effectiveDate = effectiveInfo['date'];
      final effectiveCode = effectiveInfo['code'];

      if (_activeFilterType == 'code' && _selectedRepetitionCode != null) {
        matchesFilter = effectiveCode == _selectedRepetitionCode;
      } else if (_activeFilterType == 'date' && _selectedDateRange != null) {
        try {
          if (effectiveDate == null) return false;
          final discussionDate = DateTime.parse(effectiveDate);
          final normalizedDiscussionDate = DateTime(
            discussionDate.year,
            discussionDate.month,
            discussionDate.day,
          );
          final startDate = _selectedDateRange!.start;
          final endDate = _selectedDateRange!.end;
          matchesFilter =
              !normalizedDiscussionDate.isBefore(startDate) &&
              !normalizedDiscussionDate.isAfter(endDate);
        } catch (e) {
          matchesFilter = false;
        }
      }
      return matchesFilter;
    }).toList();

    _filteredDiscussions.sort((a, b) {
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
          final codeA = infoA['code'] ?? '';
          final codeB = infoB['code'] ?? '';
          result = getRepetitionCodeIndex(
            codeA,
          ).compareTo(getRepetitionCodeIndex(codeB));
          break;
        default: // date
          final dateA = infoA['date'];
          final dateB = infoB['date'];
          if (dateA == null && dateB == null) {
            result = 0;
          } else if (dateA == null) {
            result = 1;
          } else if (dateB == null) {
            result = -1;
          } else {
            result = DateTime.parse(dateA).compareTo(DateTime.parse(dateB));
          }
          break;
      }
      return result;
    });

    if (!_sortAscending) {
      _filteredDiscussions = _filteredDiscussions.reversed.toList();
    }

    notifyListeners();
  }

  bool doesPointMatchFilter(Point point) {
    if (point.finished) return false; // Jangan tampilkan poin selesai
    if (_activeFilterType == null) {
      return true;
    }
    if (_activeFilterType == 'code' && _selectedRepetitionCode != null) {
      return point.repetitionCode == _selectedRepetitionCode;
    } else if (_activeFilterType == 'date' && _selectedDateRange != null) {
      try {
        final pointDate = DateTime.parse(point.date);
        final normalizedPointDate = DateTime(
          pointDate.year,
          pointDate.month,
          pointDate.day,
        );
        final startDate = _selectedDateRange!.start;
        final endDate = _selectedDateRange!.end;
        return !normalizedPointDate.isBefore(startDate) &&
            !normalizedPointDate.isAfter(endDate);
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  // --- ACTIONS ---

  void deleteDiscussion(Discussion discussion) {
    _allDiscussions.removeWhere((d) => d.hashCode == discussion.hashCode);
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void addDiscussion(String name) {
    final newDiscussion = Discussion(
      discussion: name,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      repetitionCode: 'R0D',
      points: [],
    );
    _allDiscussions.add(newDiscussion);
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void addPoint(Discussion discussion, String text) {
    final newPoint = Point(
      pointText: text,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      repetitionCode: 'R0D',
    );
    discussion.points.add(newPoint);
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void deletePoint(Discussion discussion, Point point) {
    discussion.points.removeWhere((p) => p.hashCode == point.hashCode);
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void updateDiscussionDate(Discussion discussion, DateTime newDate) {
    discussion.date = DateFormat('yyyy-MM-dd').format(newDate);
    if (discussion.finished) {
      discussion.finished = false;
      discussion.finish_date = null;
      if (discussion.repetitionCode == 'Finish') {
        discussion.repetitionCode = 'R0D';
      }
    }
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void updateDiscussionCode(Discussion discussion, String newCode) {
    discussion.repetitionCode = newCode;
    if (newCode != 'Finish') {
      discussion.date = getNewDateForRepetitionCode(newCode);
      if (discussion.finished) {
        discussion.finished = false;
        discussion.finish_date = null;
      }
    } else {
      markAsFinished(discussion);
    }
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void renameDiscussion(Discussion discussion, String newName) {
    discussion.discussion = newName;
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void markAsFinished(Discussion discussion) {
    discussion.finished = true;
    discussion.finish_date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void reactivateDiscussion(Discussion discussion) {
    discussion.finished = false;
    discussion.finish_date = null;
    discussion.date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    discussion.repetitionCode = 'R0D';
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void updatePointDate(Point point, DateTime newDate) {
    point.date = DateFormat('yyyy-MM-dd').format(newDate);
    if (point.finished) {
      point.finished = false;
      point.finish_date = null;
      if (point.repetitionCode == 'Finish') {
        point.repetitionCode = 'R0D';
      }
    }
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void updatePointCode(Point point, String newCode) {
    point.repetitionCode = newCode;
    if (newCode != 'Finish') {
      point.date = getNewDateForRepetitionCode(newCode);
      if (point.finished) {
        point.finished = false;
        point.finish_date = null;
      }
    } else {
      markPointAsFinished(point); // Panggil fungsi baru
    }
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  // ==> FUNGSI BARU UNTUK POINT <==
  void markPointAsFinished(Point point) {
    point.finished = true;
    point.finish_date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  // ==> FUNGSI BARU UNTUK POINT <==
  void reactivatePoint(Point point) {
    point.finished = false;
    point.finish_date = null;
    point.date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    point.repetitionCode = 'R0D';
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void renamePoint(Point point, String newName) {
    point.pointText = newName;
    notifyListeners();
    _saveDiscussions();
  }

  void applySort(String sortType, bool sortAscending) {
    _sortType = sortType;
    _sortAscending = sortAscending;
    _prefsService.saveSortPreferences(_sortType, _sortAscending);
    _filterAndSortDiscussions();
  }

  void applyCodeFilter(String code) {
    _activeFilterType = 'code';
    _selectedRepetitionCode = code;
    _selectedDateRange = null;
    _prefsService.saveFilterPreference('code', code);
    _filterAndSortDiscussions();
  }

  void applyDateFilter(DateTimeRange range) {
    _activeFilterType = 'date';
    _selectedDateRange = range;
    _selectedRepetitionCode = null;
    final dateRangeString =
        '${range.start.toIso8601String()}/${range.end.toIso8601String()}';
    _prefsService.saveFilterPreference('date', dateRangeString);
    _filterAndSortDiscussions();
  }

  void clearFilters() {
    _activeFilterType = null;
    _selectedRepetitionCode = null;
    _selectedDateRange = null;
    _prefsService.saveFilterPreference(null, null);
    _filterAndSortDiscussions();
  }
}
