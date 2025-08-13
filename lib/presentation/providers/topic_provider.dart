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

  Future<String> backupContents({required String destinationPath}) async {
    _isBackingUp = true;
    notifyListeners();
    try {
      // Menunggu hasil Future dari _pathService.contentsPath
      final contentsPath = await _pathService.contentsPath;
      final sourceDir = Directory(contentsPath);

      if (!await sourceDir.exists()) {
        throw Exception('Direktori "contents" tidak ditemukan.');
      }

      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final zipFileName = 'backup-topics-$timestamp.zip';
      final zipFile = File(path.join(destinationPath, zipFileName));

      // Memastikan direktori tujuan ada
      if (!await Directory(destinationPath).exists()) {
        await Directory(destinationPath).create(recursive: true);
      }

      await ZipFile.createFromDirectory(
        sourceDir: sourceDir,
        zipFile: zipFile,
        recurseSubDirs: true,
      );

      // Mengembalikan pesan sukses yang lebih informatif
      return 'Backup berhasil disimpan di: $destinationPath';
    } catch (e) {
      rethrow;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  // Mengubah return type menjadi Future<String> dan menjadikannya async
  Future<String> getTopicsPath() async {
    return await _pathService.topicsPath;
  }

  // FUNGSI BARU UNTUK MENDAPATKAN PATH CONTENTS
  Future<String> getContentsPath() async {
    return await _pathService.contentsPath;
  }
}
