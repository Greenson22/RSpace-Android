// lib/data/services/discussion_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/discussion_model.dart';

class DiscussionService {
  Future<List<Discussion>> loadDiscussions(String jsonFilePath) async {
    final file = File(jsonFilePath);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode({'content': []}));
    }

    final jsonString = await file.readAsString();
    if (jsonString.isEmpty) {
      return [];
    }

    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    final contentList = jsonData['content'] as List<dynamic>? ?? [];

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

  // ==> FUNGSI BARU UNTUK MENAMBAHKAN SATU DISKUSI <==
  Future<void> addDiscussion(String filePath, Discussion discussion) async {
    final discussions = await loadDiscussions(filePath);
    discussions.add(discussion);
    await saveDiscussions(filePath, discussions);
  }

  // ==> FUNGSI BARU UNTUK MENGHAPUS SATU DISKUSI <==
  Future<void> deleteDiscussion(String filePath, Discussion discussion) async {
    final discussions = await loadDiscussions(filePath);
    discussions.removeWhere((d) => d.discussion == discussion.discussion);
    await saveDiscussions(filePath, discussions);
  }

  // ==> FUNGSI BARU UNTUK MEMBUAT FILE HTML <==
  Future<String> createDiscussionFile({
    required String perpuskuBasePath,
    required String subjectLinkedPath,
    required String discussionName,
  }) async {
    // Membersihkan nama diskusi agar aman untuk nama file
    String fileName = discussionName
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Hapus karakter tidak valid
        .replaceAll(' ', '_') // Ganti spasi dengan underscore
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
      // Jika file sudah ada, tambahkan timestamp untuk membuatnya unik
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fileName = '${path.basenameWithoutExtension(fileName)}_$timestamp.html';
    }

    final finalFile = File(path.join(directoryPath, fileName));
    // Template HTML dasar
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

    // Mengembalikan path relatif untuk disimpan di data discussion
    return path.join(subjectLinkedPath, fileName);
  }
}
