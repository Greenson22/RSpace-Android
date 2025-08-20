// lib/presentation/pages/time_log_page/layouts/mobile_layout.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/presentation/pages/time_log_page/dialogs/daily_log_card.dart';
import 'package:provider/provider.dart';
import '../../../providers/time_log_provider.dart';

class MobileLayout extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  const MobileLayout({super.key, this.selectedDateRange});

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

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (provider.isLoading && todayLog == null)
          const Center(child: CircularProgressIndicator())
        else
          DailyLogCard(
            log: todayLog,
            isToday: true,
            isEditable: provider.editableLog == todayLog,
          ),
        if (selectedDateRange != null) ...[
          const Padding(
            padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
            child: Divider(),
          ),
          Text(
            'Riwayat yang Ditampilkan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (historyLogs.isNotEmpty)
            ...historyLogs.map((log) {
              return DailyLogCard(
                log: log,
                isEditable: provider.editableLog == log,
              );
            }).toList()
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Tidak ada data pada rentang tanggal yang dipilih.',
                ),
              ),
            ),
        ],
        if (!provider.isLoading && provider.logs.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Jurnal aktivitas Anda masih kosong.'),
            ),
          ),
      ],
    );
  }
}
