// lib/presentation/providers/discussion_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../domain/models/discussion_model.dart';
import '../domain/services/discussion_service.dart';
import '../../../data/services/path_service.dart';
import '../../../data/services/shared_preferences_service.dart';
import '../presentation/discussions/utils/repetition_code_utils.dart';
import 'mixins/discussion_actions_mixin.dart';
import 'mixins/discussion_filter_sort_mixin.dart';

class DiscussionProvider
    with ChangeNotifier, DiscussionFilterSortMixin, DiscussionActionsMixin {
  @override
  final DiscussionService discussionService = DiscussionService();
  @override
  final SharedPreferencesService prefsService = SharedPreferencesService();
  @override
  final PathService pathService = PathService();

  final String _jsonFilePath;
  @override
  final String? sourceSubjectLinkedPath;

  DiscussionProvider(this._jsonFilePath, {this.sourceSubjectLinkedPath}) {
    loadInitialData();
  }

  // CORE STATE
  bool _isLoading = true;
  @override
  bool get isLoading => _isLoading;

  List<Discussion> _allDiscussions = [];
  @override
  List<Discussion> get allDiscussions => _allDiscussions;
  @override
  set allDiscussions(List<Discussion> value) {
    _allDiscussions = value;
  }

  List<Discussion> _filteredDiscussions = [];
  @override
  List<Discussion> get filteredDiscussions => _filteredDiscussions;
  @override
  set filteredDiscussions(List<Discussion> value) {
    _filteredDiscussions = value;
  }

  final Set<Discussion> _selectedDiscussions = {};
  @override
  Set<Discussion> get selectedDiscussions => _selectedDiscussions;

  // GETTERS
  bool get isSelectionMode => _selectedDiscussions.isNotEmpty;

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

  // INITIALIZATION & DATA HANDLING
  Future<void> loadInitialData() async {
    await loadPreferences();
    await loadDiscussions();
  }

  Future<void> loadDiscussions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allDiscussions = await discussionService.loadDiscussions(_jsonFilePath);
      filterAndSortDiscussions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> saveDiscussions() async {
    await discussionService.saveDiscussions(_jsonFilePath, _allDiscussions);
  }

  // BASIC CRUD (Create, Read, Update, Delete)
  @override
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
      newFilePath = await discussionService.createDiscussionFile(
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
      filePath: newFilePath,
    );
    _allDiscussions.add(newDiscussion);
    filterAndSortDiscussions();
    await saveDiscussions();
  }

  @override
  void addPoint(
    Discussion discussion,
    String text, {
    bool inheritRepetitionCode = false,
  }) {
    final newPoint = Point(
      pointText: text,
      date: inheritRepetitionCode && discussion.date != null
          ? discussion.date!
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
      repetitionCode: inheritRepetitionCode ? discussion.repetitionCode : 'R0D',
    );
    discussion.points.add(newPoint);
    filterAndSortDiscussions();
    saveDiscussions();
  }

  @override
  Future<void> deleteDiscussion(Discussion discussion) async {
    final pathToDelete = discussion.filePath;
    _allDiscussions.removeWhere((d) => d.hashCode == discussion.hashCode);
    filterAndSortDiscussions();

    try {
      await saveDiscussions();
      if (pathToDelete != null) {
        await discussionService.deleteLinkedFile(pathToDelete);
      }
    } catch (e) {
      debugPrint("Error during discussion deletion process: $e");
      await loadInitialData();
      rethrow;
    }
  }

  @override
  void deletePoint(Discussion discussion, Point point) {
    discussion.points.removeWhere((p) => p.hashCode == point.hashCode);
    filterAndSortDiscussions();
    saveDiscussions();
  }

  @override
  void internalNotifyListeners() {
    notifyListeners();
  }
}
