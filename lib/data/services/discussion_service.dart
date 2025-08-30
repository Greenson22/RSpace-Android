// lib/data/services/discussion_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/discussion_model.dart';

class DiscussionService {
  // ==> FUNGSI BARU DITAMBAHKAN DI SINI <==
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
        // Jika file sumber tidak ada, tidak ada yang perlu dilakukan.
        return null;
      }

      final fileName = path.basename(sourceFile.path);
      final targetDirectoryPath = path.join(
        perpuskuBasePath,
        targetSubjectLinkedPath,
      );
      final targetDirectory = Directory(targetDirectoryPath);

      if (!await targetDirectory.exists()) {
        // Buat direktori tujuan jika belum ada (sebagai fallback).
        await targetDirectory.create(recursive: true);
      }

      final newFilePath = path.join(targetDirectoryPath, fileName);
      await sourceFile.rename(newFilePath);

      // Kembalikan path relatif yang baru untuk disimpan di model Discussion.
      return path.join(targetSubjectLinkedPath, fileName);
    } catch (e) {
      // Jika terjadi error, lemparkan kembali agar bisa ditangani oleh provider.
      throw Exception('Gagal memindahkan file fisik: $e');
    }
  }

  Future<List<Discussion>> loadDiscussions(String jsonFilePath) async {
    final file = File(jsonFilePath);
    if (!await file.exists()) {
      // Jika file tidak ada, buat dengan struktur yang benar
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
      // Jika file korup atau format lama, coba tangani
      debugPrint("Error decoding discussion file, attempting fallback: $e");
      return [];
    }
  }

  // ## FUNGSI INI TELAH DIPERBAIKI ##
  Future<void> saveDiscussions(
    String filePath,
    List<Discussion> discussions,
  ) async {
    final file = File(filePath);
    Map<String, dynamic> jsonData = {};

    // 1. Baca data yang ada untuk mempertahankan 'metadata'
    try {
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint(
        "Could not read existing discussion file, creating new structure: $e",
      );
      jsonData = {};
    }

    // 2. Pastikan blok metadata ada
    jsonData['metadata'] ??= {};

    // 3. Perbarui hanya blok 'content'
    jsonData['content'] = discussions.map((d) => d.toJson()).toList();

    // 4. Tulis kembali keseluruhan data yang sudah digabungkan
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

  Future<void> deleteDiscussion(String filePath, Discussion discussion) async {
    final discussions = await loadDiscussions(filePath);
    discussions.removeWhere((d) => d.discussion == discussion.discussion);
    await saveDiscussions(filePath, discussions);
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
