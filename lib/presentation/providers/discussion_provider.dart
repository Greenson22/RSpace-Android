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

  void _filterAndSortDiscussions() {
    final query = _searchQuery.toLowerCase();
    _filteredDiscussions = _allDiscussions.where((discussion) {
      final matchesSearchQuery = discussion.discussion.toLowerCase().contains(
        query,
      );
      bool matchesFilter = true;
      if (_activeFilterType == 'code' && _selectedRepetitionCode != null) {
        matchesFilter =
            discussion.effectiveRepetitionCode == _selectedRepetitionCode;
      } else if (_activeFilterType == 'date' && _selectedDateRange != null) {
        try {
          if (discussion.effectiveDate == null) return false;

          final discussionDate = DateTime.parse(discussion.effectiveDate!);

          // **PERUBAHAN:** Normalisasi tanggal diskusi untuk menghapus komponen waktu
          final normalizedDiscussionDate = DateTime(
            discussionDate.year,
            discussionDate.month,
            discussionDate.day,
          );

          final startDate = _selectedDateRange!.start;
          final endDate = _selectedDateRange!.end;

          // **PERUBAHAN:** Logika perbandingan yang lebih kuat untuk rentang inklusif
          // Apakah tanggal diskusi TIDAK SEBELUM tanggal mulai (artinya, sama atau sesudah)
          // DAN
          // Apakah tanggal diskusi TIDAK SESUDAH tanggal akhir (artinya, sama atau sebelum)
          matchesFilter =
              !normalizedDiscussionDate.isBefore(startDate) &&
              !normalizedDiscussionDate.isAfter(endDate);
        } catch (e) {
          matchesFilter = false;
        }
      }
      return matchesSearchQuery && matchesFilter;
    }).toList();
    _sortDiscussions();
    notifyListeners();
  }

  void _sortDiscussions() {
    _sortList(_filteredDiscussions);
    _sortList(_allDiscussions);
    notifyListeners();
  }

  void _sortList(List<Discussion> list) {
    Comparator<Discussion> comparator;
    switch (_sortType) {
      case 'name':
        comparator = (a, b) =>
            a.discussion.toLowerCase().compareTo(b.discussion.toLowerCase());
        break;
      case 'code':
        comparator = (a, b) => getRepetitionCodeIndex(
          a.effectiveRepetitionCode,
        ).compareTo(getRepetitionCodeIndex(b.effectiveRepetitionCode));
        break;
      default: // date
        comparator = (a, b) {
          if (a.effectiveDate == null && b.effectiveDate == null) return 0;
          if (a.effectiveDate == null) return _sortAscending ? 1 : -1;
          if (b.effectiveDate == null) return _sortAscending ? -1 : 1;
          return DateTime.parse(
            a.effectiveDate!,
          ).compareTo(DateTime.parse(b.effectiveDate!));
        };
        break;
    }

    list.sort(comparator);
    if (!_sortAscending) {
      _filteredDiscussions = _filteredDiscussions.reversed.toList();
      _allDiscussions = _allDiscussions.reversed.toList();
    }
  }

  // FUNGSI BARU UNTUK MEMERIKSA POINT TERHADAP FILTER AKTIF
  bool doesPointMatchFilter(Point point) {
    // Jika tidak ada filter, semua point cocok
    if (_activeFilterType == null) {
      return true;
    }

    // Logika filter berdasarkan kode
    if (_activeFilterType == 'code' && _selectedRepetitionCode != null) {
      return point.repetitionCode == _selectedRepetitionCode;
    }
    // Logika filter berdasarkan tanggal
    else if (_activeFilterType == 'date' && _selectedDateRange != null) {
      try {
        final pointDate = DateTime.parse(point.date);
        final normalizedPointDate = DateTime(
          pointDate.year,
          pointDate.month,
          pointDate.day,
        );
        final startDate = _selectedDateRange!.start;
        final endDate = _selectedDateRange!.end;
        // Memeriksa apakah tanggal point berada dalam rentang yang dipilih
        return !normalizedPointDate.isBefore(startDate) &&
            !normalizedPointDate.isAfter(endDate);
      } catch (e) {
        return false;
      }
    }
    // Jika tipe filter tidak diketahui, anggap saja cocok
    return true;
  }

  // --- ACTIONS ---

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
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void updatePointCode(Point point, String newCode) {
    point.repetitionCode = newCode;
    point.date = getNewDateForRepetitionCode(newCode);
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
