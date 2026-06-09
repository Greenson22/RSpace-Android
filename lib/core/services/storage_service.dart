// lib/core/services/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'path_service.dart';
import 'user_data_service.dart';
import 'neuron_service.dart';

/// Kelas Utama SharedPreferences bawaan aplikasi Anda tetap dipertahankan utuh
class SharedPreferencesService {
  final PathService _pathService = PathService();
  final UserDataService _userDataService = UserDataService();
  final NeuronService _neuronService = NeuronService();

  static const String _localBackgroundPathKey = 'local_background_path';

  Future<void> saveLocalBackgroundImagePath(String path) =>
      _userDataService.saveString(_localBackgroundPathKey, path);
  Future<String?> loadLocalBackgroundImagePath() =>
      _userDataService.loadString(_localBackgroundPathKey);
  Future<void> clearLocalBackgroundImagePath() =>
      _userDataService.remove(_localBackgroundPathKey);

  Future<void> saveNeurons(int count) => _neuronService.setNeurons(count);
  Future<int> loadNeurons() => _neuronService.getNeurons();

  Future<void> saveCustomStoragePath(String path) =>
      _pathService.saveCustomStoragePath(path);
  Future<String?> loadCustomStoragePath() =>
      _pathService.loadCustomStoragePath();

  Future<void> saveSortPreferences(String sortType, bool sortAscending) =>
      _userDataService.saveSortPreferences(sortType, sortAscending);
  Future<Map<String, dynamic>> loadSortPreferences() =>
      _userDataService.loadSortPreferences();
  Future<void> saveFilterPreference(String? filterType, String? filterValue) =>
      _userDataService.saveFilterPreference(filterType, filterValue);
  Future<Map<String, String?>> loadFilterPreference() =>
      _userDataService.loadFilterPreference();
  Future<void> saveBackupSortPreferences(String sortType, bool sortAscending) =>
      _userDataService.saveBackupSortPreferences(sortType, sortAscending);
  Future<Map<String, dynamic>> loadBackupSortPreferences() =>
      _userDataService.loadBackupSortPreferences();

  Future<void> saveRepetitionCodeOrder(List<String> order) =>
      _userDataService.saveRepetitionCodeOrder(order);
  Future<List<String>> loadRepetitionCodeOrder() =>
      _userDataService.loadRepetitionCodeOrder();

  Future<void> saveRepetitionCodeDisplayOrder(List<String> order) async {
    final List<String> mutableList = List.from(order);
    await _userDataService.saveRepetitionCodeDisplayOrder(mutableList);
  }

  Future<List<String>> loadRepetitionCodeDisplayOrder() =>
      _userDataService.loadRepetitionCodeDisplayOrder();

  Future<void> saveRepetitionCodeDays(Map<String, int> days) =>
      _userDataService.saveRepetitionCodeDays(days);
  Future<Map<String, int>> loadRepetitionCodeDays() =>
      _userDataService.loadRepetitionCodeDays();

  Future<void> saveTimelineAppearance({
    double? discussionRadius,
    double? pointRadius,
  }) => _userDataService.saveTimelineAppearance(
    discussionRadius: discussionRadius,
    pointRadius: pointRadius,
  );
  Future<Map<String, double>> loadTimelineAppearance() =>
      _userDataService.loadTimelineAppearance();
}

// =========================================================================
// === SOLUSI EROR: Membuat Alias StorageService Berbasis SharedPreferences ===
// =========================================================================
class StorageService extends SharedPreferencesService {
  /// Mengambil basis direktori utama untuk sinkronisasi UI Data Center
  Future<String> getBaseDirSetting() async {
    String? kustomPath = await loadCustomStoragePath();
    return kustomPath ?? 'Documents';
  }

  /// Membantu menulis data teks mentah ke file target (.json)
  Future<void> saveJsonData(File file, String content) async {
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(content);
  }

  // --- LOGIKA IP HISTORY (SINKRONISASI WIFI) ---
  Future<List<String>> getIpHistory() async {
    return _userDataService.getIpHistory();
  }

  Future<void> saveIpToHistory(String ip) async {
    await _userDataService.saveIpToHistory(ip);
  }

