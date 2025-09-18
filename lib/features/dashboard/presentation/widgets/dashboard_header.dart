// lib/features/dashboard/presentation/widgets/dashboard_header.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/features/time_management/presentation/pages/time_log_page.dart';
import '../../../../core/services/path_service.dart';
import '../../../content_management/domain/models/discussion_model.dart';
import '../../../my_tasks/application/my_task_service.dart';
import '../../../settings/application/services/gemini_service.dart';
import '../../../time_management/application/services/time_log_service.dart';
import '../../../my_tasks/presentation/pages/my_tasks_page.dart';
import '../../../content_management/presentation/topics/topics_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/neuron_provider.dart';
// ==> IMPORT SERVICE BARU & HAPUS STORAGE_SERVICE <==
import '../../../settings/application/services/dashboard_settings_service.dart';

class _HeaderStats {
  final int pendingTasks;
  final int totalTasks;
  final int finishedTasks;
  final int dueDiscussions;
  final Duration timeLoggedToday;
  final int totalDiscussions;
  final int finishedDiscussions;
  final int neurons;

  _HeaderStats({
    this.pendingTasks = 0,
    this.totalTasks = 0,
    this.finishedTasks = 0,
    this.dueDiscussions = 0,
    this.timeLoggedToday = Duration.zero,
    this.totalDiscussions = 0,
    this.finishedDiscussions = 0,
    this.neurons = 0,
  });
}

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader>
    with WidgetsBindingObserver {
  final PathService _pathService = PathService();
  // ==> GUNAKAN SERVICE BARU <==
  final DashboardSettingsService _settingsService = DashboardSettingsService();
  final GeminiService _geminiService = GeminiService();
  late Future<_HeaderStats> _statsFuture;
  String? _motivationalQuote;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadHeaderStats();
    _updateAndDisplayQuote();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {
          _statsFuture = _loadHeaderStats();
          _updateAndDisplayQuote();
        });
        Provider.of<NeuronProvider>(context, listen: false).loadNeurons();
      }
    }
  }

  Future<String> _getQuoteFromCache() async {
    const fallbackQuote = 'Teruslah belajar setiap hari.';
    final random = Random();
    try {
      final quotesPath = await _pathService.motivationalQuotesPath;
      final quotesFile = File(quotesPath);
      if (await quotesFile.exists()) {
        final jsonString = await quotesFile.readAsString();
        if (jsonString.isNotEmpty) {
          final existingQuotes = List<String>.from(jsonDecode(jsonString));
          if (existingQuotes.isNotEmpty) {
            return existingQuotes[random.nextInt(existingQuotes.length)];
          }
        }
      }
    } catch (e) {
      // Abaikan error dan kembalikan fallback
    }
    return fallbackQuote;
  }

  Future<void> _updateAndDisplayQuote() async {
    final cachedQuote = await _getQuoteFromCache();
    if (mounted) {
      setState(() {
        _motivationalQuote = cachedQuote;
      });
    }

    final newQuote = await _geminiService.getMotivationalQuote();
    if (mounted) {
      setState(() {
        _motivationalQuote = newQuote;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi!';
    if (hour < 15) return 'Selamat Siang!';
    if (hour < 19) return 'Selamat Sore!';
    return 'Selamat Malam!';
  }

  // ==> FUNGSI INI DIPERBARUI <==
  Future<_HeaderStats> _loadHeaderStats() async {
    // Muat pengaturan dari file JSON terlebih dahulu
    final dashboardSettings = await _settingsService.loadSettings();
    final excludedTaskCategories =
        dashboardSettings['excludedTaskCategories'] ?? <String>{};
    final excludedSubjects =
        dashboardSettings['excludedSubjects'] ?? <String>{};

    // Jalankan pengambilan data secara paralel dengan pengaturan yang sudah didapat
    final results = await Future.wait([
      _getTaskStats(excludedTaskCategories),
      _getDiscussionStats(excludedSubjects),
      _getTimeLoggedToday(),
    ]);
    final taskStats = results[0] as Map<String, int>;
    final discussionStats = results[1] as Map<String, int>;
    return _HeaderStats(
      pendingTasks: taskStats['pending'] ?? 0,
      totalTasks: taskStats['total'] ?? 0,
      finishedTasks: taskStats['finished'] ?? 0,
      dueDiscussions: discussionStats['due'] ?? 0,
      totalDiscussions: discussionStats['total'] ?? 0,
      finishedDiscussions: discussionStats['finished'] ?? 0,
      timeLoggedToday: results[2] as Duration,
    );
  }

  // ==> FUNGSI INI DIPERBARUI UNTUK MENERIMA PARAMETER <==
  Future<Map<String, int>> _getTaskStats(Set<String> excludedCategories) async {
    try {
      final myTaskService = MyTaskService();
      final categories = await myTaskService.loadMyTasks();
      int pendingCount = 0;
      int totalCount = 0;
      int finishedCount = 0;
      for (final category in categories) {
        if (!category.isHidden && !excludedCategories.contains(category.name)) {
          totalCount += category.tasks.length;
          pendingCount += category.tasks.where((task) => !task.checked).length;
          finishedCount += category.tasks.where((task) => task.checked).length;
        }
      }
      return {
        'pending': pendingCount,
        'total': totalCount,
        'finished': finishedCount,
      };
    } catch (e) {
      return {'pending': 0, 'total': 0, 'finished': 0};
    }
  }

  // ==> FUNGSI INI DIPERBARUI UNTUK MENERIMA PARAMETER <==
  Future<Map<String, int>> _getDiscussionStats(
    Set<String> excludedSubjects,
  ) async {
    try {
      final topicsPath = await _pathService.topicsPath;
      final topicsDir = Directory(topicsPath);
      if (!await topicsDir.exists()) return {};

      int dueCount = 0;
      int totalDiscussions = 0;
      int finishedDiscussions = 0;
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

          final metadata = jsonData['metadata'] as Map<String, dynamic>? ?? {};
          final isHidden = metadata['isHidden'] as bool? ?? false;
          if (isHidden) {
            continue;
          }

          final topicName = path.basename(topicDir.path);
          final subjectName = path.basenameWithoutExtension(subjectFile.path);
          final subjectId = '$topicName/$subjectName';

          bool isSubjectIncludedInCalcs = !excludedSubjects.contains(subjectId);

          final contentList = jsonData['content'] as List<dynamic>? ?? [];

          if (isSubjectIncludedInCalcs) {
            for (var item in contentList) {
              final discussion = Discussion.fromJson(item);

              if (discussion.points.isEmpty) {
                totalDiscussions++;
                if (discussion.finished) {
                  finishedDiscussions++;
                }
              }

              if (!discussion.finished) {
                final effectiveDate = DateTime.tryParse(
                  discussion.effectiveDate ?? '',
                );
                if (effectiveDate != null && !effectiveDate.isAfter(today)) {
                  dueCount++;
                }
              }
            }
          }
        }
      }
      return {
        'due': dueCount,
        'total': totalDiscussions,
        'finished': finishedDiscussions,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating discussion stats: $e');
      }
      return {};
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'EEEE, d MMMM yyyy',
                        'id_ID',
                      ).format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Consumer<NeuronProvider>(
                builder: (context, neuronProvider, child) {
                  return Chip(
                    avatar: const Icon(
                      Icons.psychology_outlined,
                      color: Colors.white,
                    ),
                    label: Text(
                      '${neuronProvider.neuronCount} Neurons',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.deepPurple,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _motivationalQuote == null
                ? 'Memuat motivasi...'
                : '"$_motivationalQuote"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
                alignment: WrapAlignment.center,
                children: [
                  _StatPill(
                    icon: Icons.list_alt_outlined,
                    label: 'Total Tugas',
                    value: stats.totalTasks.toString(),
                    color: Colors.teal.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyTasksPage()),
                    ),
                  ),
                  _StatPill(
                    icon: Icons.task_alt,
                    label: 'Tugas Belum Selesai',
                    value: stats.pendingTasks.toString(),
                    color: Colors.orange.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyTasksPage()),
                    ),
                  ),
                  _StatPill(
                    icon: Icons.check_circle_outline,
                    label: 'Tugas Selesai',
                    value: stats.finishedTasks.toString(),
                    color: Colors.green.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyTasksPage()),
                    ),
                  ),
                  _StatPill(
                    icon: Icons.school_outlined,
                    label: 'Perlu Ditinjau',
                    value: stats.dueDiscussions.toString(),
                    color: Colors.blue.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TopicsPage()),
                    ),
                  ),
                  _StatPill(
                    icon: Icons.chat_bubble_outline,
                    label: 'Total Diskusi',
                    value: stats.totalDiscussions.toString(),
                    color: Colors.purple.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TopicsPage()),
                    ),
                  ),
                  _StatPill(
                    icon: Icons.timer_outlined,
                    label: 'Aktivitas Hari Ini',
                    value:
                        '${stats.timeLoggedToday.inHours}j ${stats.timeLoggedToday.inMinutes.remainder(60)}m',
                    color: Colors.cyan.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TimeLogPage()),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const _DashboardPath(),
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
  final VoidCallback onTap;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
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
        ),
      ),
    );
  }
}

class _DashboardPath extends StatelessWidget {
  const _DashboardPath();

  @override
  Widget build(BuildContext context) {
    final PathService pathService = PathService();
    return FutureBuilder<String?>(
      future: pathService.loadCustomStoragePath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 32);
        }

        final customPath = snapshot.data;
        final String displayLabel;
        final String fullPathTooltip;

        if (customPath != null && customPath.isNotEmpty) {
          fullPathTooltip = customPath;
          displayLabel = '.../${path.basename(customPath)}/RSpace_data';
        } else {
          fullPathTooltip = "Menggunakan lokasi penyimpanan default aplikasi.";
          displayLabel = "Lokasi: Penyimpanan Default";
        }

        return Tooltip(
          message: fullPathTooltip,
          child: Chip(
            avatar: Icon(
              Icons.folder_open_outlined,
              size: 18,
              color: Colors.blueGrey[700],
            ),
            label: Text(
              displayLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey[700]),
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.blueGrey[50],
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        );
      },
    );
  }
}
