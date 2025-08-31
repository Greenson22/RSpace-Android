// lib/presentation/providers/bulk_link_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/unlinked_discussion_model.dart';
import '../../data/models/link_suggestion_model.dart';
import '../../data/services/unlinked_discussion_service.dart';
import '../../data/services/smart_link_service.dart';
import '../../data/services/discussion_service.dart';

class BulkLinkProvider with ChangeNotifier {
  final UnlinkedDiscussionService _unlinkedService =
      UnlinkedDiscussionService();
  final SmartLinkService _smartLinkService = SmartLinkService();
  final DiscussionService _discussionService = DiscussionService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

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

  bool get isFinished => !_isLoading && currentDiscussion == null;

  BulkLinkProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _unlinkedDiscussions = await _unlinkedService.fetchAllUnlinkedDiscussions();
    _allFiles = await _smartLinkService.getAllPerpuskuFiles();
    _isLoading = false;

    if (_unlinkedDiscussions.isNotEmpty) {
      await _findSuggestionsForCurrent();
    } else {
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
      _currentIndex++; // Mark as finished
      notifyListeners();
    }
  }

  Future<void> linkCurrentDiscussion(String relativePath) async {
    if (currentDiscussion == null) return;

    // 1. Update the discussion object in memory
    currentDiscussion!.discussion.filePath = relativePath;

    // 2. Save the updated discussion back to its JSON file
    // First, load all discussions from that file
    final allDiscussionsInFile = await _discussionService.loadDiscussions(
      currentDiscussion!.subjectJsonPath,
    );
    // Find the specific discussion by its name (or a more robust ID if you have one)
    final indexToUpdate = allDiscussionsInFile.indexWhere(
      (d) => d.discussion == currentDiscussion!.discussion.discussion,
    );
    if (indexToUpdate != -1) {
      allDiscussionsInFile[indexToUpdate] = currentDiscussion!.discussion;
      // Save the entire list back
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
