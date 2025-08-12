// lib/data/services/path_service.dart
import 'package:path/path.dart' as path;

class PathService {
  // Ubah path ini sesuai dengan direktori data Anda
  static const String _baseDataPath =
      '/home/lemon-manis-22/RikalG22/RSpace_data/data';

  String get contentsPath => path.join(_baseDataPath, 'contents');
  String get topicsPath => path.join(contentsPath, 'topics');
  String get myTasksPath => path.join(contentsPath, 'my_tasks.json');

  String getSubjectPath(String topicPath, String subjectName) {
    return path.join(topicPath, '$subjectName.json');
  }

  String getTopicPath(String topicName) {
    return path.join(topicsPath, topicName);
  }
}
