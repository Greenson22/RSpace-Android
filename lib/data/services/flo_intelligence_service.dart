// lib/data/services/flo_intelligence_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../features/content_management/domain/models/discussion_model.dart';
import '../models/my_task_model.dart';
import '../models/time_log_model.dart';
import 'path_service.dart';

// Kelas ini bertindak sebagai "otak" atau ANN simulasi untuk Flo.
class FloIntelligenceService {
  final PathService _pathService = PathService();
  final Random _random = Random();

  // Fungsi utama yang dipanggil oleh widget Flo untuk mendapatkan saran.
  Future<String?> getIntelligentSuggestion() async {
    try {
      // Coba berikan saran berdasarkan prioritas.
      String? suggestion = await _suggestReviewBasedOnRepetition();
      if (suggestion != null) return suggestion;

      suggestion = await _suggestTaskBasedOnActivity();
      if (suggestion != null) return suggestion;

      suggestion = await _praiseProductivity();
      if (suggestion != null) return suggestion;
    } catch (e) {
      debugPrint("Flo's Brain Error: $e");
    }

    // Jika tidak ada saran cerdas, kembalikan null agar Flo bisa menggunakan ucapan standarnya.
    return null;
  }

  // ATURAN 1: Menganalisis diskusi dan menyarankan untuk review.
  Future<String?> _suggestReviewBasedOnRepetition() async {
    final List<Discussion> discussionsToReview = [];
    final topicsPath = await _pathService.topicsPath;
    final topicsDir = Directory(topicsPath);

    if (!await topicsDir.exists()) return null;

    final topicEntities = topicsDir.listSync();
    for (var topicEntity in topicEntities) {
      if (topicEntity is Directory) {
        final subjectFiles = topicEntity.listSync().whereType<File>().where(
          (file) =>
              file.path.endsWith('.json') &&
              !path.basename(file.path).contains('config'),
        );

        for (final subjectFile in subjectFiles) {
          final jsonString = await subjectFile.readAsString();
          if (jsonString.isEmpty) continue;

          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          final contentList = jsonData['content'] as List<dynamic>? ?? [];

          for (var item in contentList) {
            final discussion = Discussion.fromJson(item);
            final date = DateTime.tryParse(discussion.effectiveDate ?? '');
            // Kriteria: Kode repetisi rendah, belum selesai, dan sudah lewat waktunya.
            if (!discussion.finished &&
                [
                  'R0D',
                  'R1D',
                  'R3D',
                ].contains(discussion.effectiveRepetitionCode) &&
                date != null &&
                date.isBefore(DateTime.now())) {
              discussionsToReview.add(discussion);
            }
          }
        }
      }
    }

    if (discussionsToReview.isNotEmpty) {
      final suggestion =
          discussionsToReview[_random.nextInt(discussionsToReview.length)];
      return "Mungkin ini saatnya meninjau '${suggestion.discussion}'?";
    }
    return null;
  }

  // ATURAN 2: Menganalisis tugas dan aktivitas harian.
  Future<String?> _suggestTaskBasedOnActivity() async {
    final myTasksFile = File(await _pathService.myTasksPath);
    final timeLogFile = File(await _pathService.timeLogPath);

    if (!await myTasksFile.exists() || !await timeLogFile.exists()) return null;

    final myTasksJson = jsonDecode(await myTasksFile.readAsString());
    final timeLogJson = jsonDecode(await timeLogFile.readAsString());

    final categories = (myTasksJson['categories'] as List<dynamic>)
        .map((item) => TaskCategory.fromJson(item))
        .toList();
    final logs = (timeLogJson as List<dynamic>)
        .map((item) => TimeLogEntry.fromJson(item))
        .toList();

    int totalMinutesToday = 0;
    final todayLog = logs.firstWhere(
      (log) => DateUtils.isSameDay(log.date, DateTime.now()),
      orElse: () => TimeLogEntry(date: DateTime.now(), tasks: []),
    );
    totalMinutesToday = todayLog.tasks.fold(
      0,
      (sum, task) => sum + task.durationMinutes,
    );

    List<MyTask> pendingTasks = [];
    for (var category in categories) {
      pendingTasks.addAll(category.tasks.where((task) => !task.checked));
    }

    // Kriteria: Ada tugas yang belum selesai DAN aktivitas hari ini masih sedikit.
    if (pendingTasks.isNotEmpty && totalMinutesToday < 60) {
      final suggestedTask = pendingTasks[_random.nextInt(pendingTasks.length)];
      return "Bagaimana kalau kita kerjakan tugas '${suggestedTask.name}' sekarang?";
    }
    return null;
  }

  // ATURAN 3: Memberikan pujian jika produktif.
  Future<String?> _praiseProductivity() async {
    final timeLogFile = File(await _pathService.timeLogPath);
    if (!await timeLogFile.exists()) return null;

    final timeLogJson = jsonDecode(await timeLogFile.readAsString());
    final logs = (timeLogJson as List<dynamic>)
        .map((item) => TimeLogEntry.fromJson(item))
        .toList();

    int totalMinutesToday = 0;
    final todayLog = logs.firstWhere(
      (log) => DateUtils.isSameDay(log.date, DateTime.now()),
      orElse: () => TimeLogEntry(date: DateTime.now(), tasks: []),
    );
    totalMinutesToday = todayLog.tasks.fold(
      0,
      (sum, task) => sum + task.durationMinutes,
    );

    // Kriteria: Aktivitas hari ini lebih dari 3 jam.
    if (totalMinutesToday > 180) {
      return "Wow, produktif sekali hari ini! Kerja bagus!";
    }
    return null;
  }
}
