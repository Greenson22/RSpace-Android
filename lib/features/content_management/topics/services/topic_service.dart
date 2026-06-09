// lib/data/services/topic_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/topic_model.dart';
import '../../../../core/services/path_service.dart';

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
      // 1. Buat folder topik di RSpace
      await directory.create();
      final currentTopics = await getTopics();
      final newPosition = currentTopics.length;
      final newTopic = Topic(
        name: topicName,
        icon: _defaultIcon,
        position: newPosition,
      );
      await _saveTopicConfig(newTopic);

      // 2. Buat juga folder yang sesuai di PerpusKu/data/file_contents/topics
      try {
        final perpuskuDataPath = await _pathService.perpuskuDataPath;
        final perpuskuTopicPath = path.join(
          perpuskuDataPath,
          'file_contents',
          'topics',
          topicName,
        );
        final perpuskuDirectory = Directory(perpuskuTopicPath);
        if (!await perpuskuDirectory.exists()) {
          await perpuskuDirectory.create(recursive: true);
        }
      } catch (e) {
        // Jika pembuatan folder di PerpusKu gagal, tampilkan pesan error
        // tapi jangan batalkan pembuatan topik di RSpace.
        debugPrint(
          'Gagal membuat folder pendamping di PerpusKu untuk topik "$topicName": $e',
        );
      }
    } catch (e) {
      throw Exception('Gagal membuat topik: $e');
    }
  }

  // >> FUNGSI INI TELAH DIPERBARUI SECARA SIGNIFIKAN <<
  Future<void> renameTopic(String oldName, String newName) async {
    if (newName.isEmpty) throw Exception('Nama baru tidak boleh kosong.');

    // Path untuk RSpace
    final oldRspacePath = await _pathService.getTopicPath(oldName);
    final newRspacePath = await _pathService.getTopicPath(newName);
    final oldRspaceDir = Directory(oldRspacePath);

    if (!await oldRspaceDir.exists()) {
      throw Exception('Topik yang ingin diubah tidak ditemukan.');
    }
    if (await Directory(newRspacePath).exists()) {
      throw Exception('Topik dengan nama "$newName" sudah ada di RSpace.');
    }

    // Path untuk PerpusKu
    final perpuskuDataPath = await _pathService.perpuskuDataPath;
    final perpuskuTopicsBasePath = path.join(
      perpuskuDataPath,
      'file_contents',
      'topics',
    );
    final oldPerpuskuPath = path.join(perpuskuTopicsBasePath, oldName);
    final newPerpuskuPath = path.join(perpuskuTopicsBasePath, newName);
    final oldPerpuskuDir = Directory(oldPerpuskuPath);

    try {
      // 1. Rename folder RSpace dan simpan config baru
      final oldConfig = await _getTopicConfig(oldName);
      await oldRspaceDir.rename(newRspacePath);
      final newTopic = Topic(
        name: newName,
        icon: oldConfig['icon'] as String? ?? _defaultIcon,
        position: oldConfig['position'] as int? ?? -1,
        isHidden: oldConfig['isHidden'] as bool? ?? false,
      );
      await _saveTopicConfig(newTopic);

      // 2. Rename juga folder di PerpusKu jika ada
      if (await oldPerpuskuDir.exists()) {
        if (await Directory(newPerpuskuPath).exists()) {
          debugPrint(
            'Folder tujuan di PerpusKu sudah ada, tidak jadi me-rename.',
          );
        } else {
          await oldPerpuskuDir.rename(newPerpuskuPath);
        }
      }

      // 3. PERBAIKAN: Update linkedPath di semua subject yang terpengaruh
      final newRspaceDir = Directory(newRspacePath);
      final subjectFiles = newRspaceDir.listSync().whereType<File>().where(
        (file) =>
            file.path.endsWith('.json') &&
            !path.basename(file.path).contains('config'),
      );

      for (final subjectFile in subjectFiles) {
        final jsonString = await subjectFile.readAsString();
        if (jsonString.isEmpty) continue;

        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        final metadata = jsonData['metadata'] as Map<String, dynamic>?;

        if (metadata != null && metadata.containsKey('linkedPath')) {
          final oldLinkedPath = metadata['linkedPath'] as String?;
          if (oldLinkedPath != null && oldLinkedPath.isNotEmpty) {
            final subjectFolderName = path.split(oldLinkedPath).last;
            metadata['linkedPath'] = path.join(newName, subjectFolderName);

            // Simpan kembali file JSON dengan metadata yang sudah diperbarui
            const encoder = JsonEncoder.withIndent('  ');
            await subjectFile.writeAsString(encoder.convert(jsonData));
          }
        }
      }
    } catch (e) {
      // Jika gagal, coba kembalikan nama folder RSpace
      if (!await oldRspaceDir.exists() &&
          await Directory(newRspacePath).exists()) {
        await Directory(newRspacePath).rename(oldRspacePath);
      }
      throw Exception('Gagal mengubah nama topik: $e');
    }
  }

  Future<void> deleteTopic(
    String topicName, {
    bool deletePerpuskuFolder = false,
  }) async {
    final topicPath = await _pathService.getTopicPath(topicName);
    final directory = Directory(topicPath);
    if (!await directory.exists()) {
      throw Exception('Topik yang ingin dihapus tidak ditemukan.');
    }
    try {
      if (deletePerpuskuFolder) {
        try {
          final perpuskuDataPath = await _pathService.perpuskuDataPath;
          final perpuskuTopicPath = path.join(
            perpuskuDataPath,
            'file_contents',
            'topics',
            topicName,
          );
          final perpuskuDirectory = Directory(perpuskuTopicPath);
          if (await perpuskuDirectory.exists()) {
            await perpuskuDirectory.delete(recursive: true);
          }
        } catch (e) {
          debugPrint(
            'Gagal menghapus folder pendamping di PerpusKu untuk topik "$topicName": $e',
          );
        }
      }

      await directory.delete(recursive: true);
      final remainingTopics = await getTopics();
      await saveTopicsOrder(remainingTopics);
    } catch (e) {
      throw Exception('Gagal menghapus topik: $e');
    }
  }
}
