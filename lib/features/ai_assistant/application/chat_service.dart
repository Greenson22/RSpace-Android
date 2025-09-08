// lib/data/services/chat_service.dart
import 'package:intl/intl.dart';
import '../domain/models/chat_message_model.dart';
import '../../my_tasks/domain/models/my_task_model.dart';
import '../../time_management/domain/models/time_log_model.dart';
import '../../content_management/domain/services/discussion_service.dart';
import '../../settings/application/services/gemini_service.dart';
import '../../my_tasks/application/my_task_service.dart';
import '../../../data/services/path_service.dart';
import '../../content_management/domain/services/subject_service.dart';
import '../../time_management/application/services/time_log_service.dart';
import '../../content_management/domain/services/topic_service.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart'; // Import material for DateUtils

class ChatService {
  final GeminiService _geminiService = GeminiService();
  final PathService _pathService = PathService();
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final DiscussionService _discussionService = DiscussionService();
  final MyTaskService _myTaskService = MyTaskService();
  final TimeLogService _timeLogService = TimeLogService();

  Future<ChatMessage> getResponse(String userQuery) async {
    try {
      final context = await _gatherApplicationContext();
      final responseText = await _geminiService.getChatCompletion(
        userQuery,
        context: context,
      );
      return ChatMessage(text: responseText, role: ChatRole.model);
    } catch (e) {
      return ChatMessage(
        text: 'Maaf, terjadi kesalahan: ${e.toString()}',
        role: ChatRole.error,
      );
    }
  }

  Future<String> _gatherApplicationContext() async {
    final buffer = StringBuffer();
    final today = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());
    buffer.writeln('=== Konteks Data Aplikasi RSpace ===');
    buffer.writeln('Tanggal Hari Ini: $today\n');

    // 1. Rangkuman Topics, Subjects, dan Discussions
    try {
      final topics = await _topicService.getTopics();
      if (topics.isNotEmpty) {
        buffer.writeln('## Rangkuman Topik & Pembahasan:');
        final topicsPath = await _pathService.topicsPath;
        for (final topic in topics) {
          if (topic.isHidden) continue;
          buffer.writeln('- Topik: ${topic.name}');
          final topicPath = path.join(topicsPath, topic.name);
          final subjects = await _subjectService.getSubjects(topicPath);
          for (final subject in subjects) {
            if (subject.isHidden) continue;
            final discussions = await _discussionService.loadDiscussions(
              path.join(topicPath, '${subject.name}.json'),
            );
            final activeDiscussions = discussions
                .where((d) => !d.finished)
                .toList();
            if (activeDiscussions.isNotEmpty) {
              buffer.writeln(
                '  - Subjek: ${subject.name} (${activeDiscussions.length} pembahasan aktif)',
              );
              for (final discussion in activeDiscussions) {
                final dueDate = discussion.effectiveDate != null
                    ? DateFormat(
                        'd MMM',
                      ).format(DateTime.parse(discussion.effectiveDate!))
                    : 'N/A';
                buffer.writeln(
                  '    - ${discussion.discussion} (Kode: ${discussion.effectiveRepetitionCode}, Jadwal: $dueDate)',
                );
              }
            }
          }
        }
        buffer.writeln();
      }
    } catch (e) {
      // Abaikan jika ada error
    }

    // 2. Rangkuman My Tasks
    try {
      final List<TaskCategory> categories = await _myTaskService.loadMyTasks();
      if (categories.isNotEmpty) {
        buffer.writeln('## Rangkuman Tugas (My Tasks):');
        for (final category in categories) {
          if (category.isHidden) continue;
          final pendingTasks = category.tasks.where((t) => !t.checked).toList();
          if (pendingTasks.isNotEmpty) {
            buffer.writeln('- Kategori: ${category.name}');
            for (final task in pendingTasks) {
              buffer.writeln('  - [Belum] ${task.name}');
            }
          }
        }
        buffer.writeln();
      }
    } catch (e) {
      // Abaikan
    }

    // 3. Rangkuman Jurnal Aktivitas Hari Ini
    try {
      final List<TimeLogEntry> logs = await _timeLogService.loadTimeLogs();
      final todayLog = logs.firstWhere(
        (log) => DateUtils.isSameDay(log.date, DateTime.now()),
        orElse: () => TimeLogEntry(date: DateTime.now(), tasks: []),
      );

      if (todayLog.tasks.isNotEmpty) {
        buffer.writeln('## Rangkuman Jurnal Aktivitas Hari Ini:');
        int totalMinutes = 0;
        for (final task in todayLog.tasks) {
          buffer.writeln('- ${task.name}: ${task.durationMinutes} menit');
          totalMinutes += task.durationMinutes;
        }
        final hours = (totalMinutes / 60).floor();
        final minutes = totalMinutes % 60;
        buffer.writeln('Total Durasi Hari Ini: $hours jam $minutes menit.');
      }
    } catch (e) {
      // Abaikan
    }

    buffer.writeln('====================================');
    return buffer.toString();
  }
}
