// lib/presentation/pages/time_log_page/widgets/daily_log_card.dart
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
  final bool isEditable;

  const DailyLogCard({
    super.key,
    required this.log,
    this.isToday = false,
    required this.isEditable,
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isEditable
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        key: PageStorageKey(date.toIso8601String()),
        initiallyExpanded: isToday,
        title: Text(
          formattedDate,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Total Durasi: $totalDurationString jam'),
        // ## PERUBAHAN 1: Hapus Tombol "Urutkan Tugas" dari sini ##
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isToday)
              Container() // Placeholder untuk hari ini agar layout konsisten
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: isEditable
                          ? Colors.green.withOpacity(0.1)
                          : null,
                      foregroundColor: isEditable
                          ? Colors.green.shade800
                          : null,
                    ),
                    onPressed: () => provider.setEditableLog(log),
                    child: Text(isEditable ? 'Selesai Edit' : 'Aktivasi Edit'),
                  ),
                ],
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
            // ## PERUBAHAN 2: Ganti daftar biasa dengan ReorderableListView ##
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: log!.tasks.length,
              // Tampilkan handle untuk drag hanya saat mode edit aktif
              buildDefaultDragHandles: isEditable,
              itemBuilder: (context, index) {
                final task = log!.tasks[index];
                // Key sangat penting untuk ReorderableListView agar berfungsi
                return TaskLogTile(
                  key: ValueKey(task.id),
                  task: task,
                  isEditable: isEditable,
                );
              },
              onReorder: (oldIndex, newIndex) {
                // Logika untuk mengatur ulang urutan list
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                // Buat salinan list yang bisa diubah
                final List<LoggedTask> reorderedTasks = List.from(log!.tasks);
                // Pindahkan item
                final LoggedTask item = reorderedTasks.removeAt(oldIndex);
                reorderedTasks.insert(newIndex, item);
                // Panggil provider untuk menyimpan urutan baru
                provider.updateTasksOrder(log!, reorderedTasks);
              },
            ),
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
