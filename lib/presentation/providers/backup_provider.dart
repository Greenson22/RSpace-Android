// lib/presentation/providers/backup_provider.dart

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

  bool _isBackingUp = false;
  bool get isBackingUp => _isBackingUp;

  bool _isImporting = false;
  bool get isImporting => _isImporting;

  String? _backupPath;
  String? get backupPath => _backupPath;

  String? _perpuskuDataPath;
  String? get perpuskuDataPath => _perpuskuDataPath;

  List<File> _rspaceBackupFiles = [];
  List<File> get rspaceBackupFiles => _rspaceBackupFiles;

  List<File> _perpuskuBackupFiles = [];
  List<File> get perpuskuBackupFiles => _perpuskuBackupFiles;

  BackupProvider() {
    loadBackupData();
  }

  Future<void> loadBackupData() async {
    _isLoading = true;
    notifyListeners();

    _backupPath = await _prefsService.loadCustomStoragePath();
    _perpuskuDataPath = await _prefsService.loadPerpuskuDataPath();

    if (_backupPath != null && _backupPath!.isNotEmpty) {
      await listBackupFiles();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setBackupPath(String newPath) async {
    await _prefsService.saveCustomStoragePath(newPath);
    _backupPath = newPath;
    await listBackupFiles();
  }

  Future<void> setPerpuskuDataPath(String newPath) async {
    await _prefsService.savePerpuskuDataPath(newPath);
    _perpuskuDataPath = newPath;
    notifyListeners();
  }

  Future<String> backupPerpuskuContents() async {
    _isBackingUp = true;
    notifyListeners();
    try {
      final destinationPath = await _pathService.perpuskuBackupPath;
      final perpuskuDataPath = await _pathService.perpuskuDataPath;
      final sourceDir = Directory(perpuskuDataPath);

      if (!await sourceDir.exists()) {
        await sourceDir.create(recursive: true);
        debugPrint("Folder sumber data PerpusKu dibuat di: $perpuskuDataPath");
      }

      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final zipFileName = 'backup-perpusku-$timestamp.zip';
      final zipFilePath = path.join(destinationPath, zipFileName);

      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      await encoder.addDirectory(sourceDir, includeDirName: false);
      encoder.close();

      await listBackupFiles();
      return 'Backup PerpusKu berhasil disimpan.';
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  // ==> PERUBAHAN UTAMA ADA DI FUNGSI INI <==
  Future<void> listBackupFiles() async {
    _rspaceBackupFiles = [];
    _perpuskuBackupFiles = [];

    if (_backupPath == null || _backupPath!.isEmpty) {
      notifyListeners(); // Pastikan UI update jika path kosong
      return;
    }

    try {
      final rspaceDir = Directory(await _pathService.rspaceBackupPath);
      if (await rspaceDir.exists()) {
        final files = rspaceDir
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
        _rspaceBackupFiles = files;
      }
    } catch (e) {
      // Abaikan
    }

    try {
      final perpuskuDir = Directory(await _pathService.perpuskuBackupPath);
      if (await perpuskuDir.exists()) {
        final files = perpuskuDir
            .listSync()
            .whereType<File>()
            .where(
              (item) =>
                  path.basename(item.path).startsWith('backup-perpusku-') &&
                  item.path.toLowerCase().endsWith('.zip'),
            )
            .toList();
        files.sort(
          (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
        );
        _perpuskuBackupFiles = files;
      }
    } catch (e) {
      // Abaikan
    }

    // ==> BARIS INI DITAMBAHKAN UNTUK MEMICU REFRESH UI <==
    notifyListeners();
  }

  Future<String> backupRspaceContents() async {
    _isBackingUp = true;
    notifyListeners();
    try {
      final destinationPath = await _pathService.rspaceBackupPath;
      final contentsPath = await _pathService.contentsPath;
      final sourceDir = Directory(contentsPath);

      if (!await sourceDir.exists()) {
        throw Exception('Direktori "contents" RSpace tidak ditemukan.');
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

      await listBackupFiles();
      return 'Backup RSpace berhasil disimpan.';
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  Future<void> importContents(File zipFile, String type) async {
    _isImporting = true;
    notifyListeners();
    try {
      if (type == 'RSpace') {
        final topicsPath = await _pathService.topicsPath;
        final myTasksPath = await _pathService.myTasksPath;
        final contentsPath = await _pathService.contentsPath;

        final topicsDir = Directory(topicsPath);
        final myTasksFile = File(myTasksPath);

        if (await topicsDir.exists()) await topicsDir.delete(recursive: true);
        if (await myTasksFile.exists()) await myTasksFile.delete();

        await extractFileToDisk(zipFile.path, contentsPath);
      } else if (type == 'PerpusKu') {
        final perpuskuDataPath = await _pathService.perpuskuDataPath;
        final dataDir = Directory(perpuskuDataPath);

        if (await dataDir.exists()) await dataDir.delete(recursive: true);

        await extractFileToDisk(zipFile.path, perpuskuDataPath);
      }
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }
}
