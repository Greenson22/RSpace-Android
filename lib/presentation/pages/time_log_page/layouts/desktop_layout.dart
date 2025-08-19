// lib/presentation/pages/time_log_page/layouts/desktop_layout.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/presentation/pages/time_log_page/dialogs/daily_log_card.dart';
import 'package:provider/provider.dart';
import '../../../providers/time_log_provider.dart';

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeLogProvider>(context);
    final todayLog = provider.todayLog;
    final historyLogs = provider.logs
        .where((log) => !DateUtils.isSameDay(log.date, DateTime.now()))
        .toList();

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
                'Riwayat Sebelumnya',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (provider.isLoading && historyLogs.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (historyLogs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Text('Tidak ada riwayat aktivitas.'),
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
