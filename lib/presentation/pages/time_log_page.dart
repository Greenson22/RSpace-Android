// lib/presentation/pages/time_log_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/presentation/providers/time_log_provider.dart';
import 'package:provider/provider.dart';
import 'time_log_page/dialogs/activity_chart_dialog.dart';
import 'time_log_page/dialogs/task_log_dialogs.dart';
import 'time_log_page/layouts/desktop_layout.dart';
import 'time_log_page/layouts/mobile_layout.dart';

class TimeLogPage extends StatelessWidget {
  const TimeLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimeLogProvider(),
      child: Consumer<TimeLogProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Jurnal Aktivitas'),
              actions: [
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double breakpoint = 800.0;
                  if (constraints.maxWidth > breakpoint) {
                    return const DesktopLayout();
                  } else {
                    return const MobileLayout();
                  }
                },
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => showAddTaskLogDialog(
                context,
                date: provider.editableLog?.date,
              ),
              tooltip: 'Tambah Tugas ke Jurnal Aktif',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
