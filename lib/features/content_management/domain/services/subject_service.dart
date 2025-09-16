// lib/data/services/subject_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:path/path.dart' as path;
import '../models/discussion_model.dart';
import '../models/subject_model.dart';
import 'discussion_service.dart';
import '../../../../core/services/path_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';
import 'package:open_file/open_file.dart';

class SubjectService {
  final PathService _pathService = PathService();
  final DiscussionService _discussionService = DiscussionService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  static const String _defaultIcon = '📄';

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

    final sortPrefs = await _prefsService.loadSortPreferences();
    final filterPrefs = await _prefsService.loadFilterPreference();
    // ==> 1. MUAT URUTAN BOBOT KUSTOM DARI PENYIMPANAN <==
    final customCodeSortOrder = await _prefsService.loadRepetitionCodeOrder();

    List<Subject> subjects = [];
    for (var file in files) {
      final name = path.basenameWithoutExtension(file.path);
      // >> PERBAIKAN: Panggil metode publik
      final metadata = await getSubjectMetadata(file);

      final discussions = await _discussionService.loadDiscussions(file.path);
      final int discussionCount = discussions.length;
      final int finishedDiscussionCount = discussions
          .where((d) => d.finished)
          .length;
      final Map<String, int> repetitionCodeCounts = {};
      for (final discussion in discussions) {
        final code = discussion.effectiveRepetitionCode;
        repetitionCodeCounts[code] = (repetitionCodeCounts[code] ?? 0) + 1;
      }

      final relevantDiscussionInfo = await _getRelevantDiscussionInfo(
        file.path,
        sortPrefs,
        filterPrefs,
        customCodeSortOrder, // ==> KIRIM URUTAN KUSTOM KE FUNGSI HELPER
      );

      subjects.add(
        Subject(
          name: name,
          icon: metadata['icon'] as String? ?? _defaultIcon,
          position: metadata['position'] as int? ?? -1,
          date: relevantDiscussionInfo['date'],
          repetitionCode: relevantDiscussionInfo['code'],
          isHidden: metadata['isHidden'] as bool? ?? false,
          linkedPath: metadata['linkedPath'] as String?,
          discussionCount: discussionCount,
          finishedDiscussionCount: finishedDiscussionCount,
          repetitionCodeCounts: repetitionCodeCounts,
        ),
      );
    }

    // ==> 2. TERAPKAN PENGURUTAN UTAMA DI SINI <==
    subjects.sort((a, b) {
      final codeA = a.repetitionCode;
      final codeB = b.repetitionCode;

      // Logika untuk menangani nilai null (subjek tanpa diskusi aktif/jatuh tempo)
      // Subjek tanpa kode akan selalu berada di akhir.
      if (codeA == null && codeB == null) return 0;
      if (codeA == null) return 1;
      if (codeB == null) return -1;

      // Gunakan urutan kustom untuk perbandingan
      final indexA = getRepetitionCodeIndex(
        codeA,
        customOrder: customCodeSortOrder,
      );
      final indexB = getRepetitionCodeIndex(
        codeB,
        customOrder: customCodeSortOrder,
      );

      return indexA.compareTo(indexB);
    });
    // ==> AKHIR BLOK PENGURUTAN <==

    bool needsResave = false;
    for (int i = 0; i < subjects.length; i++) {
      if (subjects[i].position != i) {
        subjects[i].position = i;
        needsResave = true;
      }
    }

    if (needsResave) {
      await saveSubjectsOrder(topicPath, subjects);
    }

