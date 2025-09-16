// lib/features/content_management/domain/services/subject_service.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:path/path.dart' as path;
import '../models/discussion_model.dart';
import '../models/subject_model.dart';
import 'discussion_service.dart';
import '../../../../core/services/path_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';
import 'subject_repository.dart';

class SubjectService {
  final DiscussionService _discussionService = DiscussionService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final SubjectRepository _repository = SubjectRepository();
  final PathService _pathService = PathService();
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
      final content = jsonData['content'] as List<dynamic>? ?? [];

      final discussions = content
          .map((item) => Discussion.fromJson(item))
          .toList();
      final relevantDiscussionInfo = await _getRelevantDiscussionInfo(
        discussions,
        sortPrefs,
        filterPrefs,
        customCodeSortOrder,
      );

      final repetitionCodeCounts = <String, int>{};
      for (final discussion in discussions) {
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
          discussionCount: discussions.length,
          finishedDiscussionCount: discussions.where((d) => d.finished).length,
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
      final indexA = getRepetitionCodeIndex(
        codeA,
        customOrder: customCodeSortOrder,
      );
      final indexB = getRepetitionCodeIndex(
        codeB,
        customOrder: customCodeSortOrder,
      );
      if (indexA == indexB) {
        return a.position.compareTo(b.position);
      }
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

  // ==> METODE BARU DITAMBAHKAN DI SINI <==
  /// Mendapatkan metadata dari file subject berdasarkan path-nya.
  Future<Map<String, dynamic>> getSubjectMetadata(
    String subjectJsonPath,
  ) async {
    final file = File(subjectJsonPath);
    final jsonData = await _repository.readSubjectJson(file);
    return jsonData['metadata'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, String?>> _getRelevantDiscussionInfo(
    List<Discussion> discussions,
    Map<String, dynamic> sortPrefs,
    Map<String, String?> filterPrefs,
    List<String> customCodeSortOrder,
  ) async {
    try {
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

      // ==> BLOK KODE YANG MENGABAIKAN R0D DIHAPUS DARI SINI <==

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

  Future<void> _saveSubjectMetadata(String topicPath, Subject subject) async {
    final filePath = await _pathService.getSubjectPath(topicPath, subject.name);
    final file = File(filePath);
    final jsonData = await _repository.readSubjectJson(file);

    jsonData['metadata'] = {
      'icon': subject.icon,
      'position': subject.position,
      'isHidden': subject.isHidden,
      'linkedPath': subject.linkedPath,
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
