// lib/data/services/discussion_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/discussion_model.dart';
import 'path_service.dart';

class DiscussionService {
  // ... (fungsi moveDiscussionFile, loadDiscussions, addDiscussion, dll. tetap sama) ...

  Future<String?> moveDiscussionFile({
    required String perpuskuBasePath,
    required String sourceDiscussionFilePath,
    required String targetSubjectLinkedPath,
  }) async {
    try {
      final sourceFile = File(
        path.join(perpuskuBasePath, sourceDiscussionFilePath),
      );
      if (!await sourceFile.exists()) {
        return null;
      }
      final fileName = path.basename(sourceFile.path);
      final targetDirectoryPath = path.join(
        perpuskuBasePath,
        targetSubjectLinkedPath,
      );
      final targetDirectory = Directory(targetDirectoryPath);
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }
      final newFilePath = path.join(targetDirectoryPath, fileName);
      await sourceFile.rename(newFilePath);
      return path.join(targetSubjectLinkedPath, fileName);
    } catch (e) {
      throw Exception('Gagal memindahkan file fisik: $e');
    }
  }

  Future<List<Discussion>> loadDiscussions(String jsonFilePath) async {
    final file = File(jsonFilePath);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode({'metadata': {}, 'content': []}));
      return [];
    }
    final jsonString = await file.readAsString();
    if (jsonString.isEmpty) {
      return [];
    }
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final contentList = jsonData['content'] as List<dynamic>? ?? [];
      return contentList.map((item) => Discussion.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Error decoding discussion file, attempting fallback: $e");
      return [];
    }
  }

  Future<void> saveDiscussions(
    String filePath,
    List<Discussion> discussions,
  ) async {
    final file = File(filePath);
    Map<String, dynamic> jsonData = {};
    try {
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      jsonData = {};
    }
    jsonData['metadata'] ??= {};
    jsonData['content'] = discussions.map((d) => d.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(jsonData));
  }

  Future<void> addDiscussion(String filePath, Discussion discussion) async {
    final discussions = await loadDiscussions(filePath);
    discussions.add(discussion);
    await saveDiscussions(filePath, discussions);
  }

  Future<void> addDiscussions(
    String filePath,
    List<Discussion> discussionsToAdd,
  ) async {
    final discussions = await loadDiscussions(filePath);
    discussions.addAll(discussionsToAdd);
    await saveDiscussions(filePath, discussions);
  }

  Future<void> deleteMultipleDiscussions(
    String filePath,
    List<String> discussionNames,
  ) async {
    final discussions = await loadDiscussions(filePath);
    discussions.removeWhere((d) => discussionNames.contains(d.discussion));
    await saveDiscussions(filePath, discussions);
  }

  Future<void> deleteLinkedFile(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) {
      return;
    }
    try {
      final pathService = PathService();
      final perpuskuBasePath = await pathService.perpuskuDataPath;
      final fullPath = path.join(
        perpuskuBasePath,
        'file_contents',
        'topics',
        relativePath,
      );

      final fileToDelete = File(fullPath);
      if (await fileToDelete.exists()) {
        await fileToDelete.delete();
        debugPrint("Successfully deleted linked file: $fullPath");
      } else {
        debugPrint("Linked file not found for deletion: $fullPath");
      }
    } catch (e) {
      debugPrint("Error deleting linked file '$relativePath': $e");
      throw Exception('Gagal menghapus file HTML tertaut: $e');
    }
  }

  Future<String> createDiscussionFile({
    required String perpuskuBasePath,
    required String subjectLinkedPath,
    required String discussionName,
  }) async {
    String fileName = discussionName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_')
        .toLowerCase();
    fileName = '$fileName.html';

    final directoryPath = path.join(perpuskuBasePath, subjectLinkedPath);
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw Exception("Direktori tertaut tidak ditemukan: $directoryPath");
    }

    final filePath = path.join(directoryPath, fileName);
    final file = File(filePath);
    if (await file.exists()) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fileName = '${path.basenameWithoutExtension(fileName)}_$timestamp.html';
    }

    final finalFile = File(path.join(directoryPath, fileName));
    const htmlTemplate = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>

</body>
</html>
''';
    await finalFile.writeAsString(htmlTemplate);

    return path.join(subjectLinkedPath, fileName);
  }
}
