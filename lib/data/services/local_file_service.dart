import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/discussion_model.dart';

class LocalFileService {
  // Path utama sekarang terpusat di sini
  final String _topicsPath =
      '/home/lemon-manis-22/RikalG22/RSpace_data/data/contents/topics';

  // Sebelumnya _getFolders di TopicsPage
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

  // Sebelumnya _getJsonFiles di SubjectsPage
  Future<List<String>> getSubjects(String topicPath) async {
    final directory = Directory(topicPath);
    if (!await directory.exists()) {
      throw Exception('Folder tidak ditemukan: $topicPath');
    }
    final fileNames = directory
        .listSync()
        .whereType<File>()
        .where((item) => item.path.toLowerCase().endsWith('.json'))
        .map((item) => path.basenameWithoutExtension(item.path))
        .toList();
    fileNames.sort();
    return fileNames;
  }

  // Sebelumnya _loadDiscussions di DiscussionsPage
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

  // Sebelumnya _saveDiscussions di DiscussionsPage
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

  // Mendapatkan path topik utama
  String getTopicsPath() => _topicsPath;
}
