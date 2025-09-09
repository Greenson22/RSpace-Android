// lib/core/services/path_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PathService {
  // Kunci SharedPreferences dipindahkan ke sini
  static const String _customStoragePathKey = 'custom_storage_path';
  static const String _customStoragePathKeyDebug = 'custom_storage_path_debug';
  static const String _customBackupPathKey = 'custom_backup_path';
  static const String _customBackupPathKeyDebug = 'custom_backup_path_debug';
  static const String _customDownloadPathKey = 'custom_download_path';
  static const String _customDownloadPathKeyDebug =
      'custom_download_path_debug';
  static const String _perpuskuDataPathKey = 'perpusku_data_path';
  static const String _perpuskuDataPathKeyDebug = 'perpusku_data_path_debug';

  // Metode dari path_service_2.dart digabungkan ke sini
  Future<void> saveCustomStoragePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _customStoragePathKeyDebug : _customStoragePathKey;
    await prefs.setString(key, path);
  }

  Future<String?> loadCustomStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _customStoragePathKeyDebug : _customStoragePathKey;
    return prefs.getString(key);
  }

  Future<void> saveCustomBackupPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _customBackupPathKeyDebug : _customBackupPathKey;
    await prefs.setString(key, path);
  }

  Future<String?> loadCustomBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _customBackupPathKeyDebug : _customBackupPathKey;
    return prefs.getString(key);
  }

  Future<void> saveCustomDownloadPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode
        ? _customDownloadPathKeyDebug
        : _customDownloadPathKey;
    await prefs.setString(key, path);
  }

  Future<String?> loadCustomDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode
        ? _customDownloadPathKeyDebug
        : _customDownloadPathKey;
    return prefs.getString(key);
  }

  Future<void> savePerpuskuDataPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _perpuskuDataPathKeyDebug : _perpuskuDataPathKey;
    await prefs.setString(key, path);
  }

  Future<String?> loadPerpuskuDataPath() async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _perpuskuDataPathKeyDebug : _perpuskuDataPathKey;
    return prefs.getString(key);
  }

  // Metode asli dari path_service.dart disesuaikan untuk menggunakan metode di atas
  Future<String> get _appBasePath async {
    String? customPath = await loadCustomStoragePath();
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }

    Directory? baseDir;
    if (Platform.isAndroid) {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception(
          "Tidak dapat menemukan direktori penyimpanan eksternal.",
        );
      }
      final rootDir = Directory(
        path.join(externalDir.path, '..', '..', '..', '..'),
      );
      baseDir = Directory(path.join(rootDir.path, 'Download'));
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    return path.join(baseDir.path, 'RSpace_App');
  }

  Future<String> get _baseDataPath async {
    if (Platform.isAndroid) {
      if (!await Permission.manageExternalStorage.request().isGranted) {
        throw Exception(
          'Izin "Akses semua file" diperlukan untuk menyimpan data di folder pilihan Anda.',
        );
      }
    }

    String? customPath = await loadCustomStoragePath();

    if (customPath != null && customPath.isNotEmpty) {
      final dataDir = Directory(path.join(customPath, 'RSpace_data', 'data'));
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      return dataDir.path;
    }

    Directory? baseDir;
    if (Platform.isAndroid) {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception(
          "Tidak dapat menemukan direktori penyimpanan eksternal.",
        );
      }
      final rootDir = Directory(
        path.join(externalDir.path, '..', '..', '..', '..'),
      );
      baseDir = Directory(path.join(rootDir.path, 'Download'));
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final defaultAppDir = Directory(
      path.join(baseDir.path, 'RSpace_App', 'data'),
    );
    if (!await defaultAppDir.exists()) {
      await defaultAppDir.create(recursive: true);
    }
    return defaultAppDir.path;
  }

  Future<String?> get _baseBackupPath async {
    return await loadCustomBackupPath();
  }

  Future<String> get finishedDiscussionsExportPath async {
    final basePath = await _appBasePath;
    final exportDir = Directory(path.join(basePath, 'finish_discussions'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  Future<String> get rspaceBackupPath async {
    final basePath = await _baseBackupPath;
    if (basePath == null || basePath.isEmpty) {
      throw Exception('Folder backup utama belum diatur.');
    }
    final backupDir = Directory(path.join(basePath, 'RSpace_backup'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  Future<String> get perpuskuBackupPath async {
    final basePath = await _baseBackupPath;
    if (basePath == null || basePath.isEmpty) {
      throw Exception('Folder backup utama belum diatur.');
    }
    final backupDir = Directory(path.join(basePath, 'PerpusKu_backup'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  Future<String> get contentsPath async =>
      path.join(await _baseDataPath, 'contents');
  Future<String> get topicsPath async =>
      path.join(await contentsPath, 'topics');
  Future<String> get myTasksPath async =>
      path.join(await contentsPath, 'my_tasks.json');
  Future<String> get timeLogPath async =>
      path.join(await contentsPath, 'time_log.json');
  Future<String> get logTaskPresetsPath async =>
      path.join(await contentsPath, 'log_task_presets.json');

  Future<String> get feedbackPath async =>
      path.join(await contentsPath, 'feedback.json');

  Future<String> get promptLibraryPath async =>
      path.join(await _baseDataPath, 'prompt_library');

  Future<String> get countdownTimersPath async =>
      path.join(await contentsPath, 'countdown_timers.json');

  Future<String> get progressPath async => // Path baru untuk fitur Progress
      path.join(await _baseDataPath, 'progress');

  // ==> TAMBAHKAN PATH BARU UNTUK FILE PROFIL PENGGUNA
  Future<String> get userProfilePath async =>
      path.join(await _baseDataPath, 'user_profile.dat');

  Future<String> get perpuskuDataPath async {
    String? customPath = await loadPerpuskuDataPath();
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }
    return path.join(await _baseDataPath, 'perpusku_data');
  }

  Future<String> getTopicPath(String topicName) async {
    return path.join(await topicsPath, topicName);
  }

  Future<String> getTopicConfigPath(String topicName) async {
    return path.join(await getTopicPath(topicName), 'topic_config.json');
  }

  Future<String> getSubjectPath(String topicPath, String subjectName) async {
    return path.join(topicPath, '$subjectName.json');
  }
}
