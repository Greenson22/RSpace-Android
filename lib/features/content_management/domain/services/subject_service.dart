// lib/features/content_management/domain/services/subject_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/core/services/storage_service.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';
import 'package:path/path.dart' as path;

import '../models/subject_model.dart';
import 'discussion_service.dart';
import 'subject_repository.dart';
// ==> IMPORT SERVICE ENKRIPSI <==
import 'encryption_service.dart';

class SubjectService {
  final DiscussionService _discussionService = DiscussionService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final SubjectRepository _repository = SubjectRepository();
  final PathService _pathService = PathService();
  // ==> TAMBAHKAN INSTANCE ENCRYPTION SERVICE <==
  final EncryptionService _encryptionService = EncryptionService();
  static const String _defaultIcon = '📄';

  Future<List<Subject>> getSubjects(String topicPath) async {
    final files = await _repository.getSubjectFiles(topicPath);
    final sortPrefs = await _prefsService.loadSortPreferences();
    final filterPrefs = await _prefsService.loadFilterPreference();
    final customCodeSortOrder = await _prefsService.loadRepetitionCodeOrder();

    List<Subject> subjects = [];
    for (var file in files) {
      final name = path.basenameWithoutExtension(file.path);
      final jsonData = await _repository.readSubjectJson(file);
      final metadata = jsonData['metadata'] as Map<String, dynamic>? ?? {};
      final content =
          jsonData['content']; // Bisa jadi String (terenkripsi) atau List

      final bool isLocked = metadata['isLocked'] as bool? ?? false;

      // Hanya parse diskusi jika tidak terkunci dan tipenya adalah List
      final discussions = (isLocked || content is! List<dynamic>)
          ? <Discussion>[]
          : content.map((item) => Discussion.fromJson(item)).toList();

      final discussionsToCount = _getFilteredAndSortedDiscussions(
        discussions,
        filterPrefs,
        sortPrefs,
        customCodeSortOrder,
      );

      final relevantDiscussionInfo = await _getRelevantDiscussionInfo(
        discussionsToCount,
        sortPrefs,
        customCodeSortOrder,
      );

      final repetitionCodeCounts = <String, int>{};
      for (final discussion in discussionsToCount) {
        final code = discussion.effectiveRepetitionCode;
        repetitionCodeCounts[code] = (repetitionCodeCounts[code] ?? 0) + 1;
      }

      subjects.add(
        Subject(
          name: name,
          icon: metadata['icon'] as String? ?? _defaultIcon,
          position: metadata['position'] as int? ?? -1,
          date: relevantDiscussionInfo['date'],
          repetitionCode: relevantDiscussionInfo['code'],
          isHidden: metadata['isHidden'] as bool? ?? false,
          linkedPath: metadata['linkedPath'] as String?,
          isFrozen: metadata['isFrozen'] as bool? ?? false,
          frozenDate: metadata['frozenDate'] as String?,
          isLocked: isLocked,
          passwordHash: metadata['passwordHash'] as String?,
          discussionCount: discussions.length,
          finishedDiscussionCount: discussions.where((d) => d.finished).length,
          repetitionCodeCounts: repetitionCodeCounts,
          topicName: '',
        ),
      );
    }

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

  // ==> FUNGSI BARU UNTUK MENYIMPAN SUBJECT YANG DIENKRIPSI <==
  Future<void> saveEncryptedSubject(
    String topicPath,
    Subject subject,
    String password,
  ) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subject.name);

    // Ambil metadata dari objek subject
    final metadata = subject.toJson()['metadata'];

    // Ubah konten diskusi menjadi string JSON
    final discussionsJsonString = jsonEncode(
      subject.discussions.map((d) => d.toJson()).toList(),
    );

    // Enkripsi string JSON tersebut
    final encryptedContent = _encryptionService.encryptContent(
      discussionsJsonString,
      password,
    );

    // Buat data akhir untuk disimpan ke file
    final jsonData = {
      'metadata': metadata,
      'content': encryptedContent, // Simpan konten yang sudah terenkripsi
    };

