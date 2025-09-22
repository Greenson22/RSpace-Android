// lib/features/link_maintenance/application/services/file_path_correction_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/services/topic_service.dart';
import 'package:path/path.dart' as path;

class FilePathCorrectionService {
  final PathService _pathService = PathService();
  final TopicService _topicService = TopicService();

  /// Memindai semua file subject dan memperbaiki format `filePath` di dalamnya.
  /// Mengembalikan ringkasan hasil proses.
  Future<Map<String, int>> correctAllFilePaths() async {
    int filesScanned = 0;
    int filesCorrected = 0;
    int entriesUpdated = 0;

    try {
      final topics = await _topicService.getTopics();
      final topicsPath = await _pathService.topicsPath;

      for (final topic in topics) {
        final topicDir = Directory(path.join(topicsPath, topic.name));
        if (!await topicDir.exists()) continue;

        final subjectFiles = topicDir.listSync().whereType<File>().where(
          (file) =>
              file.path.endsWith('.json') &&
              !path.basename(file.path).contains('config'),
        );

        for (final subjectFile in subjectFiles) {
          filesScanned++;
          bool fileNeedsSaving = false;
          final jsonString = await subjectFile.readAsString();
          if (jsonString.isEmpty) continue;

          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          final contentList = jsonData['content'] as List<dynamic>? ?? [];

          for (var item in contentList) {
            final discussion = item as Map<String, dynamic>;
            final filePath = discussion['filePath'] as String?;

            // Kondisi utama: perbaiki jika filePath ada dan mengandung garis miring
            if (filePath != null && filePath.contains('/')) {
              discussion['filePath'] = path.basename(filePath);
              fileNeedsSaving = true;
              entriesUpdated++;
            }
          }

          if (fileNeedsSaving) {
            filesCorrected++;
            const encoder = JsonEncoder.withIndent('  ');
            await subjectFile.writeAsString(encoder.convert(jsonData));
          }
        }
      }
    } catch (e) {
      debugPrint("Error during file path correction: $e");
      rethrow;
    }

    return {
      'filesScanned': filesScanned,
      'filesCorrected': filesCorrected,
      'entriesUpdated': entriesUpdated,
    };
  }
}
