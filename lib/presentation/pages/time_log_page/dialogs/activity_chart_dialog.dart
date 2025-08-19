// lib/presentation/pages/time_log_page/dialogs/activity_chart_dialog.dart
import 'package:flutter/material.dart';
import '../../../../data/models/time_log_model.dart';
import '../widgets/daily_activity_chart.dart';

void showActivityChartDialog(
  BuildContext context,
  List<TimeLogEntry> logs,
) {
  showDialog(
    context: context,
    // Gunakan builder agar dialog bisa update state-nya (jika diperlukan)
    builder: (context) {
      // Filter log untuk menampilkan 30 hari terakhir agar tidak terlalu padat
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentLogs =
          logs.where((log) => log.date.isAfter(thirtyDaysAgo)).toList();

      // Urutkan dari yang paling lama ke yang terbaru untuk grafik
      recentLogs.sort((a, b) => a.date.compareTo(b.date));

      return AlertDialog(
        title: const Text('Grafik Aktivitas Harian'),
        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // Beri tinggi agar dialog tidak overflow
          child: recentLogs.isEmpty
              ? const Center(child: Text('Tidak ada data untuk ditampilkan.'))
              : DailyActivityChart(logs: recentLogs),
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