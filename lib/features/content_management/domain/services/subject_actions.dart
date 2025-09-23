// lib/features/content_management/domain/services/subject_actions.dart

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import 'subject_repository.dart';

class SubjectActions {
  final PathService _pathService = PathService();
  final SubjectRepository _repository = SubjectRepository();

  // ==> FUNGSI HELPER BARU UNTUK MENDAPATKAN FILE INDEX
  Future<File> _getIndexFile(String subjectLinkedPath) async {
    final perpuskuBasePath = await _pathService.perpuskuDataPath;
    final subjectDirectoryPath = path.join(
      perpuskuBasePath,
      'file_contents',
      'topics',
      subjectLinkedPath,
    );
    return File(path.join(subjectDirectoryPath, 'index.html'));
  }

  // ==> FUNGSI BARU UNTUK MEMBACA KONTEN
  Future<String> readSubjectIndexFile(String subjectLinkedPath) async {
    final indexFile = await _getIndexFile(subjectLinkedPath);
    if (!await indexFile.exists()) {
      return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Index</title>
</head>
<body>
    <div id="main-container"></div>
</body>
</html>''';
    }
    return await indexFile.readAsString();
  }

  // ==> FUNGSI BARU UNTUK MENYIMPAN KONTEN
  Future<void> saveSubjectIndexFileContent(
    String subjectLinkedPath,
    String htmlContent,
  ) async {
    final indexFile = await _getIndexFile(subjectLinkedPath);
    await indexFile.writeAsString(htmlContent, flush: true);
  }

  Future<void> generateAndSaveSubjectIndexFile(
    String subjectLinkedPath,
    String htmlContent,
  ) async {
    // Fungsi ini sekarang memanggil helper save yang baru
    await saveSubjectIndexFileContent(subjectLinkedPath, htmlContent);
  }

  // Fungsi ini tetap sama untuk membuka dengan editor eksternal
  Future<void> openSubjectIndexFile(String subjectLinkedPath) async {
    final indexFile = await _getIndexFile(subjectLinkedPath);

    if (!await indexFile.exists()) {
      await indexFile.create(recursive: true);
      await indexFile.writeAsString('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Index</title>
</head>
<body>
    <div id="main-container"></div>
</body>
</html>''');
    }

    if (Platform.isLinux) {
      const editors = ['gedit', 'kate', 'mousepad', 'code', 'xdg-open'];
      for (final ed in editors) {
        final check = await Process.run('which', [ed]);
        if (check.exitCode == 0) {
          await Process.run(ed, [indexFile.path], runInShell: true);
          return;
        }
      }
      throw Exception('Tidak ditemukan editor teks yang kompatibel.');
    } else {
      final result = await OpenFile.open(indexFile.path);
      if (result.type != ResultType.done) {
        throw Exception('Gagal membuka file untuk diedit: ${result.message}');
      }
    }
  }

  // ... (sisa kode seperti moveSubject tidak berubah)
  Future<void> moveSubject(
    Subject subject,
    String oldTopicPath,
    Topic newTopic,
  ) async {
    final oldJsonPath = await _pathService.getSubjectPath(
      oldTopicPath,
      subject.name,
    );
    final newTopicPath = await _pathService.getTopicPath(newTopic.name);
    final newJsonPath = await _pathService.getSubjectPath(
      newTopicPath,
      subject.name,
    );

    final oldJsonFile = File(oldJsonPath);
    if (!await oldJsonFile.exists()) {
      throw Exception('File JSON subject sumber tidak ditemukan.');
    }
    if (await File(newJsonPath).exists()) {
      throw Exception(
        'Subject dengan nama "${subject.name}" sudah ada di topik tujuan.',
      );
    }

    // Pindahkan file JSON
    await oldJsonFile.rename(newJsonPath);

    // Pindahkan folder PerpusKu jika ada
    if (subject.linkedPath != null && subject.linkedPath!.isNotEmpty) {
      final perpuskuBasePath = await _pathService.perpuskuDataPath;
      final perpuskuTopicsPath = path.join(
        perpuskuBasePath,
        'file_contents',
        'topics',
      );

      final oldLinkedDir = Directory(
        path.join(perpuskuTopicsPath, subject.linkedPath!),
      );
      if (await oldLinkedDir.exists()) {
        final newLinkedPath = path.join(newTopic.name, subject.name);
        final newLinkedDir = Directory(
          path.join(perpuskuTopicsPath, newLinkedPath),
        );

        if (await newLinkedDir.exists()) {
          await oldLinkedDir.delete(recursive: true);
        } else {
          await oldLinkedDir.rename(newLinkedDir.path);

          // Update linkedPath di file JSON yang baru dipindah
          final newJsonFile = File(newJsonPath);
          final jsonData = await _repository.readSubjectJson(newJsonFile);
          jsonData['metadata']['linkedPath'] = newLinkedPath;
          await _repository.writeSubjectJson(newJsonPath, jsonData);
        }
      }
    }
  }
}
