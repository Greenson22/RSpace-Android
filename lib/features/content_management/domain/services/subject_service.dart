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

    // **LOGIKA PENGURUTAN TELAH DIHAPUS DARI SINI**

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
    List<String> customCodeSortOrder,
  ) async {
    try {
      if (discussions.isNotEmpty && discussions.every((d) => d.finished)) {
        return {'date': null, 'code': 'Finish'};
      }

      List<Discussion> discussionsToConsider = discussions
          .where((d) => !d.finished)
          .toList();

      if (discussionsToConsider.isEmpty) {
        return {'date': null, 'code': null};
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

      discussionsToConsider.sort(comparator);
      if (!sortAscending) {
        discussionsToConsider = discussionsToConsider.reversed.toList();
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
