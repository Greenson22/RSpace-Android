// lib/presentation/pages/time_log_page/layouts/mobile_layout.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/presentation/pages/time_log_page/dialogs/daily_log_card.dart';
import 'package:provider/provider.dart';
import '../../../providers/time_log_provider.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeLogProvider>(context);
    final todayLog = provider.todayLog;
    final historyLogs = provider.logs
        .where((log) => !DateUtils.isSameDay(log.date, DateTime.now()))
        .toList();

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
            return DailyLogCard(
              log: log,
              isEditable: provider.editableLog == log,
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
    );
  }
}
