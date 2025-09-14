// lib/features/time_management/presentation/dialogs/daily_log_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/time_management/presentation/widgets/task_log_tile.dart';
import 'package:provider/provider.dart';
import '../../domain/models/time_log_model.dart';
import '../../application/providers/time_log_provider.dart';
import 'task_log_dialogs.dart';

class DailyLogCard extends StatelessWidget {
  final TimeLogEntry? log;
  final bool isToday;
  // ==> HAPUS isEditable DARI KONSTRUKTOR <==
  final bool isReorderMode;

  const DailyLogCard({
    super.key,
    required this.log,
    this.isToday = false,
    required this.isReorderMode, // ==> JADIKAN REQUIRED
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeLogProvider>(context, listen: false);
    final theme = Theme.of(context);
    final date = log?.date ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

    final totalMinutes =
        log?.tasks.fold<int>(0, (sum, task) => sum + task.durationMinutes) ?? 0;
    final hours = (totalMinutes / 60).floor();
    final minutes = totalMinutes % 60;
    final totalDurationString =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

    // ==> Logika isEditable sekarang sepenuhnya dikontrol oleh isReorderMode <==
    final bool isEditable = isReorderMode;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isEditable // Gunakan isEditable lokal
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        key: PageStorageKey(date.toIso8601String()),
        initiallyExpanded: isToday || isEditable,
        title: Text(
          formattedDate,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Total Durasi: $totalDurationString jam'),
        // ==> Hapus tombol edit manual dan sederhanakan UI <==
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol hapus hanya muncul jika mode urutkan aktif
            if (isEditable && !isToday)
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDeleteLogConfirmationDialog(
                    context,
                    date,
                  );
                  if (confirmed == true && log != null) {
                    provider.deleteLog(log!);
                  }
                },
                tooltip: 'Hapus Jurnal Hari Ini',
              ),
          ],
        ),
        children: [
          if (log == null || log!.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isToday
                    ? 'Belum ada tugas hari ini.'
                    : 'Tidak ada tugas pada tanggal ini.',
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: log!.tasks.length,
              buildDefaultDragHandles: isEditable, // Kontrol dengan isEditable
              itemBuilder: (context, index) {
                final task = log!.tasks[index];
                return TaskLogTile(
                  key: ValueKey(task.id),
                  task: task,
                  isEditable: isEditable,
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final List<LoggedTask> reorderedTasks = List.from(log!.tasks);
                final LoggedTask item = reorderedTasks.removeAt(oldIndex);
                reorderedTasks.insert(newIndex, item);
                provider.updateTasksOrder(log!, reorderedTasks);
              },
            ),
          // Tombol tambah tetap ada, dan muncul jika mode edit/reorder aktif
          if (isEditable)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(
                  isToday
                      ? 'Tambah Tugas Hari Ini'
                      : 'Tambah Tugas ke Tanggal Ini',
                ),
                onPressed: () => showAddTaskLogDialog(context, date: date),
              ),
            ),
        ],
      ),
    );
  }
}
