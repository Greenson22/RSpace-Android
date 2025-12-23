// lib/features/content_management/application/discussion_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/dialogs/add_discussion_dialog.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';
// ==> IMPORT DIPERBARUI
import 'package:my_aplication/features/settings/application/services/gemini_service_flutter_gemini.dart';
import 'package:path/path.dart' as path;
import '../domain/models/discussion_model.dart';
import '../domain/models/point_preset_model.dart';
import '../domain/services/discussion_service.dart';
import '../domain/services/point_preset_service.dart';
import '../../../core/services/path_service.dart';
import '../../../core/services/storage_service.dart';
import 'mixins/discussion_actions_mixin.dart';
import 'mixins/discussion_filter_sort_mixin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_aplication/features/quiz/application/quiz_service.dart';
import 'package:my_aplication/features/quiz/presentation/dialogs/quiz_picker_dialog.dart';
// Import dialog move discussion
import '../presentation/discussions/dialogs/move_discussion_dialog.dart';
// Import dialog lain yang mungkin dibutuhkan dari discussion_dialogs
import '../presentation/discussions/dialogs/discussion_dialogs.dart';
// Import provider neuron dan utils snackbar
import '../../../../core/providers/neuron_provider.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';

class DiscussionProvider
    with ChangeNotifier, DiscussionFilterSortMixin, DiscussionActionsMixin {
  @override
  final DiscussionService discussionService = DiscussionService();
  final PointPresetService _pointPresetService = PointPresetService();
  final QuizService _quizService = QuizService();
  // ==> INSTANCE & IMPORT DIPERBARUI
  final GeminiServiceFlutterGemini _geminiService =
      GeminiServiceFlutterGemini();
  @override
  final SharedPreferencesService prefsService = SharedPreferencesService();
  @override
  final PathService pathService = PathService();

  final String _jsonFilePath;
  @override
  final String? sourceSubjectLinkedPath;
  final Subject subject;

  DiscussionProvider(
    this._jsonFilePath, {
    String? linkedPath,
    required this.subject,
  }) : sourceSubjectLinkedPath = linkedPath {
    loadInitialData();
  }

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
  @override
  List<String> get repetitionCodeOrder => _repetitionCodeOrder;

  Map<String, int> _repetitionCodeDays = {};

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

  Future<void> reorderPoints(
    Discussion discussion,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final point = discussion.points.removeAt(oldIndex);
    discussion.points.insert(newIndex, point);

    await saveDiscussions();
    notifyListeners();
  }

  List<Point> getSortedPoints(Discussion discussion) {
    final allPoints = List<Point>.from(discussion.points);

    if (sortType == 'position') {
      return allPoints;
    }

    allPoints.sort((a, b) {
      int result;
      switch (sortType) {
        case 'name':
          result = a.pointText.toLowerCase().compareTo(
            b.pointText.toLowerCase(),
          );
          break;
        case 'code':
          result =
              getRepetitionCodeIndex(
                a.repetitionCode,
                customOrder: repetitionCodeOrder,
              ).compareTo(
                getRepetitionCodeIndex(
                  b.repetitionCode,
                  customOrder: repetitionCodeOrder,
                ),
              );
          break;
        default: // date
          final dateA = DateTime.tryParse(a.date);
          final dateB = DateTime.tryParse(b.date);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return sortAscending ? 1 : -1;
          if (dateB == null) return sortAscending ? -1 : 1;
          result = dateA.compareTo(dateB);
          break;
      }
      return result;
    });

    if (!sortAscending) {
      return allPoints.reversed.toList();
    }
    return allPoints;
  }

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
      if (subject.isLocked && subject.discussions.isNotEmpty) {
        _allDiscussions = subject.discussions;
      } else {
        _allDiscussions = await discussionService.loadDiscussions(
          _jsonFilePath,
        );
      }

      _repetitionCodeOrder = await prefsService.loadRepetitionCodeOrder();
      _repetitionCodeDays = await prefsService.loadRepetitionCodeDays();
      filterAndSortDiscussions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> saveDiscussions() async {
    if (subject.isLocked) {
      debugPrint("Save skipped: Subject is locked and in-memory only.");
      return;
    }
    await discussionService.saveDiscussions(_jsonFilePath, _allDiscussions);
  }

  Future<void> saveRepetitionCodeOrder(List<String> newOrder) async {
    _repetitionCodeOrder = newOrder;
    await prefsService.saveRepetitionCodeOrder(newOrder);
    filterAndSortDiscussions();
  }

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

  Future<void> addDiscussion(AddDiscussionResult result) async {
    String? filePathValue;
    String? quizNameValue;

    if (result.linkType == DiscussionLinkType.html) {
      if (sourceSubjectLinkedPath == null || sourceSubjectLinkedPath!.isEmpty) {
        throw Exception(
          "Tidak dapat membuat file karena Subject ini belum ditautkan ke folder PerpusKu.",
        );
      }
      final createdFileName = await discussionService.createDiscussionFile(
        perpuskuBasePath: await getPerpuskuHtmlBasePath(),
        subjectLinkedPath: sourceSubjectLinkedPath!,
        discussionName: result.name,
      );
      filePathValue = path.join(sourceSubjectLinkedPath!, createdFileName);
    } else if (result.linkType == DiscussionLinkType.perpuskuQuiz) {
      if (result.linkData is QuizPickerResult) {
        final quizResult = result.linkData as QuizPickerResult;
        filePathValue = quizResult.subjectPath;
        quizNameValue = quizResult.quizName;
      } else if (result.linkData == 'create_new_quiz') {
        if (sourceSubjectLinkedPath == null ||
            sourceSubjectLinkedPath!.isEmpty) {
          throw Exception(
            "Tidak dapat membuat kuis karena Subject ini belum ditautkan ke folder PerpusKu.",
          );
        }
        await _quizService.addQuizSet(sourceSubjectLinkedPath!, result.name);
        filePathValue = sourceSubjectLinkedPath;
        quizNameValue = result.name;
      }
    }

    final newDiscussion = Discussion(
      discussion: result.name,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      repetitionCode: 'R0D',
      points: [],
      linkType: result.linkType,
      filePath: filePathValue,
      url: result.linkType == DiscussionLinkType.link
          ? result.linkData as String?
          : null,
      quizName: quizNameValue,
    );
    _allDiscussions.add(newDiscussion);

    filterAndSortDiscussions();
    await saveDiscussions();
  }

  Future<void> updateQuizLink(
    Discussion discussion,
    QuizPickerResult result,
  ) async {
    discussion.filePath = result.subjectPath;
    discussion.quizName = result.quizName;
    await saveDiscussions();
    notifyListeners();
  }

  Future<void> convertToQuiz(
    Discussion discussion, {
    QuizPickerResult? linkTo,
    bool createNew = false,
  }) async {
    if (createNew) {
      if (sourceSubjectLinkedPath == null || sourceSubjectLinkedPath!.isEmpty) {
        throw Exception(
          "Tidak dapat membuat kuis karena Subject ini belum ditautkan ke folder PerpusKu.",
        );
      }
      await _quizService.addQuizSet(
        sourceSubjectLinkedPath!,
        discussion.discussion,
      );
      discussion.linkType = DiscussionLinkType.perpuskuQuiz;
      discussion.filePath = sourceSubjectLinkedPath;
      discussion.quizName = discussion.discussion;
    } else if (linkTo != null) {
      discussion.linkType = DiscussionLinkType.perpuskuQuiz;
      discussion.filePath = linkTo.subjectPath;
      discussion.quizName = linkTo.quizName;
    } else {
      throw Exception("Data kuis untuk ditautkan tidak valid.");
    }

    await saveDiscussions();
    notifyListeners();
  }

  // ==> FUNGSI DIPERBARUI
  Future<List<String>> getTitlesFromContent(String htmlContent) async {
    return await _geminiService.generateDiscussionTitles(htmlContent);
  }

  Future<void> addDiscussionWithPredefinedTitle({
    required String title,
    required String htmlContent,
    required String subjectLinkedPath,
  }) async {
    final newDiscussion = Discussion(
      discussion: title,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      repetitionCode: 'R0D',
      points: [],
      linkType: DiscussionLinkType.html,
    );

    await createAndLinkHtmlFile(newDiscussion, subjectLinkedPath);

    if (newDiscussion.filePath != null) {
      await writeHtmlToFile(newDiscussion.filePath!, htmlContent);
    }

    _allDiscussions.add(newDiscussion);
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

  // ==> BARU: Method untuk update highlight <==
  void updateDiscussionHighlight(
    Discussion discussion,
    int? color,
    String? label,
  ) {
    discussion.highlightColor = color;
    discussion.highlightLabel = label;
    saveDiscussions();
    notifyListeners();
  }

  Future<void> deleteDiscussion(Discussion discussion) async {
    String? fullPathToDelete;
    if (discussion.filePath != null && discussion.filePath!.isNotEmpty) {
      if (!discussion.filePath!.contains('/')) {
        if (sourceSubjectLinkedPath != null &&
            sourceSubjectLinkedPath!.isNotEmpty) {
          fullPathToDelete = path.join(
            sourceSubjectLinkedPath!,
            discussion.filePath!,
          );
        }
      } else {
        fullPathToDelete = discussion.filePath;
      }
    }

    _allDiscussions.removeWhere((d) => d.hashCode == discussion.hashCode);
    filterAndSortDiscussions();

    try {
      await saveDiscussions();
      await discussionService.deleteLinkedFile(fullPathToDelete);
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
