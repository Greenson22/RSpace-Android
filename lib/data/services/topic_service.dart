// lib/data/services/topic_service.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'path_service.dart';

class TopicService {
  final PathService _pathService = PathService();

  Future<List<String>> getTopics() async {
    final directory = Directory(_pathService.topicsPath);
    if (!await directory.exists()) {
      try {
        await directory.create(recursive: true);
        return [];
      } catch (e) {
        throw Exception(
          'Gagal membuat direktori: ${_pathService.topicsPath}\nError: $e',
        );
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
    if (topicName.isEmpty) throw Exception('Nama topik tidak boleh kosong.');

    final newTopicPath = _pathService.getTopicPath(topicName);
    final directory = Directory(newTopicPath);

    if (await directory.exists())
      throw Exception('Topik dengan nama "$topicName" sudah ada.');

    try {
      await directory.create();
    } catch (e) {
      throw Exception('Gagal membuat topik: $e');
    }
  }

  Future<void> renameTopic(String oldName, String newName) async {
    if (newName.isEmpty) throw Exception('Nama baru tidak boleh kosong.');

    final oldPath = _pathService.getTopicPath(oldName);
    final newPath = _pathService.getTopicPath(newName);

    final oldDir = Directory(oldPath);
    if (!await oldDir.exists())
      throw Exception('Topik yang ingin diubah tidak ditemukan.');

    if (await Directory(newPath).exists())
      throw Exception('Topik dengan nama "$newName" sudah ada.');

    try {
      await oldDir.rename(newPath);
    } catch (e) {
      throw Exception('Gagal mengubah nama topik: $e');
    }
  }

  Future<void> deleteTopic(String topicName) async {
    final topicPath = _pathService.getTopicPath(topicName);
    final directory = Directory(topicPath);

    if (!await directory.exists())
      throw Exception('Topik yang ingin dihapus tidak ditemukan.');

    try {
      await directory.delete(recursive: true);
    } catch (e) {
      throw Exception('Gagal menghapus topik: $e');
    }
  }
}
