import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discussion_model.dart';
import '../models/my_task_model.dart';

class SharedPreferencesService {
  static const String _sortTypeKey = 'sort_type';
  static const String _sortAscendingKey = 'sort_ascending';
  static const String _filterTypeKey = 'filter_type';
  static const String _filterValueKey = 'filter_value';
  static const String _themeKey = 'theme_preference';

  Future<void> saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  Future<bool> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false; // Default to light mode
  }

  Future<void> saveSortPreferences(String sortType, bool sortAscending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortTypeKey, sortType);
    await prefs.setBool(_sortAscendingKey, sortAscending);
  }

  Future<Map<String, dynamic>> loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final sortType = prefs.getString(_sortTypeKey) ?? 'date';
    final sortAscending = prefs.getBool(_sortAscendingKey) ?? true;
    return {'sortType': sortType, 'sortAscending': sortAscending};
  }

  Future<void> saveFilterPreference(
    String? filterType,
    String? filterValue,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (filterType != null) {
      await prefs.setString(_filterTypeKey, filterType);
    } else {
      await prefs.remove(_filterTypeKey);
    }
    if (filterValue != null) {
      await prefs.setString(_filterValueKey, filterValue);
    } else {
      await prefs.remove(_filterValueKey);
    }
  }

  Future<Map<String, String?>> loadFilterPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final filterType = prefs.getString(_filterTypeKey);
    final filterValue = prefs.getString(_filterValueKey);
    return {'filterType': filterType, 'filterValue': filterValue};
  }
}

class LocalFileService {
  final String _topicsPath =
      '/home/lemon-manis-22/RikalG22/RSpace_data/data/contents/topics';

  String getContentsPath() {
    // Mengembalikan path ke direktori 'contents'
    return path.dirname(_topicsPath);
  }

  Future<List<String>> getTopics() async {
    final directory = Directory(_topicsPath);
    if (!await directory.exists()) {
      try {
        await directory.create(recursive: true);
        return [];
      } catch (e) {
        throw Exception('Gagal membuat direktori: $_topicsPath \nError: $e');
      }
    }
    final folderNames = directory
        .listSync()
        .whereType<Directory>()
        .map((item) => path.basename(item.path))
        .toList();
    folderNames.sort();
    return folderNames;
  }

  Future<void> addTopic(String topicName) async {
    if (topicName.isEmpty) {
      throw Exception('Nama topik tidak boleh kosong.');
    }
    final newTopicPath = path.join(_topicsPath, topicName);
    final directory = Directory(newTopicPath);
    if (await directory.exists()) {
      throw Exception('Topik dengan nama "$topicName" sudah ada.');
    }
    try {
      await directory.create();
    } catch (e) {
      throw Exception('Gagal membuat topik: $e');
    }
  }

  Future<void> renameTopic(String oldName, String newName) async {
    if (newName.isEmpty) {
      throw Exception('Nama baru tidak boleh kosong.');
    }
    final oldPath = path.join(_topicsPath, oldName);
    final newPath = path.join(_topicsPath, newName);

    final oldDir = Directory(oldPath);
    final newDir = Directory(newPath);

    if (!await oldDir.exists()) {
      throw Exception('Topik yang ingin diubah tidak ditemukan.');
    }
    if (await newDir.exists()) {
      throw Exception('Topik dengan nama "$newName" sudah ada.');
    }
    try {
      await oldDir.rename(newPath);
    } catch (e) {
      throw Exception('Gagal mengubah nama topik: $e');
    }
  }

  Future<void> deleteTopic(String topicName) async {
    final topicPath = path.join(_topicsPath, topicName);
    final directory = Directory(topicPath);

    if (!await directory.exists()) {
      throw Exception('Topik yang ingin dihapus tidak ditemukan.');
    }
    try {
      await directory.delete(recursive: true);
    } catch (e) {
      throw Exception('Gagal menghapus topik: $e');
    }
  }

