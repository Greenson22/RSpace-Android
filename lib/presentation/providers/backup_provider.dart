import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import '../../data/services/path_service.dart';
import '../../data/services/shared_preferences_service.dart';

class BackupProvider with ChangeNotifier {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final PathService _pathService = PathService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // State untuk proses backup dan import
  bool _isBackingUp = false;
  bool get isBackingUp => _isBackingUp;

  bool _isImporting = false;
  bool get isImporting => _isImporting;

  String? _backupPath;
  String? get backupPath => _backupPath;

  List<File> _backupFiles = [];
  List<File> get backupFiles => _backupFiles;

  BackupProvider() {
    loadBackupData();
  }

  Future<void> loadBackupData() async {
    _isLoading = true;
    notifyListeners();

    _backupPath = await _prefsService.loadCustomStoragePath();
    if (_backupPath == null || _backupPath!.isEmpty) {
      _backupPath = await _pathService.contentsPath.then(
        (p) => path.dirname(p),
      );
    }
    await listBackupFiles();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setBackupPath(String newPath) async {
    await _prefsService.saveCustomStoragePath(newPath);
    _backupPath = newPath;
    await listBackupFiles();
    notifyListeners();
  }

  Future<void> listBackupFiles() async {
    _backupFiles = [];
    if (_backupPath == null || _backupPath!.isEmpty) {
      return;
    }

    final directory = Directory(_backupPath!);
    if (await directory.exists()) {
      final files = directory
          .listSync()
          .whereType<File>()
          .where(
            (item) =>
                path.basename(item.path).startsWith('backup-topics-') &&
                item.path.toLowerCase().endsWith('.zip'),
          )
          .toList();

      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      _backupFiles = files;
    }
  }

  // --- FUNGSI BARU: Logika Backup & Import ---
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

      await listBackupFiles(); // Refresh daftar file setelah backup
      return 'Backup berhasil disimpan di: $destinationPath';
    } catch (e) {
      rethrow;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  Future<void> importContents(File zipFile) async {
    _isImporting = true;
    notifyListeners();
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

      await extractFileToDisk(zipFile.path, contentsPath);
    } catch (e) {
      rethrow;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }
}
