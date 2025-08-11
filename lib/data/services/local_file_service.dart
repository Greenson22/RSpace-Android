import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/discussion_model.dart';

class LocalFileService {
  final String _topicsPath =
      '/home/lemon-manis-22/RikalG22/RSpace_data/data/contents/topics';

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
        .map((item) => path.basenameWithoutExtension(item.path))
        .toList();
    fileNames.sort();
    return fileNames;
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

  String getTopicsPath() => _topicsPath;
}
