// lib/data/services/subject_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../models/discussion_model.dart';
import '../models/subject_model.dart';
import 'discussion_service.dart';
import 'path_service.dart';
import 'shared_preferences_service.dart';
import '../../presentation/pages/3_discussions_page/utils/repetition_code_utils.dart';

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

    List<Subject> subjects = [];
    for (var file in files) {
      final name = path.basenameWithoutExtension(file.path);
      final metadata = await _getSubjectMetadata(file);

      // Logika baru untuk menghitung statistik diskusi
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
      );

      subjects.add(
        Subject(
          name: name,
          icon: metadata['icon'] as String? ?? _defaultIcon,
          position: metadata['position'] as int? ?? -1,
          date: relevantDiscussionInfo['date'],
          repetitionCode: relevantDiscussionInfo['code'],
          isHidden: metadata['isHidden'] as bool? ?? false,
          // Mengisi data statistik ke model
          discussionCount: discussionCount,
          finishedDiscussionCount: finishedDiscussionCount,
          repetitionCodeCounts: repetitionCodeCounts,
        ),
      );
    }

    subjects.sort((a, b) {
      final codeA = a.repetitionCode;
      final codeB = b.repetitionCode;

      if (codeA == null && codeB == null) return 0;
      if (codeA == null) return 1;
      if (codeB == null) return -1;

      final indexA = getRepetitionCodeIndex(codeA);
      final indexB = getRepetitionCodeIndex(codeB);
      return indexA.compareTo(indexB);
    });

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
  ) async {
    try {
      List<Discussion> discussions = await _discussionService.loadDiscussions(
        subjectJsonPath,
      );

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

      // ## LOGIKA BARU DIMULAI DI SINI ##
      // Cek apakah ada diskusi dengan kode 'R0D' di antara yang sudah difilter
      final bool hasR0D = filteredDiscussions.any(
        (d) => d.effectiveRepetitionCode == 'R0D',
      );

      // Jika ada 'R0D', filter lebih lanjut untuk hanya menyertakan diskusi
      // yang TIDAK 'Finish', kecuali jika SEMUA diskusi adalah 'Finish'.
      if (hasR0D) {
        final activeDiscussions = filteredDiscussions
            .where((d) => !d.finished)
            .toList();
        if (activeDiscussions.isNotEmpty) {
          filteredDiscussions = activeDiscussions;
        }
      }
      // ## LOGIKA BARU SELESAI ##

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
        'isHidden': metadata['isHidden'] as bool? ?? false,
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
      jsonData = {};
    }

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
      final initialContent = {
        'metadata': {'icon': _defaultIcon, 'position': -1, 'isHidden': false},
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
      await getSubjects(topicPath);
    } catch (e) {
      throw Exception('Gagal menghapus subject: $e');
    }
  }
}
