// lib/presentation/pages/time_log_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/time_log_provider.dart';
import 'time_log_page/dialogs/task_log_dialogs.dart';
import 'time_log_page/widgets/task_log_tile.dart';

class TimeLogPage extends StatelessWidget {
  const TimeLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimeLogProvider(),
      child: Consumer<TimeLogProvider>(
        builder: (context, provider, child) {
          final todayLog = provider.todayLog;
          final today = DateTime.now();
          final formattedDate = DateFormat(
            'EEEE, d MMMM yyyy',
            'id_ID',
          ).format(today);
          final totalMinutes =
              todayLog?.tasks.fold<int>(
                0,
                (sum, task) => sum + task.durationMinutes,
              ) ??
              0;
          final hours = (totalMinutes / 60).floor();
          final minutes = totalMinutes % 60;
          final totalDurationString =
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

          return Scaffold(
            appBar: AppBar(
              title: const Text('Jurnal Aktivitas'),
              // ==> TOMBOL BARU DITAMBAHKAN DI SINI <==
              actions: [
                IconButton(
                  icon: const Icon(Icons.list_alt_outlined),
                  onPressed: () => showManagePresetsDialog(context),
                  tooltip: 'Kelola Preset Tugas',
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () => provider.fetchLogs(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Hari Ini: $totalDurationString jam',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (todayLog == null || todayLog.tasks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Belum ada tugas hari ini. Tekan + untuk memulai.',
                        ),
                      ),
                    )
                  else
                    ...todayLog.tasks
                        .map((task) => TaskLogTile(task: task))
                        .toList(),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => showAddTaskLogDialog(context),
              tooltip: 'Tambah Tugas',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