  Future<void> deleteIpFromHistory(String ip) async {
    await _userDataService.deleteIpFromHistory(ip);
  }

  // --- LOGIKA CADANGAN BERKAS ZIP DATA CENTER ---
  Future<List<File>> getAllLocalBackupFiles(String baseDir) async {
    final String targetPath = await _pathService.rspaceBackupPath;
    final Directory dir = Directory(targetPath);
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.zip'))
        .toList();
  }

  Future<List<File>> getAllServerBackupFiles(String baseDir) async {
    final String targetPath = await _pathService.perpuskuBackupPath;
    final Directory dir = Directory(targetPath);
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.zip'))
        .toList();
  }

  Future<File> getLocalBackupZipFile(String baseDir, String fileName) async {
    final String targetPath = await _pathService.rspaceBackupPath;
    return File('$targetPath/$fileName');
  }

  Future<File> getBackupZipFile(String baseDir, String fileName) async {
    final String targetPath = await _pathService.perpuskuBackupPath;
    return File('$targetPath/$fileName');
  }

  // --- SEGMEN DATA: RSPACE ---
  Future<File> getRSpaceJsonFile(String baseDir) async {
    final String tPath = await _pathService.topicsPath;
    return File('$tPath/rspace_data_marker.json');
  }

  // --- SEGMEN DATA: PERPUSKU ---
  Future<String> getPerpuskuDirPath(String baseDir) async {
    return await _pathService.perpuskuDataPath;
  }

  Future<List<File>> getAllPerpuskuGroups(String baseDir) async {
    final String targetPath = await _pathService.perpuskuDataPath;
    final Directory dir = Directory(targetPath);
    if (!await dir.exists()) return [];

    // Membaca seluruh file data internal Perpusku secara rekursif
    return dir.listSync(recursive: true).whereType<File>().toList();
  }

  // =========================================================================
  // === LOGIKA GENERATE ZIP BERBASIS RSPACE_DATA DI DALAM RSPACE_APP     ===
  // =========================================================================
  Future<File> createBackupZip({
    required String mainFolderPath, // Mengarah ke root /RSpace_App
    required String baseDir,
    required String fileName,
    bool isServerSharing = false,
  }) async {
    // DISESUAIKAN: Sekarang mencari folder 'RSpace_data' di dalam mainFolderPath
    final Directory dataDir = Directory(
      path.join(mainFolderPath, 'RSpace_data'),
    );
    final Directory perpuskuDir = Directory(
      path.join(mainFolderPath, 'PerpusKu'),
    );

    if (!dataDir.existsSync() && !perpuskuDir.existsSync()) {
      throw Exception(
        "Folder RSpace_data atau PerpusKu tidak ditemukan di folder aplikasi.",
      );
    }

    File fileZipTarget = isServerSharing
        ? await getBackupZipFile(baseDir, fileName)
        : await getLocalBackupZipFile(baseDir, fileName);

    // --- PROSES PEMBUATAN FILE META.JSON SEMENTARA ---
    final Map<String, dynamic> metadata = {
      'mainFolderPath': mainFolderPath,
      'rspacePath': dataDir.path,
      'rspaceExists': dataDir.existsSync(),
      'perpuskuPath': perpuskuDir.path,
      'perpuskuExists': perpuskuDir.existsSync(),
      'createdAt': DateTime.now().toIso8601String(),
      'isServerSharing': isServerSharing,
    };

    final File metaFile = File(path.join(mainFolderPath, 'meta.json'));
    await metaFile.writeAsString(jsonEncode(metadata));
    // -------------------------------------------------

    final encoder = ZipFileEncoder();
    encoder.create(fileZipTarget.path);

    if (metaFile.existsSync()) {
      await encoder.addFile(metaFile);
    }

    // Masukkan folder RSpace_data dan PerpusKu ke dalam file ZIP backup
    if (dataDir.existsSync()) {
      await encoder.addDirectory(dataDir, includeDirName: true);
    }
    if (perpuskuDir.existsSync()) {
      await encoder.addDirectory(perpuskuDir, includeDirName: true);
    }
    encoder.close();

    if (metaFile.existsSync()) {
      await metaFile.delete();
    }

    return fileZipTarget;
  }
}
