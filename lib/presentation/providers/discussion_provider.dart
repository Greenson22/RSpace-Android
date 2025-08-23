// lib/presentation/providers/discussion_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../data/models/discussion_model.dart';
import '../../data/services/discussion_service.dart';
import '../../data/services/path_service.dart';
import '../../data/services/shared_preferences_service.dart';
import '../pages/3_discussions_page/utils/repetition_code_utils.dart';

class DiscussionProvider with ChangeNotifier {
  final DiscussionService _discussionService = DiscussionService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final PathService _pathService = PathService();

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

  bool _showFinishedDiscussions = false;
  bool get showFinishedDiscussions => _showFinishedDiscussions;

  final List<String> repetitionCodes = kRepetitionCodes;

  int get totalDiscussionCount => _allDiscussions.length;

  int get finishedDiscussionCount =>
      _allDiscussions.where((d) => d.finished).length;

  Map<String, int> get repetitionCodeCounts {
    final Map<String, int> counts = {};
    for (final discussion in _allDiscussions) {
      final code = discussion.effectiveRepetitionCode;
      counts[code] = (counts[code] ?? 0) + 1;
    }
    return counts;
  }

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

    final activeDiscussions = _allDiscussions
        .where((d) => !d.finished)
        .toList();
    final finishedDiscussions = _allDiscussions
        .where((d) => d.finished)
        .toList();

