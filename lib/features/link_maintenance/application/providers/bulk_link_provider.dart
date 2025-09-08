// lib/presentation/providers/bulk_link_provider.dart

import 'package:flutter/material.dart';
import '../../../content_management/domain/models/topic_model.dart';
import '../../domain/models/unlinked_discussion_model.dart';
import '../../domain/models/link_suggestion_model.dart';
import '../../../content_management/domain/services/topic_service.dart';
import '../services/unlinked_discussion_service.dart';
import '../services/smart_link_service.dart';
import '../../../content_management/domain/services/discussion_service.dart';
import '../../../../core/services/path_service.dart';
import 'package:path/path.dart' as path;

// Enum untuk mengelola state halaman
enum BulkLinkState { loading, selectingTopic, linking, finished }

class BulkLinkProvider with ChangeNotifier {
  final UnlinkedDiscussionService _unlinkedService =
      UnlinkedDiscussionService();
  final SmartLinkService _smartLinkService = SmartLinkService();
  final DiscussionService _discussionService = DiscussionService();
  final TopicService _topicService = TopicService();
  final PathService _pathService = PathService();

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

  // State untuk filter status 'finished'
  bool _includeFinished = false;
  bool get includeFinished => _includeFinished;

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

  // Tahap 1: Inisialisasi, muat topik dan hitung jumlah diskusi awal
  Future<void> _initialize() async {
    _topics = await _topicService.getTopics();
    _allFiles = await _smartLinkService.getAllPerpuskuFiles();
    await _recalculateCounts(); // Hitung jumlah awal
    _currentState = BulkLinkState.selectingTopic;
    notifyListeners();
  }

  // Metode baru untuk menghitung ulang jumlah berdasarkan filter
  Future<void> _recalculateCounts() async {
    _currentState = BulkLinkState.loading;
    notifyListeners();

    _unlinkedCounts.clear();
    for (final topic in _topics) {
      if (!topic.isHidden) {
        final discussions = await _unlinkedService.fetchAllUnlinkedDiscussions(
          topicName: topic.name,
          includeFinished: _includeFinished, // Gunakan state filter
        );
        _unlinkedCounts[topic.name] = discussions.length;
      }
    }
    _currentState = BulkLinkState.selectingTopic;
    notifyListeners();
  }

  // Metode untuk mengubah filter dan memicu perhitungan ulang
  void toggleIncludeFinished(bool value) {
    if (_includeFinished == value) return;
    _includeFinished = value;
    _recalculateCounts();
  }

  // Tahap 2: Mulai proses penautan setelah topik dipilih
  Future<void> startLinking({String? topicName}) async {
    _currentState = BulkLinkState.loading;
    notifyListeners();

    _unlinkedDiscussions = await _unlinkedService.fetchAllUnlinkedDiscussions(
      topicName: topicName,
      includeFinished: _includeFinished, // Gunakan state filter
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

  Future<void> createAndLinkDiscussion() async {
    if (currentDiscussion == null ||
        currentDiscussion!.subjectLinkedPath == null) {
      throw Exception(
        "Subject dari diskusi ini tidak tertaut ke folder PerpusKu.",
      );
    }

    final perpuskuDataPath = await _pathService.perpuskuDataPath;
    final perpuskuTopicsPath = path.join(
      perpuskuDataPath,
      'file_contents',
      'topics',
    );

    final newRelativePath = await _discussionService.createDiscussionFile(
      perpuskuBasePath: perpuskuTopicsPath,
      subjectLinkedPath: currentDiscussion!.subjectLinkedPath!,
      discussionName: currentDiscussion!.discussion.discussion,
    );

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
