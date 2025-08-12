// lib/data/services/subject_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../models/subject_model.dart';
import 'path_service.dart';

class SubjectService {
  final PathService _pathService = PathService();
  static const String _defaultIcon = '📄';

  // FUNGSI DIUBAH TOTAL UNTUK MEMBACA, MENGURUTKAN, DAN MEMPERBAIKI POSISI
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

    List<Subject> subjects = [];
    for (var file in files) {
      final name = path.basenameWithoutExtension(file.path);
      final metadata = await _getSubjectMetadata(file);
      subjects.add(
        Subject(
          name: name,
          icon: metadata['icon'] as String? ?? _defaultIcon,
          position: metadata['position'] as int? ?? -1,
        ),
      );
    }

    final positionedSubjects = subjects.where((s) => s.position != -1).toList();
    final unpositionedSubjects = subjects
        .where((s) => s.position == -1)
        .toList();

    positionedSubjects.sort((a, b) => a.position.compareTo(b.position));

    int maxPosition = positionedSubjects.isNotEmpty
        ? positionedSubjects
              .map((s) => s.position)
              .reduce((a, b) => a > b ? a : b)
        : -1;

    for (final subject in unpositionedSubjects) {
      maxPosition++;
      subject.position = maxPosition;
      await _saveSubjectMetadata(topicPath, subject);
    }

    final allSubjects = [...positionedSubjects, ...unpositionedSubjects];
    allSubjects.sort((a, b) => a.position.compareTo(b.position));

    bool needsResave = false;
    for (int i = 0; i < allSubjects.length; i++) {
      if (allSubjects[i].position != i) {
        allSubjects[i].position = i;
        needsResave = true;
      }
    }

    if (needsResave) {
      await saveSubjectsOrder(topicPath, allSubjects);
    }

    return allSubjects;
  }

  // FUNGSI BARU UNTUK MENYIMPAN URUTAN SEMUA SUBJECT
  Future<void> saveSubjectsOrder(
    String topicPath,
    List<Subject> subjects,
  ) async {
    for (int i = 0; i < subjects.length; i++) {
      final subject = subjects[i];
      subject.position = i;
      await _saveSubjectMetadata(topicPath, subject);
    }
  }

  Future<Map<String, dynamic>> _getSubjectMetadata(File subjectFile) async {
    try {
      if (!await subjectFile.exists())
        return {'icon': _defaultIcon, 'position': -1};
      final jsonString = await subjectFile.readAsString();
      if (jsonString.isEmpty) return {'icon': _defaultIcon, 'position': -1};

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = jsonData['metadata'] as Map<String, dynamic>? ?? {};

      return {
        'icon': metadata['icon'] as String? ?? _defaultIcon,
        'position': metadata['position'] as int?,
      };
    } catch (e) {
      return {'icon': _defaultIcon, 'position': -1};
    }
  }

  Future<void> _saveSubjectMetadata(String topicPath, Subject subject) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subject.name);
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
      // Jika file corrupt, buat ulang dengan data baru
      jsonData = {};
    }

    jsonData['metadata'] = {'icon': subject.icon, 'position': subject.position};
    jsonData['content'] ??= [];

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(jsonData));
  }

  Future<void> addSubject(String topicPath, String subjectName) async {
    if (subjectName.isEmpty)
      throw Exception('Nama subject tidak boleh kosong.');
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (await file.exists())
      throw Exception('Subject dengan nama "$subjectName" sudah ada.');

    try {
      final currentSubjects = await getSubjects(topicPath);
      final newPosition = currentSubjects.length;
      final initialContent = {
        'metadata': {'icon': _defaultIcon, 'position': newPosition},
        'content': [],
      };
      await file.writeAsString(jsonEncode(initialContent));
    } catch (e) {
      throw Exception('Gagal membuat subject: $e');
    }
  }

  Future<void> updateSubjectIcon(
    String topicPath,
    String subjectName,
    String newIcon,
  ) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File subject tidak ditemukan.');

    final metadata = await _getSubjectMetadata(file);
    final subject = Subject(
      name: subjectName,
      icon: newIcon,
      position: metadata['position'] as int? ?? -1,
    );
    await _saveSubjectMetadata(topicPath, subject);
  }

  Future<void> renameSubject(
    String topicPath,
    String oldName,
    String newName,
  ) async {
    if (newName.isEmpty) throw Exception('Nama baru tidak boleh kosong.');
    final oldPath = await _pathService.getSubjectPath(topicPath, oldName);
    final newPath = await _pathService.getSubjectPath(topicPath, newName);
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
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (!await file.exists())
      throw Exception('Subject yang ingin dihapus tidak ditemukan.');

    try {
      await file.delete();
      final remainingSubjects = await getSubjects(topicPath);
      await saveSubjectsOrder(topicPath, remainingSubjects);
    } catch (e) {
      throw Exception('Gagal menghapus subject: $e');
    }
  }
}
