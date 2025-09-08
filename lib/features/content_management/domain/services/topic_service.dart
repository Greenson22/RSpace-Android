// lib/data/services/topic_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/topic_model.dart';
import '../../../../data/services/path_service.dart';

class TopicService {
  final PathService _pathService = PathService();
  static const String _defaultIcon = '📁';

  // FUNGSI DIUBAH TOTAL UNTUK MEMBACA, MENGURUTKAN, DAN MEMPERBAIKI POSISI
  Future<List<Topic>> getTopics() async {
    // Menggunakan await untuk mendapatkan topicsPath
    final topicsPath = await _pathService.topicsPath;
    final directory = Directory(topicsPath);
    if (!await directory.exists()) {
      try {
        await directory.create(recursive: true);
        return [];
      } catch (e) {
        throw Exception('Gagal membuat direktori: $topicsPath\nError: $e');
      }
    }

    final folderNames = directory
        .listSync()
        .whereType<Directory>()
        .map((item) => path.basename(item.path))
        .toList();

    List<Topic> topics = [];
    for (var name in folderNames) {
      final config = await _getTopicConfig(name);
      topics.add(
        Topic(
          name: name,
          icon: config['icon'] as String? ?? _defaultIcon,
          position: config['position'] as int? ?? -1,
          isHidden: config['isHidden'] as bool? ?? false, // ==> DITAMBAHKAN
        ),
      );
    }

    final positionedTopics = topics.where((t) => t.position != -1).toList();
    final unpositionedTopics = topics.where((t) => t.position == -1).toList();

    positionedTopics.sort((a, b) => a.position.compareTo(b.position));

    int maxPosition = positionedTopics.isNotEmpty
        ? positionedTopics
              .map((t) => t.position)
              .reduce((a, b) => a > b ? a : b)
        : -1;

    for (final topic in unpositionedTopics) {
      maxPosition++;
      topic.position = maxPosition;
      await _saveTopicConfig(topic);
    }

    final allTopics = [...positionedTopics, ...unpositionedTopics];
    allTopics.sort((a, b) => a.position.compareTo(b.position));

    bool needsResave = false;
    for (int i = 0; i < allTopics.length; i++) {
      if (allTopics[i].position != i) {
        allTopics[i].position = i;
        needsResave = true;
      }
    }

    if (needsResave) {
      await saveTopicsOrder(allTopics);
    }

    return allTopics;
  }

  // FUNGSI BARU UNTUK MENYIMPAN URUTAN SEMUA TOPIK
  Future<void> saveTopicsOrder(List<Topic> topics) async {
    for (int i = 0; i < topics.length; i++) {
      final topic = topics[i];
      topic.position = i;
      await _saveTopicConfig(topic);
    }
  }

  Future<Map<String, dynamic>> _getTopicConfig(String topicName) async {
    // Menggunakan await untuk mendapatkan configPath
    final configPath = await _pathService.getTopicConfigPath(topicName);
    final configFile = File(configPath);

    if (await configFile.exists()) {
      try {
        final jsonString = await configFile.readAsString();
        if (jsonString.isNotEmpty) {
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          return {
            'icon': jsonData['icon'] as String? ?? _defaultIcon,
            'position': jsonData['position'] as int?,
            'isHidden':
                jsonData['isHidden'] as bool? ?? false, // ==> DITAMBAHKAN
          };
        }
      } catch (e) {
        // Abaikan error dan gunakan config default
      }
    }
    return {'icon': _defaultIcon, 'position': -1, 'isHidden': false};
  }

  Future<void> _saveTopicConfig(Topic topic) async {
    // Menggunakan await untuk mendapatkan configPath
    final configPath = await _pathService.getTopicConfigPath(topic.name);
    final configFile = File(configPath);
    try {
      await configFile.create(recursive: true);
      await configFile.writeAsString(jsonEncode(topic.toConfigJson()));
    } catch (e) {
      // Abaikan jika gagal menulis file
    }
  }

  // ==> FUNGSI BARU <==
  Future<void> updateTopicVisibility(String topicName, bool isHidden) async {
    final config = await _getTopicConfig(topicName);
    final topic = Topic(
      name: topicName,
      icon: config['icon'] as String? ?? _defaultIcon,
      position: config['position'] as int? ?? -1,
      isHidden: isHidden,
    );
    await _saveTopicConfig(topic);
  }

  Future<void> updateTopicIcon(String topicName, String newIcon) async {
    final config = await _getTopicConfig(topicName);
    final topic = Topic(
      name: topicName,
      icon: newIcon,
      position: config['position'] as int? ?? -1,
      isHidden: config['isHidden'] as bool? ?? false,
    );
    await _saveTopicConfig(topic);
  }

  Future<void> addTopic(String topicName) async {
    if (topicName.isEmpty) throw Exception('Nama topik tidak boleh kosong.');

    // Menggunakan await untuk mendapatkan newTopicPath
    final newTopicPath = await _pathService.getTopicPath(topicName);
    final directory = Directory(newTopicPath);

    if (await directory.exists()) {
      throw Exception('Topik dengan nama "$topicName" sudah ada.');
    }

    try {
      await directory.create();
      final currentTopics = await getTopics();
      final newPosition = currentTopics.length;
      final newTopic = Topic(
        name: topicName,
        icon: _defaultIcon,
        position: newPosition,
      );
      await _saveTopicConfig(newTopic);
    } catch (e) {
      throw Exception('Gagal membuat topik: $e');
    }
  }

  Future<void> renameTopic(String oldName, String newName) async {
    if (newName.isEmpty) throw Exception('Nama baru tidak boleh kosong.');
    // Menggunakan await untuk mendapatkan oldPath dan newPath
    final oldPath = await _pathService.getTopicPath(oldName);
    final newPath = await _pathService.getTopicPath(newName);
    final oldDir = Directory(oldPath);
    if (!await oldDir.exists()) {
      throw Exception('Topik yang ingin diubah tidak ditemukan.');
    }
    if (await Directory(newPath).exists()) {
      throw Exception('Topik dengan nama "$newName" sudah ada.');
    }
    try {
      final oldConfig = await _getTopicConfig(oldName);
      await oldDir.rename(newPath);
      final newTopic = Topic(
        name: newName,
        icon: oldConfig['icon'] as String? ?? _defaultIcon,
        position: oldConfig['position'] as int? ?? -1,
        isHidden: oldConfig['isHidden'] as bool? ?? false,
      );
      await _saveTopicConfig(newTopic);
    } catch (e) {
      throw Exception('Gagal mengubah nama topik: $e');
    }
  }

  Future<void> deleteTopic(String topicName) async {
    // Menggunakan await untuk mendapatkan topicPath
    final topicPath = await _pathService.getTopicPath(topicName);
    final directory = Directory(topicPath);
    if (!await directory.exists()) {
      throw Exception('Topik yang ingin dihapus tidak ditemukan.');
    }
    try {
      await directory.delete(recursive: true);
      final remainingTopics = await getTopics();
      await saveTopicsOrder(remainingTopics);
    } catch (e) {
      throw Exception('Gagal menghapus topik: $e');
    }
  }
}
