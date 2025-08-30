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

  Future<void> addDiscussion(String filePath, Discussion discussion) async {
    final discussions = await loadDiscussions(filePath);
    discussions.add(discussion);
    await saveDiscussions(filePath, discussions);
  }

  // ==> FUNGSI BARU UNTUK MENAMBAHKAN BEBERAPA DISKUSI <==
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
