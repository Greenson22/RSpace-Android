// lib/data/services/subject_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'path_service.dart';

class SubjectService {
  final PathService _pathService = PathService();

  Future<List<String>> getSubjects(String topicPath) async {
    final directory = Directory(topicPath);
    if (!await directory.exists())
      throw Exception('Folder tidak ditemukan: $topicPath');

    final fileNames = directory
        .listSync()
        .whereType<File>()
        .where(
          (item) =>
              item.path.toLowerCase().endsWith('.json') &&
              path.basename(item.path) != 'topic_config.json',
        )
        .map((item) => path.basenameWithoutExtension(item.path))
        .toList();
    fileNames.sort();
    return fileNames;
  }

  Future<void> addSubject(String topicPath, String subjectName) async {
    if (subjectName.isEmpty)
      throw Exception('Nama subject tidak boleh kosong.');

    final filePath = _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);

    if (await file.exists())
      throw Exception('Subject dengan nama "$subjectName" sudah ada.');

    try {
      await file.writeAsString(jsonEncode({'content': []}));
    } catch (e) {
      throw Exception('Gagal membuat subject: $e');
    }
  }

  Future<void> renameSubject(
    String topicPath,
    String oldName,
    String newName,
  ) async {
    if (newName.isEmpty) throw Exception('Nama baru tidak boleh kosong.');

    final oldPath = _pathService.getSubjectPath(topicPath, oldName);
    final newPath = _pathService.getSubjectPath(topicPath, newName);
    final oldFile = File(oldPath);

    if (!await oldFile.exists())
      throw Exception('Subject yang ingin diubah tidak ditemukan.');
    if (await File(newPath).exists())
      throw Exception('Subject dengan nama "$newName" sudah ada.');

    try {
      await oldFile.rename(newPath);
    } catch (e) {
      throw Exception('Gagal mengubah nama subject: $e');
    }
  }

  Future<void> deleteSubject(String topicPath, String subjectName) async {
    final filePath = _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (!await file.exists())
      throw Exception('Subject yang ingin dihapus tidak ditemukan.');

    try {
      await file.delete();
    } catch (e) {
      throw Exception('Gagal menghapus subject: $e');
    }
  }
}
