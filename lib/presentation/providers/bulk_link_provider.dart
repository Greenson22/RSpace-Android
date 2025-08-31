// lib/presentation/providers/bulk_link_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/topic_model.dart'; // Import model Topik
import '../../data/models/unlinked_discussion_model.dart';
import '../../data/models/link_suggestion_model.dart';
import '../../data/services/topic_service.dart'; // Import service Topik
import '../../data/services/unlinked_discussion_service.dart';
import '../../data/services/smart_link_service.dart';
import '../../data/services/discussion_service.dart';

// Enum untuk mengelola state halaman
enum BulkLinkState { loading, selectingTopic, linking, finished }

class BulkLinkProvider with ChangeNotifier {
  final UnlinkedDiscussionService _unlinkedService =
      UnlinkedDiscussionService();
  final SmartLinkService _smartLinkService = SmartLinkService();
  final DiscussionService _discussionService = DiscussionService();
  final TopicService _topicService = TopicService(); // Tambahkan TopicService

  BulkLinkState _currentState = BulkLinkState.loading;
  BulkLinkState get currentState => _currentState;

  List<Topic> _topics = []; // Untuk menyimpan daftar topik
  List<Topic> get topics => _topics;

  List<UnlinkedDiscussion> _unlinkedDiscussions = [];
  int _currentIndex = 0;

  UnlinkedDiscussion? get currentDiscussion =>
      _unlinkedDiscussions.isNotEmpty &&
          _currentIndex < _unlinkedDiscussions.length
      ? _unlinkedDiscussions[_currentIndex]
      : null;

  List<LinkSuggestion> _currentSuggestions = [];
  List<LinkSuggestion> get currentSuggestions => _currentSuggestions;

  List<Map<String, String>> _allFiles = [];

  BulkLinkProvider() {
    _initialize();
  }

  // Tahap 1: Inisialisasi, muat daftar topik
  Future<void> _initialize() async {
    _topics = await _topicService.getTopics();
    _allFiles = await _smartLinkService.getAllPerpuskuFiles();
    _currentState = BulkLinkState.selectingTopic;
    notifyListeners();
  }

  // Tahap 2: Mulai proses penautan setelah topik dipilih
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

    // 1. Update the discussion object in memory
    currentDiscussion!.discussion.filePath = relativePath;

    // 2. Save the updated discussion back to its JSON file
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

    // 3. Move to the next discussion
    nextDiscussion();
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
            score: 0, // Score isn't relevant for manual search
          ),
        )
        .toList();
    notifyListeners();
  }
}
