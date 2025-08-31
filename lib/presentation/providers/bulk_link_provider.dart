// lib/presentation/providers/bulk_link_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/topic_model.dart';
import '../../data/models/unlinked_discussion_model.dart';
import '../../data/models/link_suggestion_model.dart';
import '../../data/services/topic_service.dart';
import '../../data/services/unlinked_discussion_service.dart';
import '../../data/services/smart_link_service.dart';
import '../../data/services/discussion_service.dart';
import '../../data/services/path_service.dart';
// ==> 1. TAMBAHKAN IMPORT UNTUK FUNGSI PATH
import 'package:path/path.dart' as path;

// Enum untuk mengelola state halaman
enum BulkLinkState { loading, selectingTopic, linking, finished }

class BulkLinkProvider with ChangeNotifier {
  final UnlinkedDiscussionService _unlinkedService =
      UnlinkedDiscussionService();
  final SmartLinkService _smartLinkService = SmartLinkService();
  final DiscussionService _discussionService = DiscussionService();
  final TopicService _topicService = TopicService();
  final PathService _pathService = PathService(); // Tambahkan PathService

  BulkLinkState _currentState = BulkLinkState.loading;
  BulkLinkState get currentState => _currentState;

  List<Topic> _topics = [];
  List<Topic> get topics => _topics;

  Map<String, int> _unlinkedCounts = {};
  Map<String, int> get unlinkedCounts => _unlinkedCounts;

  int get totalUnlinkedCount =>
      _unlinkedCounts.values.fold(0, (sum, count) => sum + count);

  List<UnlinkedDiscussion> _unlinkedDiscussions = [];
  int _currentIndex = 0;

  int get totalDiscussionsToProcess => _unlinkedDiscussions.length;
  int get currentDiscussionNumber => _currentIndex + 1;

  UnlinkedDiscussion? get currentDiscussion =>
      _unlinkedDiscussions.isNotEmpty &&
          _currentIndex < _unlinkedDiscussions.length
      ? _unlinkedDiscussions[_currentIndex]
      : null;

  List<LinkSuggestion> _currentSuggestions = [];
  List<LinkSuggestion> get currentSuggestions => _currentSuggestions;

  List<Map<String, String>> _allFiles = [];

  bool get isFinished => _currentState == BulkLinkState.finished;

  BulkLinkProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _topics = await _topicService.getTopics();
    _allFiles = await _smartLinkService.getAllPerpuskuFiles();

    for (final topic in _topics) {
      if (!topic.isHidden) {
        final discussions = await _unlinkedService.fetchAllUnlinkedDiscussions(
          topicName: topic.name,
        );
        _unlinkedCounts[topic.name] = discussions.length;
      }
    }

    _currentState = BulkLinkState.selectingTopic;
    notifyListeners();
  }

  Future<void> startLinking({String? topicName}) async {
    _currentState = BulkLinkState.loading;
    notifyListeners();

    _unlinkedDiscussions = await _unlinkedService.fetchAllUnlinkedDiscussions(
      topicName: topicName,
    );

    if (_unlinkedDiscussions.isNotEmpty) {
      _currentIndex = 0;
      _currentState = BulkLinkState.linking;
      await _findSuggestionsForCurrent();
    } else {
      _currentState = BulkLinkState.finished;
      notifyListeners();
    }
  }

  Future<void> _findSuggestionsForCurrent() async {
    if (currentDiscussion == null) return;
    _currentSuggestions = await _smartLinkService.findSuggestions(
      discussion: currentDiscussion!.discussion,
      topicName: currentDiscussion!.topicName,
      subjectName: currentDiscussion!.subjectName,
    );
    notifyListeners();
  }

  void nextDiscussion() {
    if (_currentIndex < _unlinkedDiscussions.length - 1) {
      _currentIndex++;
      _findSuggestionsForCurrent();
    } else {
      _currentState = BulkLinkState.finished;
      notifyListeners();
    }
  }

  Future<void> linkCurrentDiscussion(String relativePath) async {
    if (currentDiscussion == null) return;

    currentDiscussion!.discussion.filePath = relativePath;

    final allDiscussionsInFile = await _discussionService.loadDiscussions(
      currentDiscussion!.subjectJsonPath,
    );
    final indexToUpdate = allDiscussionsInFile.indexWhere(
      (d) => d.discussion == currentDiscussion!.discussion.discussion,
    );
    if (indexToUpdate != -1) {
      allDiscussionsInFile[indexToUpdate] = currentDiscussion!.discussion;
      await _discussionService.saveDiscussions(
        currentDiscussion!.subjectJsonPath,
        allDiscussionsInFile,
      );
    }

    nextDiscussion();
  }

  // ==> 2. FUNGSI INI DIPERBAIKI
  Future<void> createAndLinkDiscussion() async {
    if (currentDiscussion == null ||
        currentDiscussion!.subjectLinkedPath == null) {
      throw Exception(
        "Subject dari diskusi ini tidak tertaut ke folder PerpusKu.",
      );
    }

    // Dapatkan path dasar data PerpusKu (e.g., .../Perpusku/data)
    final perpuskuDataPath = await _pathService.perpuskuDataPath;

    // **FIX**: Bentuk path yang benar menuju folder 'topics' di dalam struktur PerpusKu
    final perpuskuTopicsPath = path.join(
      perpuskuDataPath,
      'file_contents',
      'topics',
    );

    // Panggil service untuk membuat file HTML baru dengan base path yang sudah benar
    final newRelativePath = await _discussionService.createDiscussionFile(
      perpuskuBasePath:
          perpuskuTopicsPath, // Gunakan path yang sudah diperbaiki
      subjectLinkedPath: currentDiscussion!.subjectLinkedPath!,
      discussionName: currentDiscussion!.discussion.discussion,
    );

    // Panggil metode yang sudah ada untuk menautkan path baru ini
    await linkCurrentDiscussion(newRelativePath);
  }

  void searchFiles(String query) {
    if (query.isEmpty) {
      _findSuggestionsForCurrent();
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    _currentSuggestions = _allFiles
        .where(
          (fileData) =>
              fileData['title']!.toLowerCase().contains(lowerCaseQuery) ||
              fileData['relativePath']!.toLowerCase().contains(lowerCaseQuery),
        )
        .map(
          (fileData) => LinkSuggestion(
            title: fileData['title']!,
            relativePath: fileData['relativePath']!,
            score: 0,
          ),
        )
        .toList();
    notifyListeners();
  }
}
