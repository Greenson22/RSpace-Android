import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../../data/models/topic_model.dart';
import '../../data/services/topic_service.dart';
import '../../data/services/path_service.dart';

class TopicProvider with ChangeNotifier {
  final TopicService _topicService = TopicService();
  final PathService _pathService = PathService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isBackingUp = false;
  bool get isBackingUp => _isBackingUp;

  List<Topic> _allTopics = [];
  List<Topic> get allTopics => _allTopics;

  List<Topic> _filteredTopics = [];
  List<Topic> get filteredTopics => _filteredTopics;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isReorderModeEnabled = false;
  bool get isReorderModeEnabled => _isReorderModeEnabled;

  TopicProvider() {
    fetchTopics();
  }

  void toggleReorderMode() {
    _isReorderModeEnabled = !_isReorderModeEnabled;
    if (!_isReorderModeEnabled) {
      _filterTopics();
    }
    notifyListeners();
  }

  Future<void> fetchTopics() async {
    _isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });

    try {
      _allTopics = await _topicService.getTopics();
      _filterTopics();
    } finally {
      _isLoading = false;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _filterTopics();
  }

  void _filterTopics() {
    if (_searchQuery.isEmpty) {
      _filteredTopics = _allTopics;
    } else {
      _filteredTopics = _allTopics
          .where((topic) => topic.name.toLowerCase().contains(_searchQuery))
          .toList();
    }
    notifyListeners();
  }

  Future<void> reorderTopics(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final Topic item = _allTopics.removeAt(oldIndex);
    _allTopics.insert(newIndex, item);

    _isBackingUp = true;
    notifyListeners();

    try {
      await _topicService.saveTopicsOrder(_allTopics);
    } finally {
      _isBackingUp = false;
      await fetchTopics();
    }
  }

  Future<void> addTopic(String name) async {
    await _topicService.addTopic(name);
    await fetchTopics();
  }

  Future<void> renameTopic(String oldName, String newName) async {
    await _topicService.renameTopic(oldName, newName);
    await fetchTopics();
  }

  Future<void> deleteTopic(String topicName) async {
    await _topicService.deleteTopic(topicName);
    await fetchTopics();
  }

  Future<void> updateTopicIcon(String topicName, String newIcon) async {
    await _topicService.updateTopicIcon(topicName, newIcon);
    await fetchTopics();
  }

  Future<String> backupContents() async {
    _isBackingUp = true;
    notifyListeners();
    try {
      final contentsPath = _pathService.contentsPath;
      final sourceDir = Directory(contentsPath);

      if (!await sourceDir.exists()) {
        throw Exception('Direktori "contents" tidak ditemukan.');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final zipFileName = 'backup_contents_$timestamp.zip';

      final tempDir = await Directory.systemTemp.createTemp();
      final zipFile = File(path.join(tempDir.path, zipFileName));

      await ZipFile.createFromDirectory(
        sourceDir: sourceDir,
        zipFile: zipFile,
        recurseSubDirs: true,
      );

      String? savedPath = await FileSaver.instance.saveAs(
        name: zipFileName,
        bytes: await zipFile.readAsBytes(),
        fileExtension: 'zip',
        mimeType: MimeType.zip,
      );
      await tempDir.delete(recursive: true);

      return savedPath != null
          ? 'Backup berhasil disimpan di folder Downloads'
          : 'Backup dibatalkan atau gagal disimpan.';
    } catch (e) {
      rethrow;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  String getTopicsPath() {
    return _pathService.topicsPath;
  }
}
