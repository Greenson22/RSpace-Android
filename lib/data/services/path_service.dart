// lib/data/services/path_service.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PathService {
  // PathService sekarang akan menginisialisasi path secara asynchronous.
  // Oleh karena itu, kita membuat _baseDataPath menjadi Future.
  Future<String> get _baseDataPath async {
    if (Platform.isAndroid) {
      // Jika OS adalah Android, dapatkan direktori dokumen internal.
      final directory = await getApplicationDocumentsDirectory();
      // Buat folder RikalG22 di dalam direktori tersebut.
      final rikalG22Directory = Directory(
        path.join(directory.path, 'RikalG22'),
      );
      if (!await rikalG22Directory.exists()) {
        await rikalG22Directory.create(recursive: true);
      }
      return path.join(rikalG22Directory.path, 'data');
    } else if (Platform.isLinux) {
      // Jika OS adalah Linux, gunakan path yang sudah ada.
      return '/home/lemon-manis-22/RikalG22/RSpace_data/data';
    } else {
      // Path default jika OS bukan Android atau Linux.
      final directory = await getApplicationDocumentsDirectory();
      return path.join(directory.path, 'data');
    }
  }

  // Semua getter path sekarang menjadi Future<String>
  Future<String> get contentsPath async =>
      path.join(await _baseDataPath, 'contents');
  Future<String> get topicsPath async =>
      path.join(await contentsPath, 'topics');
  Future<String> get myTasksPath async =>
      path.join(await contentsPath, 'my_tasks.json');

  Future<String> getSubjectPath(String topicPath, String subjectName) async {
    return path.join(topicPath, '$subjectName.json');
  }

  Future<String> getTopicPath(String topicName) async {
    return path.join(await topicsPath, topicName);
  }

  Future<String> getTopicConfigPath(String topicName) async {
    return path.join(await topicsPath, topicName, 'topic_config.json');
  }
}
