// lib/features/content_management/domain/services/subject_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../../core/services/path_service.dart';

class SubjectRepository {
  final PathService _pathService = PathService();
  static const String _defaultIcon = '📄';

  // ==> FUNGSI BARU DITAMBAHKAN <==
  /// Membaca konten mentah dari file JSON sebagai string.
  Future<String> readSubjectRawJson(File subjectFile) async {
    try {
      if (await subjectFile.exists()) {
        return await subjectFile.readAsString();
      }
      return '{}'; // Kembalikan objek JSON kosong jika file tidak ada
    } catch (e) {
      return '{"error": "Gagal membaca file: $e"}';
    }
  }

  /// Membaca semua file subject .json dari sebuah direktori topik.
  Future<List<File>> getSubjectFiles(String topicPath) async {
    final directory = Directory(topicPath);
    if (!await directory.exists()) {
      throw Exception('Folder tidak ditemukan: $topicPath');
    }

    return directory
        .listSync()
        .whereType<File>()
        .where(
          (item) =>
              item.path.toLowerCase().endsWith('.json') &&
              path.basename(item.path) != 'topic_config.json',
        )
        .toList();
  }

  /// Membaca konten JSON dari satu file subject.
  Future<Map<String, dynamic>> readSubjectJson(File subjectFile) async {
    try {
      if (!await subjectFile.exists()) return _defaultJsonContent();

      final jsonString = await subjectFile.readAsString();
      if (jsonString.isEmpty) return _defaultJsonContent();

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return _defaultJsonContent();
    }
  }

  /// Menulis data ke file subject .json.
  Future<void> writeSubjectJson(
    String filePath,
    Map<String, dynamic> data,
  ) async {
    final file = File(filePath);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));
  }

  /// Membuat file subject baru dengan konten awal.
  Future<void> createSubjectFile(String topicPath, String subjectName) async {
    if (subjectName.isEmpty) {
      throw Exception('Nama subject tidak boleh kosong.');
    }
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (await file.exists()) {
      throw Exception('Subject dengan nama "$subjectName" sudah ada.');
    }
    await writeSubjectJson(filePath, _defaultJsonContent());
  }

  /// Menghapus file subject .json.
  Future<void> deleteSubjectFile(String topicPath, String subjectName) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Mengganti nama file subject .json.
  Future<void> renameSubjectFile(
    String topicPath,
    String oldName,
    String newName,
  ) async {
    if (newName.isEmpty) throw Exception('Nama baru tidak boleh kosong.');
    final oldPath = await _pathService.getSubjectPath(topicPath, oldName);
    final newPath = await _pathService.getSubjectPath(topicPath, newName);
    final oldFile = File(oldPath);
    if (!await oldFile.exists()) {
      throw Exception('Subject yang ingin diubah tidak ditemukan.');
    }
    if (await File(newPath).exists()) {
      throw Exception('Subject dengan nama "$newName" sudah ada.');
    }
    await oldFile.rename(newPath);
  }

  Map<String, dynamic> _defaultJsonContent() {
    return {
      'metadata': {
        'icon': _defaultIcon,
        'position': -1,
        'isHidden': false,
        'linkedPath': null,
      },
      'content': [],
    };
  }
}
