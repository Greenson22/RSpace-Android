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

  // Kunci dan fungsi untuk Download Path dihapus

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

  Future<String> get _baseBackupPath async {
    final appBase = await _appBasePath;
    final backupDir = Directory(path.join(appBase, 'Backup'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  // ==> GETTER BARU UNTUK FOLDER FOTO PROFIL <==
  Future<String> get profilePicturesPath async {
    final appBase = await _appBasePath;
    final profilePicDir = Directory(path.join(appBase, 'Profile_Pictures'));
    if (!await profilePicDir.exists()) {
      await profilePicDir.create(recursive: true);
    }
    return profilePicDir.path;
  }

  // ==> GETTER BARU UNTUK FOLDER DOWNLOAD UTAMA <==
  Future<String> get downloadsPath async {
    final appBase = await _appBasePath;
    final downloadsDir = Directory(path.join(appBase, 'Downloads'));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir.path;
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
    final backupDir = Directory(path.join(basePath, 'RSpace_backup'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  Future<String> get perpuskuBackupPath async {
    final basePath = await _baseBackupPath;
    final backupDir = Directory(path.join(basePath, 'PerpusKu_backup'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  Future<String> get contentsPath async =>
      path.join(await _baseDataPath, 'contents');

  // ==> PENAMBAHAN BARU <==
  Future<String> get assetsPath async {
    final dataPath = await _baseDataPath;
    final assetsDir = Directory(path.join(dataPath, 'assets'));
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    return assetsDir.path;
  }

  // ==> PERUBAHAN DI SINI <==
  // Path untuk game ular sekarang berada di dalam folder 'contents'
  Future<String> get snakeGamePath async {
    final contents = await contentsPath;
    final snakeDir = Directory(path.join(contents, 'snake_game'));
    if (!await snakeDir.exists()) {
      await snakeDir.create(recursive: true);
    }
    return snakeDir.path;
  }

  Future<String> get topicsPath async =>
      path.join(await contentsPath, 'topics');
  Future<String> get myTasksPath async =>
      path.join(await contentsPath, 'my_tasks.json');
  Future<String> get timeLogPath async =>
      path.join(await contentsPath, 'time_log.json');
  Future<String> get logTaskPresetsPath async =>
      path.join(await contentsPath, 'log_task_presets.json');

  Future<String> get pointPresetsPath async =>
      path.join(await contentsPath, 'point_presets.json');

  Future<String> get feedbackPath async =>
      path.join(await contentsPath, 'feedback.json');

  Future<String> get promptLibraryPath async =>
      path.join(await contentsPath, 'prompt_library');

  Future<String> get countdownTimersPath async =>
      path.join(await contentsPath, 'countdown_timers.json');

  Future<String> get progressPath async =>
      path.join(await contentsPath, 'progress');

  Future<String> get quizPath async => path.join(await contentsPath, 'quizzes');

  Future<String> get userProfilePath async =>
      path.join(await contentsPath, 'user_profile.dat');

  Future<String> get bookmarksPath async =>
      path.join(await contentsPath, 'bookmarks.json');

  Future<String> get motivationalQuotesPath async =>
      path.join(await contentsPath, 'motivational_quotes.json');

  Future<String> get geminiSettingsPath async =>
      path.join(await contentsPath, 'gemini_settings.json');

  Future<String> get themeSettingsPath async =>
      path.join(await contentsPath, 'theme_settings.json');

  Future<String> get dashboardSettingsPath async =>
      path.join(await contentsPath, 'dashboard_settings.json');

  Future<String> get perpuskuDataPath async {
    final basePath = await _appBasePath;
    final perpuskuDir = Directory(path.join(basePath, 'PerpusKu', 'data'));
    if (!await perpuskuDir.exists()) {
      await perpuskuDir.create(recursive: true);
    }
    return perpuskuDir.path;
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
