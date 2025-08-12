import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../../data/services/local_file_service.dart';

class TopicProvider with ChangeNotifier {
  final LocalFileService _fileService = LocalFileService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isBackingUp = false;
  bool get isBackingUp => _isBackingUp;

  List<String> _allTopics = [];
  List<String> get allTopics => _allTopics;

  List<String> _filteredTopics = [];
  List<String> get filteredTopics => _filteredTopics;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  TopicProvider() {
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    _isLoading = true;
    // Hindari notifikasi jika widget sudah di-dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      _allTopics = await _fileService.getTopics();
      _filterTopics();
    } finally {
      _isLoading = false;
      notifyListeners();
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
          .where((topic) => topic.toLowerCase().contains(_searchQuery))
          .toList();
    }
    notifyListeners();
  }

  Future<void> addTopic(String name) async {
    await _fileService.addTopic(name);
    await fetchTopics();
  }

  Future<void> renameTopic(String oldName, String newName) async {
    await _fileService.renameTopic(oldName, newName);
    await fetchTopics();
  }

  Future<void> deleteTopic(String topicName) async {
    await _fileService.deleteTopic(topicName);
    await fetchTopics();
  }

  Future<String> backupContents() async {
    _isBackingUp = true;
    notifyListeners();
    try {
      final contentsPath = _fileService.getContentsPath();
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
    return _fileService.getTopicsPath();
  }
}
