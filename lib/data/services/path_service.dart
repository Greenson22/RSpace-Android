// lib/data/services/path_service.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'shared_preferences_service.dart';

class PathService {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  Future<String> get _baseDataPath async {
    // ==> LOGIKA DIGABUNGKAN UNTUK ANDROID DAN LINUX <==
    if (Platform.isAndroid || Platform.isLinux) {
      // Minta izin hanya jika di Android
      if (Platform.isAndroid) {
        if (!await Permission.manageExternalStorage.request().isGranted) {
          throw Exception(
            'Izin "Akses semua file" diperlukan untuk menyimpan data di folder pilihan Anda.',
          );
        }
      }

      // Coba muat path kustom yang disimpan pengguna (berlaku untuk Android & Linux)
      String? customPath = await _prefsService.loadCustomStoragePath();

      if (customPath != null && customPath.isNotEmpty) {
        final customDir = Directory(customPath);
        // Pastikan path kustom ada, jika tidak buat baru
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }
        // Pastikan subfolder data ada di dalam path kustom
        final dataDir = Directory(path.join(customPath, 'RSpace_data', 'data'));
        if (!await dataDir.exists()) {
          await dataDir.create(recursive: true);
        }
        return dataDir.path;
      }

      // === LOGIKA DEFAULT JIKA TIDAK ADA PATH KUSTOM ===
      Directory? baseDir;
      if (Platform.isAndroid) {
        // Default untuk Android: folder Download
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
      } else if (Platform.isLinux) {
        // Default untuk Linux: folder Documents
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
    } else {
      // Fallback untuk OS lain (Windows, macOS, iOS)
      final directory = await getApplicationDocumentsDirectory();
      return path.join(directory.path, 'data');
    }
  }

  Future<String> get contentsPath async =>
      path.join(await _baseDataPath, 'contents');
  Future<String> get topicsPath async =>
      path.join(await contentsPath, 'topics');
  Future<String> get myTasksPath async =>
      path.join(await contentsPath, 'my_tasks.json');

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
