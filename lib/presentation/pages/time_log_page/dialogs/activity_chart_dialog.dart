// lib/presentation/pages/time_log_page/dialogs/activity_chart_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/time_log_model.dart';
import '../widgets/daily_activity_chart.dart';

/// Menampilkan widget statistik ringkas di dalam dialog.
Widget _buildStatRow(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  required DateTime date,
  required double durationMinutes,
}) {
  final hours = (durationMinutes / 60).floor();
  final minutes = (durationMinutes % 60).round();
  final durationString =
      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  final dateString = DateFormat('EEE, d MMM yyyy', 'id_ID').format(date);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text('$title:', style: const TextStyle(fontSize: 12)),
        const Spacer(),
        Text(
          '$dateString ($durationString jam)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

void showActivityChartDialog(BuildContext context, List<TimeLogEntry> logs) {
  showDialog(
    context: context,
    // Gunakan builder agar dialog bisa update state-nya (jika diperlukan)
    builder: (context) {
      // Filter log untuk menampilkan 30 hari terakhir agar tidak terlalu padat
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentLogs = logs
          .where((log) => log.date.isAfter(thirtyDaysAgo))
          .toList();

      // Urutkan dari yang paling lama ke yang terbaru untuk grafik
      recentLogs.sort((a, b) => a.date.compareTo(b.date));

      // Logika untuk mencari hari paling produktif dan paling santai
      TimeLogEntry? mostActiveDay;
      TimeLogEntry? leastActiveDay;
      double maxMinutes = -1;
      double minMinutes = double.infinity;

      if (recentLogs.isNotEmpty) {
        for (final log in recentLogs) {
          final totalMinutes = log.tasks.fold<double>(
            0,
            (sum, task) => sum + task.durationMinutes,
          );
          if (totalMinutes > maxMinutes) {
            maxMinutes = totalMinutes;
            mostActiveDay = log;
          }
          // Hanya hitung hari yang ada aktivitasnya untuk minimum
          if (totalMinutes > 0 && totalMinutes < minMinutes) {
            minMinutes = totalMinutes;
            leastActiveDay = log;
          }
        }
      }

      // Hindari menampilkan hari yang sama jika hanya ada satu data
      if (mostActiveDay == leastActiveDay) {
        leastActiveDay = null;
      }

      return AlertDialog(
        title: const Text('Grafik Aktivitas Harian'),
        contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        content: SizedBox(
          width: double.maxFinite,
          height: 450, // Tinggi dialog ditambah
          child: recentLogs.isEmpty
              ? const Center(child: Text('Tidak ada data untuk ditampilkan.'))
              : Column(
                  children: [
                    // Menampilkan informasi hari produktif/santai
                    if (mostActiveDay != null)
                      _buildStatRow(
                        context,
                        icon: Icons.whatshot_rounded,
                        color: Colors.orange.shade700,
                        title: 'Hari Terproduktif',
                        date: mostActiveDay.date,
                        durationMinutes: maxMinutes,
                      ),
                    if (leastActiveDay != null)
                      _buildStatRow(
                        context,
                        icon: Icons.airline_seat_recline_normal_rounded,
                        color: Colors.blue.shade700,
                        title: 'Hari Tersantai',
                        date: leastActiveDay.date,
                        durationMinutes: minMinutes,
                      ),
                    if (mostActiveDay != null || leastActiveDay != null)
                      const Divider(height: 24),

                    // Grafik
                    Expanded(child: DailyActivityChart(logs: recentLogs)),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      );
    },
  );
}
