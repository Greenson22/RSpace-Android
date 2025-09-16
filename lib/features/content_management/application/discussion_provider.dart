// lib/features/content_management/application/discussion_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';
import '../domain/models/discussion_model.dart';
import '../domain/models/point_preset_model.dart';
import '../domain/services/discussion_service.dart';
import '../domain/services/point_preset_service.dart';
import '../../../core/services/path_service.dart';
import '../../../core/services/storage_service.dart';
import 'mixins/discussion_actions_mixin.dart';
import 'mixins/discussion_filter_sort_mixin.dart';

class DiscussionProvider
    with ChangeNotifier, DiscussionFilterSortMixin, DiscussionActionsMixin {
  @override
  final DiscussionService discussionService = DiscussionService();
  final PointPresetService _pointPresetService = PointPresetService();
  @override
  final SharedPreferencesService prefsService = SharedPreferencesService();
  @override
  final PathService pathService = PathService();

  final String _jsonFilePath;
  @override
  final String? sourceSubjectLinkedPath;

  DiscussionProvider(
    this._jsonFilePath, {
    this.sourceSubjectLinkedPath,
    String? linkedPath,
  }) {
    loadInitialData();
  }

  // CORE STATE
  bool _isLoading = true;
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

  List<PointPreset> _pointPresets = [];
  List<PointPreset> get pointPresets => _pointPresets;

  List<String> _repetitionCodeOrder = [];
  List<String> get repetitionCodeOrder => _repetitionCodeOrder;

  // ==> STATE BARU UNTUK MENYIMPAN BOBOT HARI <==
  Map<String, int> _repetitionCodeDays = {};

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
    await _loadPointPresets();
  }

  Future<void> _loadPointPresets() async {
    _pointPresets = await _pointPresetService.loadPresets();
    notifyListeners();
  }

  Future<void> _savePointPresets() async {
    await _pointPresetService.savePresets(_pointPresets);
    notifyListeners();
  }

  Future<void> loadDiscussions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allDiscussions = await discussionService.loadDiscussions(_jsonFilePath);
      _repetitionCodeOrder = await prefsService.loadRepetitionCodeOrder();
      // ==> MUAT BOBOT HARI <==
      _repetitionCodeDays = await prefsService.loadRepetitionCodeDays();
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

  Future<void> saveRepetitionCodeOrder(List<String> newOrder) async {
    _repetitionCodeOrder = newOrder;
    await prefsService.saveRepetitionCodeOrder(newOrder);
    filterAndSortDiscussions();
  }

  // PRESET ACTIONS
  Future<void> addPointPreset(String name) async {
    final newId =
        (_pointPresets.isEmpty
            ? 0
            : _pointPresets.map((p) => p.id).reduce((a, b) => a > b ? a : b)) +
        1;
    _pointPresets.add(PointPreset(id: newId, name: name));
    await _savePointPresets();
  }

  Future<void> updatePointPreset(PointPreset preset, String newName) async {
    final presetToUpdate = _pointPresets.firstWhere((p) => p.id == preset.id);
    presetToUpdate.name = newName;
    await _savePointPresets();
  }

  Future<void> deletePointPreset(PointPreset preset) async {
    _pointPresets.removeWhere((p) => p.id == preset.id);
    await _savePointPresets();
  }

  // BASIC CRUD (Create, Read, Update, Delete)
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

    await prefsService.saveNeurons(10);

    filterAndSortDiscussions();
    await saveDiscussions();
  }

  void addPoint(
    Discussion discussion,
    String text, {
    required String repetitionCode,
  }) {
    final newPoint = Point(
      pointText: text,
      date: discussion.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      repetitionCode: repetitionCode,
    );
    discussion.points.add(newPoint);
    filterAndSortDiscussions();
    saveDiscussions();
  }

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

  void deletePoint(Discussion discussion, Point point) {
    discussion.points.removeWhere((p) => p.hashCode == point.hashCode);
    filterAndSortDiscussions();
    saveDiscussions();
  }

  // ==> PERBARUI FUNGSI YANG MEMANGGIL getNewDateForRepetitionCode <==
  @override
  void updateDiscussionCode(Discussion discussion, String newCode) {
    discussion.repetitionCode = newCode;
    if (newCode != 'Finish') {
      discussion.date = getNewDateForRepetitionCode(
        newCode,
        _repetitionCodeDays,
      );
      if (discussion.finished) {
        discussion.finished = false;
        discussion.finish_date = null;
      }
    } else {
      markAsFinished(discussion);
    }
    filterAndSortDiscussions();
    saveDiscussions();
  }

  @override
  void updatePointCode(Point point, String newCode) {
    point.repetitionCode = newCode;
    if (newCode != 'Finish') {
      point.date = getNewDateForRepetitionCode(newCode, _repetitionCodeDays);
      if (point.finished) {
        point.finished = false;
        point.finish_date = null;
      }
    } else {
      markPointAsFinished(point);
    }
    filterAndSortDiscussions();
    saveDiscussions();
  }

  @override
  void internalNotifyListeners() {
    notifyListeners();
  }
}
