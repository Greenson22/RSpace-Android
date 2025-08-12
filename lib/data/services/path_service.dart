// lib/data/services/path_service.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'shared_preferences_service.dart';

class PathService {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  Future<String> get _baseDataPath async {
    if (Platform.isAndroid) {
      // ==> PERUBAHAN UTAMA: Meminta izin MANAGE_EXTERNAL_STORAGE <==
      // Izin ini lebih kuat dan diperlukan untuk Android 11+
      if (!await Permission.manageExternalStorage.request().isGranted) {
        throw Exception(
          'Izin "Akses semua file" diperlukan untuk menyimpan data di folder pilihan Anda.',
        );
      }

      // Coba muat path kustom yang disimpan pengguna
      String? customPath = await _prefsService.loadCustomStoragePath();

      if (customPath != null && customPath.isNotEmpty) {
        final customDir = Directory(customPath);
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

      // Jika tidak ada path kustom, gunakan folder Download sebagai default
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception(
          "Tidak dapat menemukan direktori penyimpanan eksternal.",
        );
      }

      // Membuat path ke folder Download secara manual dari root
      // Direktori root biasanya 4 level di atas direktori data aplikasi
      final rootDir = Directory(
        path.join(externalDir.path, '..', '..', '..', '..'),
      );
      final downloadDirPath = path.join(rootDir.path, 'Download');

      final defaultDir = Directory(downloadDirPath);

      final defaultAppDir = Directory(
        path.join(defaultDir.path, 'RSpace_App', 'RSpace_data', 'data'),
      );
      if (!await defaultAppDir.exists()) {
        await defaultAppDir.create(recursive: true);
      }
      return defaultAppDir.path;
    } else if (Platform.isLinux) {
      // Path untuk Linux tidak berubah
      return '/home/lemon-manis-22/RikalG22/RSpace_data/data';
    } else {
      // Fallback untuk OS lain
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
