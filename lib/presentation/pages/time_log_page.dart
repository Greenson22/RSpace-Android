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
          // --- LOGIKA BARU UNTUK MEMISAHKAN LOG HARI INI DAN RIWAYAT ---
          final todayLog = provider.todayLog;
          final historyLogs = provider.logs
              .where((log) => log != todayLog)
              .toList();
          // --- AKHIR LOGIKA BARU ---

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
                IconButton(
                  icon: const Icon(Icons.list_alt_outlined),
                  onPressed: () => showManagePresetsDialog(context),
                  tooltip: 'Kelola Preset Tugas',
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () => provider.fetchLogs(),
              // --- PERUBAHAN UTAMA PADA STRUKTUR TAMPILAN ---
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // KARTU UNTUK HARI INI (TETAP SAMA)
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
                            'Total Hari Ini: $totalDurationStringToday jam',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TAMPILKAN LOADING ATAU DAFTAR TUGAS HARI INI
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
                    ...todayLog.tasks
                        .map((task) => TaskLogTile(task: task))
                        .toList(),

                  // BAGIAN BARU UNTUK MENAMPILKAN RIWAYAT
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
                      // Hitung total durasi untuk setiap entri riwayat
                      final totalMinutes = log.tasks.fold<int>(
                        0,
                        (sum, task) => sum + task.durationMinutes,
                      );
                      final hours = (totalMinutes / 60).floor();
                      final minutes = totalMinutes % 60;
                      final totalDurationString =
                          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
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
                          children: log.tasks
                              .map((task) => TaskLogTile(task: task))
                              .toList(),
                        ),
                      );
                    }).toList(),
                  ],
                  // TAMPILKAN PESAN INI JIKA TIDAK ADA DATA SAMA SEKALI
                  if (!provider.isLoading && provider.logs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Jurnal aktivitas Anda masih kosong.'),
                      ),
                    ),
                ],
              ),
              // --- AKHIR PERUBAHAN TAMPILAN ---
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
