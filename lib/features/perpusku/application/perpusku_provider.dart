// lib/features/perpusku/application/perpusku_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/perpusku_models.dart';
import '../infrastructure/perpusku_service.dart';

class PerpuskuProvider with ChangeNotifier {
  final PerpuskuService _service = PerpuskuService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  List<PerpuskuTopic> _topics = [];
  List<PerpuskuTopic> get topics => _topics;

  List<PerpuskuSubject> _subjects = [];
  List<PerpuskuSubject> get subjects => _subjects;

  List<PerpuskuFile> _files = [];
  List<PerpuskuFile> get files => _files;

  List<PerpuskuFile> _searchResults = [];
  List<PerpuskuFile> get searchResults => _searchResults;

  Future<void> fetchTopics() async {
    _setLoading(true);
    _topics = await _service.getTopics();
    _setLoading(false);
  }

  Future<void> fetchSubjects(String topicPath) async {
    _setLoading(true);
    _subjects = await _service.getSubjects(topicPath);
    _setLoading(false);
  }

  Future<void> fetchFiles(String subjectPath) async {
    _setLoading(true);
    _files = await _service.getFiles(subjectPath);
    _setLoading(false);
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    _isSearching = true;
    _setLoading(true);
    _searchResults = await _service.searchAllFiles(query);
    _setLoading(false);
  }

  // Metode baru untuk pencarian di dalam topik
  Future<void> searchInTopic(String topicPath, String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    _isSearching = true;
    _setLoading(true);
    _searchResults = await _service.searchFilesInTopic(topicPath, query);
    _setLoading(false);
  }

  void clearSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
