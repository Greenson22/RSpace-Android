// lib/data/services/path_service.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'shared_preferences_service.dart'; // Import service preferensi

class PathService {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  Future<String> get _baseDataPath async {
    if (Platform.isAndroid) {
      final location = await _prefsService.loadStorageLocation();
      Directory? baseDir;

      if (location == 'external') {
        // Minta izin untuk penyimpanan eksternal
        if (await Permission.storage.request().isGranted) {
          baseDir = await getExternalStorageDirectory();
        } else {
          // Jika izin ditolak, kembali ke internal sebagai fallback
          baseDir = await getApplicationDocumentsDirectory();
        }
      } else {
        // Default adalah penyimpanan internal
        baseDir = await getApplicationDocumentsDirectory();
      }

      final rikalG22Directory = Directory(path.join(baseDir!.path, 'RikalG22'));
      if (!await rikalG22Directory.exists()) {
        await rikalG22Directory.create(recursive: true);
      }
      return path.join(rikalG22Directory.path, 'RSpace_data', 'data');
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
