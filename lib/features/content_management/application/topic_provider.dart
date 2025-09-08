// lib/presentation/providers/topic_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart'; // DIUBAH: Menggunakan pustaka baru
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../domain/models/topic_model.dart';
import '../domain/services/topic_service.dart';
import '../../../core/services/path_service.dart';

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

  bool _showHiddenTopics = false;
  bool get showHiddenTopics => _showHiddenTopics;

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

  void toggleShowHidden() {
    _showHiddenTopics = !_showHiddenTopics;
    _filterTopics();
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
    List<Topic> tempTopics;

    // Filter berdasarkan status isHidden
    if (_showHiddenTopics) {
      tempTopics = _allTopics; // Tampilkan semua
    } else {
      tempTopics = _allTopics
          .where((topic) => !topic.isHidden)
          .toList(); // Sembunyikan yang tersembunyi
    }

    // Filter berdasarkan query pencarian
    if (_searchQuery.isEmpty) {
      _filteredTopics = tempTopics;
    } else {
      _filteredTopics = tempTopics
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

  Future<void> toggleTopicVisibility(String topicName, bool isHidden) async {
    await _topicService.updateTopicVisibility(topicName, isHidden);
    await fetchTopics();
  }

  // DIUBAH: Fungsi backup diperbarui untuk menggunakan pustaka 'archive'
  Future<String> backupContents({required String destinationPath}) async {
    _isBackingUp = true;
    notifyListeners();
    try {
      final contentsPath = await _pathService.contentsPath;
      final sourceDir = Directory(contentsPath);

      if (!await sourceDir.exists()) {
        throw Exception('Direktori "contents" tidak ditemukan.');
      }

      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final zipFileName = 'backup-topics-$timestamp.zip';
      final zipFilePath = path.join(destinationPath, zipFileName);

      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      await encoder.addDirectory(sourceDir, includeDirName: false);
      encoder.close();

      return 'Backup berhasil disimpan di: $destinationPath';
    } catch (e) {
      rethrow;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  // DIUBAH: Fungsi import diperbarui untuk menggunakan pustaka 'archive'
  Future<void> importContents(File zipFile) async {
    try {
      final topicsPath = await _pathService.topicsPath;
      final myTasksPath = await _pathService.myTasksPath;
      final contentsPath = await _pathService.contentsPath;

      final topicsDir = Directory(topicsPath);
      final myTasksFile = File(myTasksPath);

      if (await topicsDir.exists()) {
        await topicsDir.delete(recursive: true);
      }

      if (await myTasksFile.exists()) {
        await myTasksFile.delete();
      }

      // Menggunakan fungsi dari pustaka 'archive' untuk ekstraksi
      await extractFileToDisk(zipFile.path, contentsPath);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getTopicsPath() async {
    return await _pathService.topicsPath;
  }
}