    return subjects;
  }

  Future<Map<String, String?>> _getRelevantDiscussionInfo(
    String subjectJsonPath,
    Map<String, dynamic> sortPrefs,
    Map<String, String?> filterPrefs,
    List<String> customCodeSortOrder, // ==> TERIMA URUTAN KUSTOM
  ) async {
    try {
      List<Discussion> discussions = await _discussionService.loadDiscussions(
        subjectJsonPath,
      );

      if (discussions.isNotEmpty && discussions.every((d) => d.finished)) {
        return {'date': null, 'code': 'Finish'};
      }

      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      List<Discussion> dueDiscussions = discussions.where((d) {
        if (d.finished) return false;
        if (d.effectiveDate == null) return false;
        try {
          final discussionDate = DateTime.parse(d.effectiveDate!);
          return !discussionDate.isAfter(normalizedToday);
        } catch (e) {
          return false;
        }
      }).toList();

      if (dueDiscussions.isEmpty) {
        return {'date': null, 'code': null};
      }

      List<Discussion> filteredDiscussions = dueDiscussions.where((discussion) {
        final filterType = filterPrefs['filterType'];
        if (filterType == null) return true;

        if (filterType == 'code') {
          return discussion.effectiveRepetitionCode ==
              filterPrefs['filterValue'];
        } else if (filterType == 'date' && filterPrefs['filterValue'] != null) {
          try {
            if (discussion.effectiveDate == null) return false;
            final discussionDate = DateTime.parse(discussion.effectiveDate!);
            final normalizedDate = DateTime(
              discussionDate.year,
              discussionDate.month,
              discussionDate.day,
            );

            final dates = filterPrefs['filterValue']!.split('/');
            final startDate = DateTime.parse(dates[0]);
            final endDate = DateTime.parse(dates[1]);

            return !normalizedDate.isBefore(startDate) &&
                !normalizedDate.isAfter(endDate);
          } catch (e) {
            return false;
          }
        }
        return true;
      }).toList();

      if (filteredDiscussions.isEmpty) {
        return {'date': null, 'code': null};
      }

      final activeDiscussions = filteredDiscussions
          .where((d) => !d.finished)
          .toList();

      if (activeDiscussions.isNotEmpty) {
        final hasNonR0D = activeDiscussions.any(
          (d) => d.effectiveRepetitionCode != 'R0D',
        );

        if (hasNonR0D) {
          filteredDiscussions = activeDiscussions
              .where((d) => d.effectiveRepetitionCode != 'R0D')
              .toList();
        } else {
          filteredDiscussions = activeDiscussions;
        }
      }

      final sortType = sortPrefs['sortType'] as String;
      final sortAscending = sortPrefs['sortAscending'] as bool;

      Comparator<Discussion> comparator;
      switch (sortType) {
        case 'name':
          comparator = (a, b) =>
              a.discussion.toLowerCase().compareTo(b.discussion.toLowerCase());
          break;
        case 'code':
          comparator = (a, b) =>
              getRepetitionCodeIndex(
                a.effectiveRepetitionCode,
                customOrder: customCodeSortOrder, // ==> GUNAKAN URUTAN KUSTOM
              ).compareTo(
                getRepetitionCodeIndex(
                  b.effectiveRepetitionCode,
                  customOrder: customCodeSortOrder,
                ),
              );
          break;
        default: // date
          comparator = (a, b) {
            if (a.effectiveDate == null && b.effectiveDate == null) return 0;
            if (a.effectiveDate == null) return sortAscending ? 1 : -1;
            if (b.effectiveDate == null) return sortAscending ? -1 : 1;
            return DateTime.parse(
              a.effectiveDate!,
            ).compareTo(DateTime.parse(b.effectiveDate!));
          };
          break;
      }

      if (filteredDiscussions.isEmpty) {
        filteredDiscussions = dueDiscussions;
        if (filteredDiscussions.isEmpty) {
          return {'date': null, 'code': null};
        }
      }

      filteredDiscussions.sort(comparator);
      if (!sortAscending) {
        filteredDiscussions = filteredDiscussions.reversed.toList();
      }

      final relevantDiscussion = filteredDiscussions.first;
      return {
        'date': relevantDiscussion.effectiveDate,
        'code': relevantDiscussion.effectiveRepetitionCode,
      };
    } catch (e) {
      return {'date': null, 'code': null};
    }
  }

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

  // >> PERUBAHAN DI SINI: Metode ini sekarang publik (tanpa garis bawah)
  Future<Map<String, dynamic>> getSubjectMetadata(File subjectFile) async {
    try {
      if (!await subjectFile.exists()) {
        return {
          'icon': _defaultIcon,
          'position': -1,
          'isHidden': false,
          'linkedPath': null,
        };
      }
      final jsonString = await subjectFile.readAsString();
      if (jsonString.isEmpty) {
        return {
          'icon': _defaultIcon,
          'position': -1,
          'isHidden': false,
          'linkedPath': null,
        };
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = jsonData['metadata'] as Map<String, dynamic>? ?? {};

      return {
        'icon': metadata['icon'] as String? ?? _defaultIcon,
        'position': metadata['position'] as int?,
        'isHidden': metadata['isHidden'] as bool? ?? false,
        'linkedPath': metadata['linkedPath'] as String?,
      };
    } catch (e) {
      return {
        'icon': _defaultIcon,
        'position': -1,
        'isHidden': false,
        'linkedPath': null,
      };
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
      jsonData = {};
    }

    jsonData['metadata'] = {
      'icon': subject.icon,
      'position': subject.position,
      'isHidden': subject.isHidden,
      'linkedPath': subject.linkedPath,
    };
    jsonData['content'] ??= [];

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(jsonData));
  }

  Future<void> addSubject(String topicPath, String subjectName) async {
    if (subjectName.isEmpty) {
      throw Exception('Nama subject tidak boleh kosong.');
    }
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (await file.exists()) {
      throw Exception('Subject dengan nama "$subjectName" sudah ada.');
    }

    try {
      final initialContent = {
        'metadata': {
          'icon': _defaultIcon,
          'position': -1,
          'isHidden': false,
          'linkedPath': null,
        },
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

    // >> PERBAIKAN: Panggil metode publik
    final metadata = await getSubjectMetadata(file);
    final subject = Subject(
      name: subjectName,
      icon: newIcon,
      position: metadata['position'] as int? ?? -1,
      isHidden: metadata['isHidden'] as bool? ?? false,
      linkedPath: metadata['linkedPath'] as String?,
    );
    await _saveSubjectMetadata(topicPath, subject);
  }

  Future<void> updateSubjectLinkedPath(
    String topicPath,
    String subjectName,
    String? newPath,
  ) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File subject tidak ditemukan.');

    // >> PERBAIKAN: Panggil metode publik
    final metadata = await getSubjectMetadata(file);
    final subject = Subject(
      name: subjectName,
      icon: metadata['icon'] as String? ?? _defaultIcon,
      position: metadata['position'] as int? ?? -1,
      isHidden: metadata['isHidden'] as bool? ?? false,
      linkedPath: newPath,
    );
    await _saveSubjectMetadata(topicPath, subject);
  }

  Future<void> updateSubjectVisibility(
    String topicPath,
    String subjectName,
    bool isHidden,
  ) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File subject tidak ditemukan.');

    // >> PERBAIKAN: Panggil metode publik
    final metadata = await getSubjectMetadata(file);
    final subject = Subject(
      name: subjectName,
      icon: metadata['icon'] as String? ?? _defaultIcon,
      position: metadata['position'] as int? ?? -1,
      isHidden: isHidden,
      linkedPath: metadata['linkedPath'] as String?,
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

  Future<void> deleteSubject(
    String topicPath,
    String subjectName, {
    bool deleteLinkedFolder = false,
  }) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Subject yang ingin dihapus tidak ditemukan.');
    }

    // Ambil metadata SEBELUM menghapus file json
    final metadata = await getSubjectMetadata(file);
    final linkedPath = metadata['linkedPath'] as String?;

    try {
      // Hapus file json subject
      await file.delete();

      // Jika user memilih untuk menghapus folder tertaut
      if (deleteLinkedFolder && linkedPath != null && linkedPath.isNotEmpty) {
        final perpuskuBasePath = await _pathService.perpuskuDataPath;
        final perpuskuTopicsPath = path.join(
          perpuskuBasePath,
          'file_contents',
          'topics',
        );
        final folderToDelete = Directory(
          path.join(perpuskuTopicsPath, linkedPath),
        );
        if (await folderToDelete.exists()) {
          await folderToDelete.delete(recursive: true);
        }
      }

      // Perbarui urutan subject yang tersisa
      final remainingSubjects = await getSubjects(topicPath);
      await saveSubjectsOrder(topicPath, remainingSubjects);
    } catch (e) {
      throw Exception('Gagal menghapus subject: $e');
    }
  }

  // ==> FUNGSI BARU UNTUK MEMINDAHKAN SUBJECT <==
  Future<void> moveSubject(
    Subject subject,
    String oldTopicPath,
    Topic newTopic,
  ) async {
    final oldJsonPath = await _pathService.getSubjectPath(
      oldTopicPath,
      subject.name,
    );
    final newJsonPath = await _pathService.getSubjectPath(
      await _pathService.getTopicPath(newTopic.name),
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
          // Jika folder tujuan sudah ada, hapus yang lama dan jangan pindahkan
          await oldLinkedDir.delete(recursive: true);
        } else {
          // Pindahkan folder
          await oldLinkedDir.rename(newLinkedDir.path);
          // Update linkedPath di file JSON yang baru
          final newJsonFile = File(newJsonPath);
          final metadata = await getSubjectMetadata(newJsonFile);
          subject.linkedPath = newLinkedPath; // Update path
          await _saveSubjectMetadata(
            await _pathService.getTopicPath(newTopic.name),
            subject,
          );
        }
      }
    }
  }

  Future<void> openSubjectIndexFile(String subjectLinkedPath) async {
    try {
      final pathService = PathService();
      final perpuskuBasePath = await pathService.perpuskuDataPath;
      final subjectDirectoryPath = path.join(
        perpuskuBasePath,
        'file_contents',
        'topics',
        subjectLinkedPath,
      );
      final indexFilePath = path.join(subjectDirectoryPath, 'index.html');
      final indexFile = File(indexFilePath);

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
        final editor =
            Platform.environment['EDITOR'] ?? Platform.environment['VISUAL'];
        ProcessResult result;
        if (editor != null && editor.isNotEmpty) {
          result = await Process.run(editor, [
            indexFile.path,
          ], runInShell: true);
          if (result.exitCode == 0) return;
        }
        const commonEditors = ['gedit', 'kate', 'mousepad', 'code'];
        for (final ed in commonEditors) {
          result = await Process.run('which', [ed]);
          if (result.exitCode == 0) {
            result = await Process.run(ed, [indexFile.path], runInShell: true);
            if (result.exitCode == 0) return;
          }
        }
        result = await Process.run('xdg-open', [indexFile.path]);
        if (result.exitCode != 0) {
          throw Exception(
            'Gagal membuka file dengan semua metode: ${result.stderr}',
          );
        }
      } else {
        final result = await OpenFile.open(indexFile.path);
        if (result.type != ResultType.done) {
          throw Exception('Gagal membuka file untuk diedit: ${result.message}');
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
