// lib/presentation/pages/dashboard_page/widgets/dashboard_header.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../../../../core/services/path_service.dart';
import '../../../content_management/domain/models/discussion_model.dart';
import '../../../my_tasks/application/my_task_service.dart';
import '../../../time_management/application/services/time_log_service.dart';

// Data model untuk menampung statistik header
class _HeaderStats {
  final int pendingTasks;
  final int dueDiscussions;
  final Duration timeLoggedToday;

  _HeaderStats({
    this.pendingTasks = 0,
    this.dueDiscussions = 0,
    this.timeLoggedToday = Duration.zero,
  });
}

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  final PathService _pathService = PathService();
  late Future<_HeaderStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadHeaderStats();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi!';
    if (hour < 15) return 'Selamat Siang!';
    if (hour < 19) return 'Selamat Sore!';
    return 'Selamat Malam!';
  }

  Future<_HeaderStats> _loadHeaderStats() async {
    // Digabung agar berjalan secara paralel
    final results = await Future.wait([
      _getPendingTaskCount(),
      _getDueDiscussionsCount(),
      _getTimeLoggedToday(),
    ]);
    return _HeaderStats(
      pendingTasks: results[0] as int,
      dueDiscussions: results[1] as int,
      timeLoggedToday: results[2] as Duration,
    );
  }

  Future<int> _getPendingTaskCount() async {
    try {
      final myTaskService = MyTaskService();
      final categories = await myTaskService.loadMyTasks();
      int count = 0;
      for (final category in categories) {
        if (!category.isHidden) {
          count += category.tasks.where((task) => !task.checked).length;
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getDueDiscussionsCount() async {
    try {
      final topicsPath = await _pathService.topicsPath;
      final topicsDir = Directory(topicsPath);
      if (!await topicsDir.exists()) return 0;

      int count = 0;
      final today = DateUtils.dateOnly(DateTime.now());

      final topicEntities = topicsDir.listSync().whereType<Directory>();
      for (var topicDir in topicEntities) {
        final subjectFiles = topicDir.listSync().whereType<File>().where(
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
            final effectiveDate = DateTime.tryParse(
              discussion.effectiveDate ?? '',
            );
            if (!discussion.finished &&
                effectiveDate != null &&
                !effectiveDate.isAfter(today)) {
              count++;
            }
          }
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<Duration> _getTimeLoggedToday() async {
    try {
      final timeLogService = TimeLogService();
      final logs = await timeLogService.loadTimeLogs();
      final todayLog = logs.firstWhere(
        (log) => DateUtils.isSameDay(log.date, DateTime.now()),
      );
      final totalMinutes = todayLog.tasks.fold<int>(
        0,
        (sum, task) => sum + task.durationMinutes,
      );
      return Duration(minutes: totalMinutes);
    } catch (e) {
      return Duration.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color:
            Theme.of(context).cardTheme.color?.withOpacity(0.8) ??
            Theme.of(context).cardColor.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Divider(height: 24),
          FutureBuilder<_HeaderStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final stats = snapshot.data ?? _HeaderStats();
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatPill(
                    icon: Icons.task_alt,
                    label: 'Tugas Belum Selesai',
                    value: stats.pendingTasks.toString(),
                    color: Colors.orange.shade700,
                  ),
                  _StatPill(
                    icon: Icons.school_outlined,
                    label: 'Perlu Ditinjau',
                    value: stats.dueDiscussions.toString(),
                    color: Colors.blue.shade700,
                  ),
                  _StatPill(
                    icon: Icons.timer_outlined,
                    label: 'Aktivitas Hari Ini',
                    value:
                        '${stats.timeLoggedToday.inHours}j ${stats.timeLoggedToday.inMinutes.remainder(60)}m',
                    color: Colors.green.shade700,
                  ),
                ],
              );
            },
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            const _DashboardPath(),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$value ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _DashboardPath extends StatelessWidget {
  const _DashboardPath();

  @override
  Widget build(BuildContext context) {
    final PathService pathService = PathService();
    return FutureBuilder<String>(
      future: pathService.contentsPath,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final textStyle = theme.textTheme.bodySmall?.copyWith(
          color: Colors.amber.shade800,
          fontWeight: FontWeight.bold,
        );
        return Row(
          children: [
            const Icon(Icons.folder_outlined, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                snapshot.data!,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
