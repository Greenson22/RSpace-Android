// lib/data/services/path_service.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'shared_preferences_service.dart';

class PathService {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  // ... (_baseDataPath tetap sama)
  Future<String> get _baseDataPath async {
    // Logika ini sekarang berlaku untuk semua platform yang didukung.

    // Minta izin hanya jika di Android.
    if (Platform.isAndroid) {
      if (!await Permission.manageExternalStorage.request().isGranted) {
        throw Exception(
          'Izin "Akses semua file" diperlukan untuk menyimpan data di folder pilihan Anda.',
        );
      }
    }

    // Coba muat path kustom yang disimpan pengguna.
    String? customPath = await _prefsService.loadCustomStoragePath();

    if (customPath != null && customPath.isNotEmpty) {
      final customDir = Directory(customPath);
      // Pastikan path kustom ada, jika tidak buat baru.
      if (!await customDir.exists()) {
        await customDir.create(recursive: true);
      }
      // Pastikan subfolder data ada di dalam path kustom.
      final dataDir = Directory(path.join(customPath, 'RSpace_data', 'data'));
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      return dataDir.path;
    }

    // === LOGIKA DEFAULT JIKA TIDAK ADA PATH KUSTOM ===
    Directory? baseDir;
    if (Platform.isAndroid) {
      // Default untuk Android: folder Download.
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
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // Default untuk semua OS desktop: folder Documents.
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      // Fallback untuk OS lain (seperti iOS).
      baseDir = await getApplicationDocumentsDirectory();
    }

    if (baseDir == null) {
      throw Exception("Tidak dapat menentukan direktori default.");
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
    return await _prefsService.loadCustomStoragePath();
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

  // ==> LOKASI BACKUP PERPUSKU SELALU DI DALAM FOLDER UTAMA <==
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

  // ... (path lain tetap sama)
  Future<String> get contentsPath async =>
      path.join(await _baseDataPath, 'contents');
  Future<String> get topicsPath async =>
      path.join(await contentsPath, 'topics');
  Future<String> get myTasksPath async =>
      path.join(await contentsPath, 'my_tasks.json');

  // ==> PATH SUMBER DATA PERPUSKU SEKARANG MEMERIKSA PREFERENSI <==
  Future<String> get perpuskuDataPath async {
    String? customPath = await _prefsService.loadPerpuskuDataPath();
    if (customPath != null && customPath.isNotEmpty) {
      return customPath; // Gunakan path kustom jika ada
    }
    // Jika tidak ada, gunakan path default di dalam folder data utama
    return path.join(await _baseDataPath, 'perpusku_data');
  }

  // ... (sisa kode tetap sama)
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
