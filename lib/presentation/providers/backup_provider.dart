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

  // ==> STATE BARU UNTUK SELEKSI FILE <==
  final Set<String> _selectedFiles = {};
  Set<String> get selectedFiles => _selectedFiles;

  bool get isSelectionMode => _selectedFiles.isNotEmpty;

  // ==> STATE BARU UNTUK SORTING <==
  String _sortType = 'date';
  String get sortType => _sortType;

  bool _sortAscending = false;
  bool get sortAscending => _sortAscending;

  BackupProvider() {
    loadBackupData();
  }

  // ==> FUNGSI BARU UNTUK MENGELOLA SELEKSI <==
  void toggleFileSelection(File file) {
    if (_selectedFiles.contains(file.path)) {
      _selectedFiles.remove(file.path);
    } else {
      _selectedFiles.add(file.path);
    }
    notifyListeners();
  }

  void selectAllFiles(List<File> files) {
    _selectedFiles.addAll(files.map((f) => f.path));
    notifyListeners();
  }

  void clearSelection() {
    _selectedFiles.clear();
    notifyListeners();
  }

  Future<void> deleteSelectedFiles() async {
    for (String path in _selectedFiles) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Abaikan error jika file tidak dapat dihapus
      }
    }
    _selectedFiles.clear();
    await listBackupFiles(); // Muat ulang daftar file setelah penghapusan
  }
  // --- AKHIR FUNGSI BARU ---

  // ==> FUNGSI BARU UNTUK SORTING <==
  void applySort(String sortType, bool sortAscending) {
    _sortType = sortType;
    _sortAscending = sortAscending;
    _prefsService.saveBackupSortPreferences(sortType, sortAscending);
    _sortBackupFiles();
    notifyListeners();
  }

  void _sortBackupFiles() {
    Comparator<File> comparator;
    switch (_sortType) {
      case 'name':
        comparator = (a, b) =>
            path.basename(a.path).compareTo(path.basename(b.path));
        break;
      default: // date
        comparator = (a, b) =>
            a.lastModifiedSync().compareTo(b.lastModifiedSync());
        break;
    }

    _rspaceBackupFiles.sort(comparator);
    _perpuskuBackupFiles.sort(comparator);

    if (!_sortAscending) {
      _rspaceBackupFiles = _rspaceBackupFiles.reversed.toList();
      _perpuskuBackupFiles = _perpuskuBackupFiles.reversed.toList();
    }
  }
  // --- AKHIR FUNGSI SORTING ---

  Future<void> loadBackupData() async {
    _isLoading = true;
    notifyListeners();

    final sortPrefs = await _prefsService.loadBackupSortPreferences();
    _sortType = sortPrefs['sortType'];
    _sortAscending = sortPrefs['sortAscending'];

    // ==> DIUBAH: Memuat path backup yang terpisah <==
    _backupPath = await _prefsService.loadCustomBackupPath();
    _perpuskuDataPath = await _prefsService.loadPerpuskuDataPath();

    if (_backupPath != null && _backupPath!.isNotEmpty) {
      await listBackupFiles();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setBackupPath(String newPath) async {
    // ==> DIUBAH: Menyimpan ke preferensi backup yang terpisah <==
    await _prefsService.saveCustomBackupPath(newPath);
    _backupPath = newPath;
    await listBackupFiles();
    notifyListeners();
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

  Future<void> listBackupFiles() async {
    _rspaceBackupFiles = [];
    _perpuskuBackupFiles = [];

    if (_backupPath == null || _backupPath!.isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final rspaceDir = Directory(await _pathService.rspaceBackupPath);
      if (await rspaceDir.exists()) {
        _rspaceBackupFiles = rspaceDir
            .listSync()
            .whereType<File>()
            .where(
              (item) =>
                  path.basename(item.path).startsWith('backup-topics-') &&
                  item.path.toLowerCase().endsWith('.zip'),
            )
            .toList();
      }
    } catch (e) {
      // Abaikan
    }

    try {
      final perpuskuDir = Directory(await _pathService.perpuskuBackupPath);
      if (await perpuskuDir.exists()) {
        _perpuskuBackupFiles = perpuskuDir
            .listSync()
            .whereType<File>()
            .where(
              (item) =>
                  path.basename(item.path).startsWith('backup-perpusku-') &&
                  item.path.toLowerCase().endsWith('.zip'),
            )
            .toList();
      }
    } catch (e) {
      // Abaikan
    }

    _sortBackupFiles(); // ==> PANGGIL FUNGSI SORTING DI SINI <==
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
