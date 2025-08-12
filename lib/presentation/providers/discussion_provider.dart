import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/discussion_model.dart';
import '../../data/services/discussion_service.dart'; // DIUBAH: Menggunakan discussion_service
import '../../data/services/shared_preferences_service.dart'; // DIUBAH: Menggunakan shared_preferences_service
import '../pages/3_discussions_page/utils/repetition_code_utils.dart';

class DiscussionProvider with ChangeNotifier {
  // DIUBAH: Menggunakan DiscussionService secara langsung
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

  final List<String> repetitionCodes = const [
    'R0D',
    'R1D',
    'R3D',
    'R7D',
    'R7D2',
    'R7D3',
    'R30D',
    'Finish',
  ];

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
      // DIUBAH: Memanggil _discussionService
      _allDiscussions = await _discussionService.loadDiscussions(_jsonFilePath);
      _filterAndSortDiscussions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveDiscussions() async {
    // DIUBAH: Memanggil _discussionService
    await _discussionService.saveDiscussions(_jsonFilePath, _allDiscussions);
    // Tidak perlu notifyListeners() di sini kecuali ada state loading untuk save
  }

  void _filterAndSortDiscussions() {
    final query = _searchQuery.toLowerCase();
    _filteredDiscussions = _allDiscussions.where((discussion) {
      final matchesSearchQuery = discussion.discussion.toLowerCase().contains(
        query,
      );
      bool matchesFilter = true;
      if (_activeFilterType == 'code' && _selectedRepetitionCode != null) {
        matchesFilter = discussion.repetitionCode == _selectedRepetitionCode;
      } else if (_activeFilterType == 'date' && _selectedDateRange != null) {
        try {
          if (discussion.date == null) return false;
          final discussionDate = DateTime.parse(discussion.date!);
          final startDate = _selectedDateRange!.start;
          final endDate = _selectedDateRange!.end.add(const Duration(days: 1));
          matchesFilter =
              discussionDate.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              discussionDate.isBefore(endDate);
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
    notifyListeners(); // Ditambahkan untuk memastikan UI update setelah sorting
  }

  void _sortList(List<Discussion> list) {
    Comparator<Discussion> comparator;
    switch (_sortType) {
      case 'name':
        comparator = (a, b) =>
            a.discussion.toLowerCase().compareTo(b.discussion.toLowerCase());
        break;
      case 'code':
        comparator = (a, b) => a.repetitionCode.compareTo(b.repetitionCode);
        break;
      default: // date
        comparator = (a, b) {
          if (a.date == null && b.date == null) return 0;
          if (a.date == null) return _sortAscending ? 1 : -1;
          if (b.date == null) return _sortAscending ? -1 : 1;
          return DateTime.parse(a.date!).compareTo(DateTime.parse(b.date!));
        };
        break;
    }

    // DIUBAH: Logika sorting yang lebih benar
    list.sort(comparator);
    if (!_sortAscending) {
      _filteredDiscussions = _filteredDiscussions.reversed.toList();
      _allDiscussions = _allDiscussions.reversed.toList();
    }
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
    notifyListeners();
    _saveDiscussions();
  }

  void updateDiscussionDate(Discussion discussion, DateTime newDate) {
    discussion.date = DateFormat('yyyy-MM-dd').format(newDate);
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void updateDiscussionCode(Discussion discussion, String newCode) {
    discussion.repetitionCode = newCode;
    if (newCode != 'Finish') {
      discussion.date = getNewDateForRepetitionCode(newCode);
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
    discussion.repetitionCode = 'Finish';
    discussion.finish_date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    discussion.date = null;
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void updatePointDate(Point point, DateTime newDate) {
    point.date = DateFormat('yyyy-MM-dd').format(newDate);
    notifyListeners();
    _saveDiscussions();
  }

  void updatePointCode(Point point, String newCode) {
    point.repetitionCode = newCode;
    point.date = getNewDateForRepetitionCode(newCode);
    notifyListeners();
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
