import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../data/services/path_service.dart';
import '../../data/services/shared_preferences_service.dart';

class BackupProvider with ChangeNotifier {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final PathService _pathService = PathService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

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

    // Memuat path dari SharedPreferences, jika tidak ada, gunakan path default dari PathService
    _backupPath = await _prefsService.loadCustomStoragePath();
    if (_backupPath == null || _backupPath!.isEmpty) {
      // Ambil path default jika path kustom tidak diset
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

      // Urutkan file berdasarkan tanggal modifikasi terakhir (terbaru dulu)
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      _backupFiles = files;
    }
  }
}