    List<Discussion> filteredActiveDiscussions = activeDiscussions.where((
      discussion,
    ) {
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

    filteredActiveDiscussions.sort((a, b) {
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
      filteredActiveDiscussions = filteredActiveDiscussions.reversed.toList();
    }

    _filteredDiscussions = filteredActiveDiscussions;

    if (_activeFilterType == null ||
        (_showFinishedDiscussions && _activeFilterType != 'code')) {
      final filteredFinished = finishedDiscussions
          .where((d) => d.discussion.toLowerCase().contains(query))
          .toList();
      _filteredDiscussions.addAll(filteredFinished);
    }

    if (_activeFilterType == 'code' && _selectedRepetitionCode == 'Finish') {
      _filteredDiscussions = finishedDiscussions
          .where((d) => d.discussion.toLowerCase().contains(query))
          .toList();
    }

    notifyListeners();
  }

  bool doesPointMatchFilter(Point point) {
    if (point.finished) return false;
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

  Future<String> getPerpuskuHtmlBasePath() async {
    final perpuskuPath = await _pathService.perpuskuDataPath;
    return path.join(perpuskuPath, 'file_contents', 'topics');
  }

  Future<void> updateDiscussionFilePath(
    Discussion discussion,
    String filePath,
  ) async {
    discussion.filePath = filePath;
    _filterAndSortDiscussions();
    await _saveDiscussions();
  }

  Future<void> removeDiscussionFilePath(Discussion discussion) async {
    discussion.filePath = null;
    _filterAndSortDiscussions();
    await _saveDiscussions();
  }

  Future<void> openDiscussionFile(Discussion discussion) async {
    if (discussion.filePath == null || discussion.filePath!.isEmpty) {
      throw Exception('Tidak ada path file yang ditentukan.');
    }

    try {
      final perpuskuPath = await _pathService.perpuskuDataPath;
      final basePath = path.join(perpuskuPath, 'file_contents', 'topics');
      final contentFilePath = path.join(basePath, discussion.filePath!);

      final subjectDirPath = path.dirname(contentFilePath);
      final indexFilePath = path.join(subjectDirPath, 'index.html');

      final contentFile = File(contentFilePath);
      final indexFile = File(indexFilePath);

      if (!await contentFile.exists()) {
        throw Exception('File konten tidak ditemukan: $contentFilePath');
      }
      if (!await indexFile.exists()) {
        throw Exception('File index.html tidak ditemukan di: $subjectDirPath');
      }

      final contentHtml = await contentFile.readAsString();
      final indexHtml = await indexFile.readAsString();

      final indexDocument = parse(indexHtml);
      final mainContainer = indexDocument.querySelector('#main-container');

      if (mainContainer == null) {
        throw Exception(
          'Elemen dengan id="main-container" tidak ditemukan di index.html',
        );
      }

      final contentDocument = parse(contentHtml);
      final images = contentDocument.querySelectorAll('img');

      for (var img in images) {
        final src = img.attributes['src'];
        if (src != null &&
            !src.startsWith('http') &&
            !src.startsWith('data:')) {
          final imagePath = path.join(subjectDirPath, src);
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            final imageBytes = await imageFile.readAsBytes();
            final base64Image = base64Encode(imageBytes);
            final mimeType = lookupMimeType(imagePath) ?? 'image/png';
            img.attributes['src'] = 'data:$mimeType;base64,$base64Image';
          }
        }
      }

      mainContainer.innerHtml = contentDocument.body?.innerHtml ?? '';

      final tempDir = await getTemporaryDirectory();
      final tempFileName = '${DateTime.now().millisecondsSinceEpoch}.html';
      final tempFile = File(path.join(tempDir.path, tempFileName));
      await tempFile.writeAsString(indexDocument.outerHtml);

      final result = await OpenFile.open(tempFile.path);

      if (result.type != ResultType.done) {
        throw Exception('Tidak dapat membuka file: ${result.message}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> editDiscussionFile(Discussion discussion) async {
    if (discussion.filePath == null || discussion.filePath!.isEmpty) {
      throw Exception('Tidak ada path file yang ditentukan untuk diedit.');
    }

    try {
      final perpuskuPath = await _pathService.perpuskuDataPath;
      final basePath = path.join(perpuskuPath, 'file_contents', 'topics');
      final contentFilePath = path.join(basePath, discussion.filePath!);

      final contentFile = File(contentFilePath);
      if (!await contentFile.exists()) {
        throw Exception('File konten tidak ditemukan: $contentFilePath');
      }

      if (Platform.isLinux) {
        final editor =
            Platform.environment['EDITOR'] ?? Platform.environment['VISUAL'];
        ProcessResult result;

        if (editor != null && editor.isNotEmpty) {
          result = await Process.run(editor, [
            contentFile.path,
          ], runInShell: true);
          if (result.exitCode == 0) return;
        }

        const commonEditors = ['gedit', 'kate', 'mousepad', 'code'];
        for (final ed in commonEditors) {
          result = await Process.run('which', [ed]);
          if (result.exitCode == 0) {
            result = await Process.run(ed, [
              contentFile.path,
            ], runInShell: true);
            if (result.exitCode == 0) return;
          }
        }

        result = await Process.run('xdg-open', [contentFile.path]);
        if (result.exitCode != 0) {
          throw Exception(
            'Gagal membuka file dengan semua metode: ${result.stderr}',
          );
        }
      } else {
        final result = await OpenFile.open(contentFile.path);
        if (result.type != ResultType.done) {
          throw Exception('Gagal membuka file untuk diedit: ${result.message}');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  void incrementRepetitionCode(dynamic item) {
    if (item is Discussion) {
      final currentCode = item.repetitionCode;
      final currentIndex = getRepetitionCodeIndex(currentCode);
      if (currentIndex < repetitionCodes.length - 1) {
        final newCode = repetitionCodes[currentIndex + 1];
        updateDiscussionCode(item, newCode);
      }
    } else if (item is Point) {
      final currentCode = item.repetitionCode;
      final currentIndex = getRepetitionCodeIndex(currentCode);
      if (currentIndex < repetitionCodes.length - 1) {
        final newCode = repetitionCodes[currentIndex + 1];
        updatePointCode(item, newCode);
      }
    }
  }

  void toggleShowFinished() {
    _showFinishedDiscussions = !_showFinishedDiscussions;
    _filterAndSortDiscussions();
  }

  void deleteDiscussion(Discussion discussion) {
    _allDiscussions.removeWhere((d) => d.hashCode == discussion.hashCode);
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  // ==> FUNGSI INI DIPERBARUI <==
  Future<void> addDiscussion(
    String name, {
    bool createHtmlFile = false,
    String? subjectLinkedPath,
  }) async {
    String? newFilePath;
    if (createHtmlFile) {
      if (subjectLinkedPath == null || subjectLinkedPath.isEmpty) {
        throw Exception(
          "Tidak dapat membuat file HTML karena Subject ini belum ditautkan ke folder PerpusKu.",
        );
      }
      final perpuskuBasePath = await getPerpuskuHtmlBasePath();
      newFilePath = await _discussionService.createDiscussionFile(
        perpuskuBasePath: perpuskuBasePath,
        subjectLinkedPath: subjectLinkedPath,
        discussionName: name,
      );
    }

    final newDiscussion = Discussion(
      discussion: name,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      repetitionCode: 'R0D',
      points: [],
      filePath: newFilePath, // Set path file jika dibuat
    );
    _allDiscussions.add(newDiscussion);
    _filterAndSortDiscussions();
    await _saveDiscussions();
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
      markPointAsFinished(point);
    }
    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void markPointAsFinished(Point point) {
    point.finished = true;
    point.finish_date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Discussion? parentDiscussion;
    for (final discussion in _allDiscussions) {
      if (discussion.points.contains(point)) {
        parentDiscussion = discussion;
        break;
      }
    }

    if (parentDiscussion != null) {
      final allPointsFinished = parentDiscussion.points.every(
        (p) => p.finished,
      );
      if (parentDiscussion.points.isNotEmpty && allPointsFinished) {
        markAsFinished(parentDiscussion);
      }
    }

    _filterAndSortDiscussions();
    _saveDiscussions();
  }

  void reactivatePoint(Point point) {
    point.finished = false;
    point.finish_date = null;
    point.date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    point.repetitionCode = 'R0D';

    Discussion? parentDiscussion;
    for (final discussion in _allDiscussions) {
      if (discussion.points.contains(point)) {
        parentDiscussion = discussion;
        break;
      }
    }

    if (parentDiscussion != null && parentDiscussion.finished) {
      reactivateDiscussion(parentDiscussion);
    }

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
    _showFinishedDiscussions = false;
    _prefsService.saveFilterPreference(null, null);
    _filterAndSortDiscussions();
  }
}
