// lib/data/services/subject_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../models/subject_model.dart'; // ==> DITAMBAHKAN
import 'path_service.dart';

class SubjectService {
  final PathService _pathService = PathService();
  static const String _defaultIcon = '📄'; // ==> DITAMBAHKAN

  // ==> DIUBAH UNTUK MENGEMBALIKAN List<Subject> <==
  Future<List<Subject>> getSubjects(String topicPath) async {
    final directory = Directory(topicPath);
    if (!await directory.exists()) {
      throw Exception('Folder tidak ditemukan: $topicPath');
    }

    final files = directory
        .listSync()
        .whereType<File>()
        .where(
          (item) =>
              item.path.toLowerCase().endsWith('.json') &&
              path.basename(item.path) != 'topic_config.json',
        )
        .toList();

    files.sort(
      (a, b) => path.basename(a.path).compareTo(path.basename(b.path)),
    );

    final List<Subject> subjects = [];
    for (var file in files) {
      final name = path.basenameWithoutExtension(file.path);
      final icon = await _getIconForSubject(file);
      subjects.add(Subject(name: name, icon: icon));
    }
    return subjects;
  }

  // ==> FUNGSI BARU UNTUK MEMBACA IKON DARI JSON <==
  Future<String> _getIconForSubject(File subjectFile) async {
    try {
      if (!await subjectFile.exists()) {
        return _defaultIcon;
      }
      final jsonString = await subjectFile.readAsString();
      if (jsonString.isEmpty) {
        return _defaultIcon;
      }
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = jsonData['metadata'] as Map<String, dynamic>?;
      return metadata?['icon'] as String? ?? _defaultIcon;
    } catch (e) {
      return _defaultIcon;
    }
  }

  // ==> DIUBAH: MENAMBAHKAN METADATA SAAT FILE DIBUAT <==
  Future<void> addSubject(String topicPath, String subjectName) async {
    if (subjectName.isEmpty) {
      throw Exception('Nama subject tidak boleh kosong.');
    }

    final filePath = _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);

    if (await file.exists()) {
      throw Exception('Subject dengan nama "$subjectName" sudah ada.');
    }

    try {
      // Struktur JSON awal dengan metadata dan ikon default
      final initialContent = {
        'metadata': {'icon': _defaultIcon},
        'content': [],
      };
      await file.writeAsString(jsonEncode(initialContent));
    } catch (e) {
      throw Exception('Gagal membuat subject: $e');
    }
  }

  // ==> FUNGSI BARU UNTUK UPDATE IKON <==
  Future<void> updateSubjectIcon(
    String topicPath,
    String subjectName,
    String newIcon,
  ) async {
    final filePath = _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('File subject tidak ditemukan.');
    }

    try {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Buat atau update metadata
      final metadata = (jsonData['metadata'] as Map<String, dynamic>?) ?? {};
      metadata['icon'] = newIcon;
      jsonData['metadata'] = metadata;

      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(jsonData));
    } catch (e) {
      throw Exception('Gagal memperbarui ikon subject: $e');
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

    if (!await oldFile.exists()) {
      throw Exception('Subject yang ingin diubah tidak ditemukan.');
    }
    if (await File(newPath).exists()) {
      throw Exception('Subject dengan nama "$newName" sudah ada.');
    }

    try {
      await oldFile.rename(newPath);
    } catch (e) {
      throw Exception('Gagal mengubah nama subject: $e');
    }
  }

  Future<void> deleteSubject(String topicPath, String subjectName) async {
    final filePath = _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Subject yang ingin dihapus tidak ditemukan.');
    }

    try {
      await file.delete();
    } catch (e) {
      throw Exception('Gagal menghapus subject: $e');
    }
  }
}
