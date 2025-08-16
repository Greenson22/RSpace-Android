// lib/data/services/path_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'shared_preferences_service.dart';

class PathService {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  // Path ini untuk DATA APLIKASI UTAMA
  Future<String> get _baseDataPath async {
    if (Platform.isAndroid) {
      if (!await Permission.manageExternalStorage.request().isGranted) {
        throw Exception(
          'Izin "Akses semua file" diperlukan untuk menyimpan data di folder pilihan Anda.',
        );
      }
    }

    String? customPath = await _prefsService.loadCustomStoragePath();

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

  // DIUBAH: Path ini KHUSUS untuk FOLDER BACKUP
  Future<String?> get _baseBackupPath async {
    // DIHAPUS: Blok 'if (kDebugMode)' dihapus agar selalu memuat path dari preferensi.
    // Sekarang, path yang Anda pilih di UI akan selalu digunakan.
    return await _prefsService.loadCustomBackupPath();
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

  Future<String> get perpuskuDataPath async {
    // DIHAPUS: Blok 'if (kDebugMode)' dihapus agar selalu memuat path dari preferensi.
    // Sekarang, path sumber data PerpusKu yang Anda pilih akan selalu digunakan untuk backup.
    String? customPath = await _prefsService.loadPerpuskuDataPath();
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }
    // Ini adalah path default jika Anda tidak mengatur path kustom.
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
