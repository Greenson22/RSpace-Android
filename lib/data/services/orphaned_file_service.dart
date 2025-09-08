// lib/data/services/orphaned_file_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../features/content_management/domain/models/discussion_model.dart';
import '../models/orphaned_file_model.dart';
import 'path_service.dart';

class OrphanedFileService {
  final PathService _pathService = PathService();

  Future<List<OrphanedFile>> findOrphanedFiles() async {
    try {
      // Langkah 1: Kumpulkan semua file path yang sudah tertaut di RSpace
      final Set<String> linkedFilePaths = await _getAllLinkedFilePaths();

      // Langkah 2: Pindai semua file HTML fisik di PerpusKu
      final List<OrphanedFile> allHtmlFiles = await _getAllPerpuskuHtmlFiles();

      // Langkah 3: Bandingkan untuk menemukan file yatim
      final List<OrphanedFile> orphanedFiles = allHtmlFiles
          .where((file) => !linkedFilePaths.contains(file.relativePath))
          .toList();

      return orphanedFiles;
    } catch (e) {
      debugPrint("Error finding orphaned files: $e");
      rethrow; // Lemparkan error agar bisa ditangani di UI
    }
  }

  Future<Set<String>> _getAllLinkedFilePaths() async {
    final Set<String> linkedPaths = {};
    final topicsPath = await _pathService.topicsPath;
    final topicsDir = Directory(topicsPath);

    if (!await topicsDir.exists()) return linkedPaths;

    final topicEntities = topicsDir.listSync();
    for (var topicEntity in topicEntities) {
      if (topicEntity is Directory) {
        final subjectFiles = topicEntity.listSync().whereType<File>().where(
          (file) =>
              file.path.endsWith('.json') &&
              !path.basename(file.path).contains('config'),
        );
        for (final subjectFile in subjectFiles) {
          final jsonString = await subjectFile.readAsString();
          if (jsonString.isEmpty) continue;
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          final contentList = jsonData['content'] as List<dynamic>? ?? [];
          for (var item in contentList) {
            final discussion = Discussion.fromJson(item);
            if (discussion.filePath != null &&
                discussion.filePath!.isNotEmpty) {
              linkedPaths.add(discussion.filePath!);
            }
          }
        }
      }
    }
    return linkedPaths;
  }

  Future<List<OrphanedFile>> _getAllPerpuskuHtmlFiles() async {
    final List<OrphanedFile> allFilesData = [];
    final perpuskuPath = await _pathService.perpuskuDataPath;
    final basePath = path.join(perpuskuPath, 'file_contents', 'topics');
    final topicsDir = Directory(basePath);

    if (!await topicsDir.exists()) return [];

    final topicDirs = topicsDir.listSync().whereType<Directory>();

    for (final topicDir in topicDirs) {
      final subjectDirs = topicDir.listSync().whereType<Directory>();
      for (final subjectDir in subjectDirs) {
        // Baca metadata.json untuk mendapatkan judul yang lebih deskriptif
        final metadataFile = File(path.join(subjectDir.path, 'metadata.json'));
        Map<String, String> currentTitles = {};
        if (await metadataFile.exists()) {
          final jsonString = await metadataFile.readAsString();
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          final content = jsonData['content'] as List<dynamic>? ?? [];
          currentTitles = {
            for (var item in content)
              item['nama_file'] as String: item['judul'] as String,
          };
        }

        final htmlFiles = subjectDir.listSync().whereType<File>().where(
          (f) =>
              f.path.toLowerCase().endsWith('.html') &&
              path.basename(f.path).toLowerCase() != 'index.html',
        );

        for (final file in htmlFiles) {
          final fileName = path.basename(file.path);
          final relativePath = path.join(
            path.basename(topicDir.path),
            path.basename(subjectDir.path),
            fileName,
          );
          allFilesData.add(
            OrphanedFile(
              title: currentTitles[fileName] ?? fileName,
              relativePath: relativePath,
              fileObject: file,
            ),
          );
        }
      }
    }
    return allFilesData;
  }
}
