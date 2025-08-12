// lib/data/services/topic_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/topic_model.dart'; // ==> DITAMBAHKAN
import 'path_service.dart';

class TopicService {
  final PathService _pathService = PathService();
  static const String _defaultIcon = '📁'; // ==> DITAMBAHKAN

  // ==> FUNGSI DIUBAH UNTUK MENGEMBALIKAN List<Topic> <==
  Future<List<Topic>> getTopics() async {
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

    final List<Topic> topics = [];
    for (var name in folderNames) {
      final icon = await _getIconForTopic(name);
      topics.add(Topic(name: name, icon: icon));
    }
    return topics;
  }

  // ==> FUNGSI BARU <==
  Future<String> _getIconForTopic(String topicName) async {
    final configPath = _pathService.getTopicConfigPath(topicName);
    final configFile = File(configPath);

    if (await configFile.exists()) {
      try {
        final jsonString = await configFile.readAsString();
        if (jsonString.isNotEmpty) {
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          return jsonData['icon'] as String? ?? _defaultIcon;
        }
      } catch (e) {
        // Abaikan jika ada error baca/parse, gunakan ikon default
      }
    }
    // Jika file tidak ada, atau kosong, atau error, buat file dengan ikon default
    try {
      await configFile.writeAsString(jsonEncode({'icon': _defaultIcon}));
    } catch (e) {
      // Abaikan jika gagal menulis file
    }
    return _defaultIcon;
  }

  // ==> FUNGSI BARU <==
  Future<void> updateTopicIcon(String topicName, String newIcon) async {
    final configPath = _pathService.getTopicConfigPath(topicName);
    final configFile = File(configPath);
    try {
      await configFile.writeAsString(jsonEncode({'icon': newIcon}));
    } catch (e) {
      throw Exception('Gagal memperbarui ikon topik: $e');
    }
  }

  Future<void> addTopic(String topicName) async {
    if (topicName.isEmpty) throw Exception('Nama topik tidak boleh kosong.');

    final newTopicPath = _pathService.getTopicPath(topicName);
    final directory = Directory(newTopicPath);

    if (await directory.exists()) {
      throw Exception('Topik dengan nama "$topicName" sudah ada.');
    }

    try {
      await directory.create();
      // ==> TAMBAHKAN PEMBUATAN FILE KONFIGURASI DEFAULT <==
      await _getIconForTopic(topicName);
    } catch (e) {
      throw Exception('Gagal membuat topik: $e');
    }
  }

  Future<void> renameTopic(String oldName, String newName) async {
    if (newName.isEmpty) throw Exception('Nama baru tidak boleh kosong.');

    final oldPath = _pathService.getTopicPath(oldName);
    final newPath = _pathService.getTopicPath(newName);

    final oldDir = Directory(oldPath);
    if (!await oldDir.exists()) {
      throw Exception('Topik yang ingin diubah tidak ditemukan.');
    }

    if (await Directory(newPath).exists()) {
      throw Exception('Topik dengan nama "$newName" sudah ada.');
    }

    try {
      await oldDir.rename(newPath);
    } catch (e) {
      throw Exception('Gagal mengubah nama topik: $e');
    }
  }

  Future<void> deleteTopic(String topicName) async {
    final topicPath = _pathService.getTopicPath(topicName);
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
}
