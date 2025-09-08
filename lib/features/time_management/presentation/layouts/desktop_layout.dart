// lib/presentation/pages/time_log_page/layouts/desktop_layout.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/time_management/presentation/dialogs/daily_log_card.dart';
import 'package:provider/provider.dart';
import '../../application/providers/time_log_provider.dart';

class DesktopLayout extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  const DesktopLayout({super.key, this.selectedDateRange});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeLogProvider>(context);
    final todayLog = provider.todayLog;

    // Filter riwayat berdasarkan rentang tanggal yang dipilih
    final historyLogs = provider.logs.where((log) {
      if (DateUtils.isSameDay(log.date, DateTime.now())) return false;
      if (selectedDateRange == null) return false;

      final logDate = DateUtils.dateOnly(log.date);
      final startDate = DateUtils.dateOnly(selectedDateRange!.start);
      final endDate = DateUtils.dateOnly(selectedDateRange!.end);

      return (logDate.isAtSameMomentAs(startDate) ||
              logDate.isAfter(startDate)) &&
          (logDate.isAtSameMomentAs(endDate) || logDate.isBefore(endDate));
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kolom Kiri (Hari Ini)
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Hari Ini',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (provider.isLoading && todayLog == null)
                const Center(child: CircularProgressIndicator())
              else
                DailyLogCard(
                  log: todayLog,
                  isToday: true,
                  isEditable: provider.editableLog == todayLog,
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Kolom Kanan (Riwayat)
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                selectedDateRange == null
                    ? 'Pilih Rentang Tanggal'
                    : 'Riwayat yang Ditampilkan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (selectedDateRange == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Text(
                      'Gunakan ikon kalender di pojok kanan atas untuk menampilkan riwayat.',
                    ),
                  ),
                )
              else if (provider.isLoading && historyLogs.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (historyLogs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Text('Tidak ada data pada rentang tanggal ini.'),
                  ),
                )
              else
                ...historyLogs.map((log) {
                  return DailyLogCard(
                    log: log,
                    isEditable: provider.editableLog == log,
                  );
                }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
