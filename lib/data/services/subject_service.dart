// lib/data/services/subject_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../models/subject_model.dart';
import '../models/discussion_model.dart'; // DIIMPOR
import 'path_service.dart';
import 'discussion_service.dart'; // DIIMPOR
import 'shared_preferences_service.dart'; // DIIMPOR
import '../../presentation/pages/3_discussions_page/utils/repetition_code_utils.dart'; // DIIMPOR

class SubjectService {
  final PathService _pathService = PathService();
  final DiscussionService _discussionService =
      DiscussionService(); // DITAMBAHKAN
  final SharedPreferencesService _prefsService =
      SharedPreferencesService(); // DITAMBAHKAN
  static const String _defaultIcon = '📄';

  // FUNGSI INI DIUBAH SECARA SIGNIFIKAN
  Future<List<Subject>> getSubjects(String topicPath) async {
    final directory = Directory(topicPath);
    if (!await directory.exists()) {
      throw Exception('Folder tidak ditemukan: $topicPath');
    }

    // Mengambil file-file subject
    final files = directory
        .listSync()
        .whereType<File>()
        .where(
          (item) =>
              item.path.toLowerCase().endsWith('.json') &&
              path.basename(item.path) != 'topic_config.json',
        )
        .toList();

    // Memuat preferensi filter dan sort
    final sortPrefs = await _prefsService.loadSortPreferences();
    final filterPrefs = await _prefsService.loadFilterPreference();

    List<Subject> subjects = [];
    for (var file in files) {
      final name = path.basenameWithoutExtension(file.path);
      final metadata = await _getSubjectMetadata(file);

      // Memuat dan memproses diskusi untuk mendapatkan date & code yang relevan
      final relevantDiscussionInfo = await _getRelevantDiscussionInfo(
        file.path,
        sortPrefs,
        filterPrefs,
      );

      subjects.add(
        Subject(
          name: name,
          icon: metadata['icon'] as String? ?? _defaultIcon,
          position: metadata['position'] as int? ?? -1,
          date: relevantDiscussionInfo['date'], // DITAMBAHKAN
          repetitionCode: relevantDiscussionInfo['code'], // DITAMBAHKAN
          isHidden: metadata['isHidden'] as bool? ?? false, // ==> DITAMBAHKAN
        ),
      );
    }

    // ==> PERUBAHAN: LOGIKA PENGURUTAN BARU BERDASARKAN REPETITION CODE <==
    // Urutkan daftar subjek berdasarkan indeks dari repetitionCode mereka.
    subjects.sort((a, b) {
      // Anggap subjek tanpa kode repetisi memiliki prioritas terendah.
      final codeA = a.repetitionCode;
      final codeB = b.repetitionCode;

      if (codeA == null && codeB == null) return 0;
      if (codeA == null) return 1; // Pindahkan 'a' ke akhir.
      if (codeB == null) return -1; // Pindahkan 'b' ke akhir.

      final indexA = getRepetitionCodeIndex(codeA);
      final indexB = getRepetitionCodeIndex(codeB);
      return indexA.compareTo(indexB);
    });

    // Setelah diurutkan, perbarui posisi setiap subjek sesuai urutan baru.
    bool needsResave = false;
    for (int i = 0; i < subjects.length; i++) {
      if (subjects[i].position != i) {
        subjects[i].position = i;
        needsResave = true;
      }
    }

    // Jika ada perubahan posisi, simpan urutan baru ke file.
    if (needsResave) {
      await saveSubjectsOrder(topicPath, subjects);
    }

    return subjects;
  }

  // ==> FUNGSI BARU UNTUK MEMPROSES DISKUSI <==
  Future<Map<String, String?>> _getRelevantDiscussionInfo(
    String subjectJsonPath,
    Map<String, dynamic> sortPrefs,
    Map<String, String?> filterPrefs,
  ) async {
    try {
      List<Discussion> discussions = await _discussionService.loadDiscussions(
        subjectJsonPath,
      );

      // 1. Terapkan Filter
      List<Discussion> filteredDiscussions = discussions.where((discussion) {
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

      // 2. Terapkan Sort
      final sortType = sortPrefs['sortType'] as String;
      final sortAscending = sortPrefs['sortAscending'] as bool;

      Comparator<Discussion> comparator;
      switch (sortType) {
        case 'name':
          comparator = (a, b) =>
              a.discussion.toLowerCase().compareTo(b.discussion.toLowerCase());
          break;
        case 'code':
          comparator = (a, b) => getRepetitionCodeIndex(
            a.effectiveRepetitionCode,
          ).compareTo(getRepetitionCodeIndex(b.effectiveRepetitionCode));
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

      filteredDiscussions.sort(comparator);
      if (!sortAscending) {
        filteredDiscussions = filteredDiscussions.reversed.toList();
      }

      // 3. Ambil info dari diskusi pertama
      final relevantDiscussion = filteredDiscussions.first;
      return {
        'date': relevantDiscussion.effectiveDate,
        'code': relevantDiscussion.effectiveRepetitionCode,
      };
    } catch (e) {
      return {'date': null, 'code': null};
    }
  }

  // Sisanya dari file ini tetap sama...
  // ... (saveSubjectsOrder, _getSubjectMetadata, _saveSubjectMetadata, etc.)
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
      if (!await subjectFile.exists()) {
        return {'icon': _defaultIcon, 'position': -1, 'isHidden': false};
      }
      final jsonString = await subjectFile.readAsString();
      if (jsonString.isEmpty) {
        return {'icon': _defaultIcon, 'position': -1, 'isHidden': false};
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = jsonData['metadata'] as Map<String, dynamic>? ?? {};

      return {
        'icon': metadata['icon'] as String? ?? _defaultIcon,
        'position': metadata['position'] as int?,
        'isHidden': metadata['isHidden'] as bool? ?? false, // ==> DITAMBAHKAN
      };
    } catch (e) {
      return {'icon': _defaultIcon, 'position': -1, 'isHidden': false};
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

    // ==> isHidden DITAMBAHKAN ke metadata <==
    jsonData['metadata'] = {
      'icon': subject.icon,
      'position': subject.position,
      'isHidden': subject.isHidden,
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
      // Tidak perlu menetapkan posisi secara manual lagi karena akan dihitung ulang
      final initialContent = {
        'metadata': {
          'icon': _defaultIcon,
          'position': -1,
          'isHidden': false,
        }, // Posisi awal -1
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
      isHidden: metadata['isHidden'] as bool? ?? false,
    );
    await _saveSubjectMetadata(topicPath, subject);
  }

  // ==> FUNGSI BARU <==
  Future<void> updateSubjectVisibility(
    String topicPath,
    String subjectName,
    bool isHidden,
  ) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File subject tidak ditemukan.');

    final metadata = await _getSubjectMetadata(file);
    final subject = Subject(
      name: subjectName,
      icon: metadata['icon'] as String? ?? _defaultIcon,
      position: metadata['position'] as int? ?? -1,
      isHidden: isHidden,
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

  Future<void> deleteSubject(String topicPath, String subjectName) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Subject yang ingin dihapus tidak ditemukan.');
    }

    try {
      await file.delete();
      // Panggil getSubjects untuk memicu pengurutan ulang dan penyimpanan posisi baru
      await getSubjects(topicPath);
    } catch (e) {
      throw Exception('Gagal menghapus subject: $e');
    }
  }
}
