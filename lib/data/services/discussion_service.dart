// lib/data/services/discussion_service.dart
import 'dart:convert';
import 'dart:io';
import '../models/discussion_model.dart';

class DiscussionService {
  Future<List<Discussion>> loadDiscussions(String jsonFilePath) async {
    final file = File(jsonFilePath);
    if (!await file.exists()) {
      // Jika file tidak ada, buat file kosong dengan struktur dasar
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode({'content': []}));
    }

    final jsonString = await file.readAsString();
    // Tambahkan pengecekan jika jsonString kosong
    if (jsonString.isEmpty) {
      return [];
    }

    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    final contentList =
        jsonData['content'] as List<dynamic>? ?? []; // Handle null case

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
}