    // Tulis ke file menggunakan repository
    await _repository.writeSubjectJson(filePath, jsonData);
  }

  // ==> FUNGSI BARU UNTUK MEMBACA SUBJECT YANG DIENKRIPSI <==
  Future<List<Discussion>> getDecryptedDiscussions(
    String topicPath,
    String subjectName,
    String password,
  ) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subjectName);
    final file = File(filePath);
    final jsonData = await _repository.readSubjectJson(file);

    final encryptedContent = jsonData['content'] as String?;
    if (encryptedContent == null || encryptedContent.isEmpty) {
      return [];
    }

    final decryptedJsonString = _encryptionService.decryptContent(
      encryptedContent,
      password,
    );
    final contentList = jsonDecode(decryptedJsonString) as List<dynamic>;
    return contentList.map((item) => Discussion.fromJson(item)).toList();
  }

  Future<List<Discussion>> getDiscussionsForSubject(
    String topicPath,
    String subjectName,
  ) async {
    final subjectJsonPath = await _pathService.getSubjectPath(
      topicPath,
      subjectName,
    );
    return await _discussionService.loadDiscussions(subjectJsonPath);
  }

  Future<void> saveDiscussionsForSubject(
    String topicPath,
    String subjectName,
    List<Discussion> discussions,
  ) async {
    final subjectJsonPath = await _pathService.getSubjectPath(
      topicPath,
      subjectName,
    );
    await _discussionService.saveDiscussions(subjectJsonPath, discussions);
  }

  List<Discussion> _getFilteredAndSortedDiscussions(
    List<Discussion> allDiscussions,
    Map<String, String?> filterPrefs,
    Map<String, dynamic> sortPrefs,
    List<String> customCodeSortOrder,
  ) {
    List<Discussion> filteredDiscussions = allDiscussions.where((discussion) {
      if (filterPrefs['filterType'] == null) {
        return !discussion.finished;
      }

      if (discussion.finished) {
        return false;
      }

      final date = discussion.effectiveDate;
      final code = discussion.effectiveRepetitionCode;

      if (filterPrefs['filterType'] == 'code') {
        return code == filterPrefs['filterValue'];
      } else if (filterPrefs['filterType'] == 'date' &&
          filterPrefs['filterValue'] != null) {
        try {
          final dates = filterPrefs['filterValue']!.split('/');
          final dateRange = DateTimeRange(
            start: DateTime.parse(dates[0]),
            end: DateTime.parse(dates[1]),
          );
          if (date == null) return false;
          final dDate = DateTime.parse(date);
          return !dDate.isBefore(dateRange.start) &&
              !dDate.isAfter(dateRange.end);
        } catch (e) {
          return false;
        }
      } else if (filterPrefs['filterType'] == 'date_today_and_before') {
        if (date == null) return false;
        try {
          final dDate = DateTime.parse(date);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          return !dDate.isAfter(today);
        } catch (e) {
          return false;
        }
      }
      return true;
    }).toList();

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
              customOrder: customCodeSortOrder,
            ).compareTo(
              getRepetitionCodeIndex(
                b.effectiveRepetitionCode,
                customOrder: customCodeSortOrder,
              ),
            );
        break;
      default:
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
      return filteredDiscussions.reversed.toList();
    }
    return filteredDiscussions;
  }

  Future<Map<String, dynamic>> getSubjectMetadata(
    String subjectJsonPath,
  ) async {
    final file = File(subjectJsonPath);
    final jsonData = await _repository.readSubjectJson(file);
    return jsonData['metadata'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, String?>> _getRelevantDiscussionInfo(
    List<Discussion> discussionsToConsider,
    Map<String, dynamic> sortPrefs,
    List<String> customCodeSortOrder,
  ) async {
    try {
      if (discussionsToConsider.isEmpty) {
        return {'date': null, 'code': null};
      }

      final relevantDiscussion = discussionsToConsider.first;
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

  Future<void> _saveSubjectMetadata(String topicPath, Subject subject) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subject.name);
    final file = File(filePath);
    final jsonData = await _repository.readSubjectJson(file);

    jsonData['metadata'] = {
      'icon': subject.icon,
      'position': subject.position,
      'isHidden': subject.isHidden,
      'linkedPath': subject.linkedPath,
      'isFrozen': subject.isFrozen,
      'frozenDate': subject.frozenDate,
      // ==> PASTIKAN PROPERTI KUNCI DISIMPAN DI METADATA <==
      'isLocked': subject.isLocked,
      'passwordHash': subject.passwordHash,
    };

    await _repository.writeSubjectJson(filePath, jsonData);
  }

  Future<void> addSubject(String topicPath, String subjectName) async {
    await _repository.createSubjectFile(topicPath, subjectName);
  }

  Future<void> renameSubject(
    String topicPath,
    String oldName,
    String newName,
  ) async {
    await _repository.renameSubjectFile(topicPath, oldName, newName);
  }

  Future<void> deleteSubject(String topicPath, String subjectName) async {
    await _repository.deleteSubjectFile(topicPath, subjectName);
    final remainingSubjects = await getSubjects(topicPath);
    await saveSubjectsOrder(topicPath, remainingSubjects);
  }

  Future<void> updateSubjectMetadata(String topicPath, Subject subject) async {
    await _saveSubjectMetadata(topicPath, subject);
  }
}
