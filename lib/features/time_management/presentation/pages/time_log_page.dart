// lib/features/time_management/presentation/pages/time_log_page.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/time_management/application/providers/time_log_provider.dart';
import 'package:provider/provider.dart';
import '../dialogs/activity_chart_dialog.dart';
import '../dialogs/task_log_dialogs.dart';
import '../layouts/desktop_layout.dart';
import '../layouts/mobile_layout.dart';

class TimeLogPage extends StatefulWidget {
  const TimeLogPage({super.key});

  @override
  State<TimeLogPage> createState() => _TimeLogPageState();
}

class _TimeLogPageState extends State<TimeLogPage> {
  DateTimeRange? _selectedDateRange;
  // ==> TAMBAHKAN STATE BARU UNTUK MODE PENGURUTAN <==
  bool _isReorderMode = false;

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialDateRange =
        _selectedDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);

    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
      });
    }
  }

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
                // ==> TAMBAHKAN TOMBOL TOGGLE DI SINI <==
                IconButton(
                  icon: Icon(_isReorderMode ? Icons.check : Icons.sort),
                  onPressed: () {
                    setState(() {
                      _isReorderMode = !_isReorderMode;
                    });
                  },
                  tooltip: _isReorderMode
                      ? 'Selesai Mengurutkan'
                      : 'Aktifkan Mode Urutkan',
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDateRange(context),
                  tooltip: 'Pilih Rentang Tanggal Riwayat',
                ),
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
                    return DesktopLayout(
                      selectedDateRange: _selectedDateRange,
                      // ==> KIRIM STATE KE LAYOUT <==
                      isReorderMode: _isReorderMode,
                    );
                  } else {
                    return MobileLayout(
                      selectedDateRange: _selectedDateRange,
                      // ==> KIRIM STATE KE LAYOUT <==
                      isReorderMode: _isReorderMode,
                    );
                  }
                },
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => showAddTaskLogDialog(
                context,
                // Logika ini memastikan tugas baru ditambahkan ke log yang benar
                // bahkan saat mode pengurutan aktif.
                date: _isReorderMode
                    ? (provider.editableLog?.date ?? provider.todayLog?.date)
                    : provider.editableLog?.date,
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