  Future<List<String>> getSubjects(String topicPath) async {
    final directory = Directory(topicPath);
    if (!await directory.exists()) {
      throw Exception('Folder tidak ditemukan: $topicPath');
    }
    final fileNames = directory
        .listSync()
        .whereType<File>()
        .where((item) => item.path.toLowerCase().endsWith('.json'))
        .where((item) => path.basename(item.path) != 'topic_config.json')
        .map((item) => path.basenameWithoutExtension(item.path))
        .toList();
    fileNames.sort();
    return fileNames;
  }

  Future<void> addSubject(String topicPath, String subjectName) async {
    if (subjectName.isEmpty) {
      throw Exception('Nama subject tidak boleh kosong.');
    }
    final filePath = path.join(topicPath, '$subjectName.json');
    final file = File(filePath);
    if (await file.exists()) {
      throw Exception('Subject dengan nama "$subjectName" sudah ada.');
    }
    try {
      await file.writeAsString(jsonEncode({'content': []}));
    } catch (e) {
      throw Exception('Gagal membuat subject: $e');
    }
  }

  Future<void> renameSubject(
    String topicPath,
    String oldName,
    String newName,
  ) async {
    if (newName.isEmpty) {
      throw Exception('Nama baru tidak boleh kosong.');
    }
    final oldPath = path.join(topicPath, '$oldName.json');
    final newPath = path.join(topicPath, '$newName.json');
    final oldFile = File(oldPath);
    final newFile = File(newPath);

    if (!await oldFile.exists()) {
      throw Exception('Subject yang ingin diubah tidak ditemukan.');
    }
    if (await newFile.exists()) {
      throw Exception('Subject dengan nama "$newName" sudah ada.');
    }
    try {
      await oldFile.rename(newPath);
    } catch (e) {
      throw Exception('Gagal mengubah nama subject: $e');
    }
  }

  Future<void> deleteSubject(String topicPath, String subjectName) async {
    final filePath = path.join(topicPath, '$subjectName.json');
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Subject yang ingin dihapus tidak ditemukan.');
    }
    try {
      await file.delete();
    } catch (e) {
      throw Exception('Gagal menghapus subject: $e');
    }
  }

  Future<List<Discussion>> loadDiscussions(String jsonFilePath) async {
    final file = File(jsonFilePath);
    if (!await file.exists()) {
      await file.writeAsString(jsonEncode({'content': []}));
    }
    final jsonString = await file.readAsString();
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    final contentList = jsonData['content'] as List<dynamic>;

    return contentList.map((item) => Discussion.fromJson(item)).toList();
  }

  Future<void> saveDiscussions(
    String filePath,
    List<Discussion> discussions,
  ) async {
    final file = File(filePath);
    final newJsonData = {
      'content': discussions.map((d) => d.toJson()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(newJsonData));
  }

  Future<List<TaskCategory>> loadMyTasks() async {
    final contentsPath = getContentsPath();
    final filePath = path.join(contentsPath, 'my_tasks.json');
    final file = File(filePath);

    if (!await file.exists()) {
      // Buat file default jika tidak ditemukan
      await file.writeAsString(
        jsonEncode({
          "categories": [
            {
              "name": "Pekerjaan",
              "icon": "work",
              "tasks": [
                {
                  "name": "Selesaikan laporan mingguan",
                  "count": 2,
                  "date": "2024-08-15",
                  "checked": false,
                },
                {
                  "name": "Meeting dengan tim",
                  "count": 1,
                  "date": "2024-08-16",
                  "checked": true,
                },
              ],
            },
            {
              "name": "Rumah",
              "icon": "home",
              "tasks": [
                {
                  "name": "Bersihkan kamar",
                  "count": 0,
                  "date": "2024-08-18",
                  "checked": false,
                },
              ],
            },
          ],
        }),
      );
    }

    final jsonString = await file.readAsString();
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    final categoriesList = jsonData['categories'] as List<dynamic>;

    return categoriesList.map((item) => TaskCategory.fromJson(item)).toList();
  }

  String getTopicsPath() => _topicsPath;
}
