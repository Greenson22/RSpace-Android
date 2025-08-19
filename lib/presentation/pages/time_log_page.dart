// lib/presentation/pages/time_log_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/time_log_model.dart';
import '../providers/time_log_provider.dart';
// ==> 1. IMPORT DIALOG BARU
import 'time_log_page/dialogs/activity_chart_dialog.dart';
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
          final editableLog = provider.editableLog;
          final historyLogs = provider.logs
              .where((log) => !DateUtils.isSameDay(log.date, DateTime.now()))
              .toList();

          final today = DateTime.now();
          final formattedDate = DateFormat(
            'EEEE, d MMMM yyyy',
            'id_ID',
          ).format(today);

          final totalMinutesToday =
              todayLog?.tasks.fold<int>(
                0,
                (sum, task) => sum + task.durationMinutes,
              ) ??
              0;
          final hoursToday = (totalMinutesToday / 60).floor();
          final minutesToday = totalMinutesToday % 60;
          final totalDurationStringToday =
              '${hoursToday.toString().padLeft(2, '0')}:${minutesToday.toString().padLeft(2, '0')}';

          return Scaffold(
            appBar: AppBar(
              title: const Text('Jurnal Aktivitas'),
              actions: [
                // ==> 2. TAMBAHKAN TOMBOL INI
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  onPressed: () =>
                      showActivityChartDialog(context, provider.logs),
                  tooltip: 'Lihat Grafik Aktivitas',
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: provider.editableLog == todayLog && todayLog != null
                          ? BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            )
                          : BorderSide.none,
                    ),
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
                            'Total Hari Ini: $totalDurationStringToday jam',
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
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'Belum ada tugas hari ini. Tekan + untuk memulai.',
                        ),
                      ),
                    )
                  else
                    ...todayLog.tasks.map(
                      (task) => TaskLogTile(
                        task: task,
                        isEditable: editableLog == todayLog,
                      ),
                    ),
                  if (historyLogs.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
                      child: Divider(),
                    ),
                    Text(
                      'Riwayat Sebelumnya',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    ...historyLogs.map((log) {
                      final totalMinutes = log.tasks.fold<int>(
                        0,
                        (sum, task) => sum + task.durationMinutes,
                      );
                      final hours = (totalMinutes / 60).floor();
                      final minutes = totalMinutes % 60;
                      final totalDurationString =
                          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

                      final bool isThisLogEditable = editableLog == log;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isThisLogEditable
                              ? BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            DateFormat(
                              'EEEE, d MMMM yyyy',
                              'id_ID',
                            ).format(log.date),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Total Durasi: $totalDurationString jam',
                          ),
                          trailing: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: isThisLogEditable
                                  ? Colors.green.withOpacity(0.1)
                                  : null,
                              foregroundColor: isThisLogEditable
                                  ? Colors.green.shade800
                                  : null,
                            ),
                            onPressed: () => provider.setEditableLog(log),
                            child: Text(
                              isThisLogEditable
                                  ? 'Selesai Edit'
                                  : 'Aktivasi Edit',
                            ),
                          ),
                          children: [
                            ...log.tasks.map(
                              (task) => TaskLogTile(
                                task: task,
                                isEditable: isThisLogEditable,
                              ),
                            ),
                            if (isThisLogEditable)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text(
                                    'Tambah Tugas ke Tanggal Ini',
                                  ),
                                  onPressed: () => showAddTaskLogDialog(
                                    context,
                                    date: log.date,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  if (!provider.isLoading && provider.logs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Jurnal aktivitas Anda masih kosong.'),
                      ),
                    ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () =>
                  showAddTaskLogDialog(context, date: editableLog?.date),
              tooltip: 'Tambah Tugas ke Jurnal Aktif',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
