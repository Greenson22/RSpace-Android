// lib/presentation/pages/time_log_page/widgets/daily_log_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/presentation/pages/time_log_page/widgets/task_log_tile.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/time_log_model.dart';
import '../../../providers/time_log_provider.dart';
import '../dialogs/task_log_dialogs.dart';

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
        trailing: isToday
            ? null
            : TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: isEditable
                      ? Colors.green.withOpacity(0.1)
                      : null,
                  foregroundColor: isEditable ? Colors.green.shade800 : null,
                ),
                onPressed: () => provider.setEditableLog(log),
                child: Text(isEditable ? 'Selesai Edit' : 'Aktivasi Edit'),
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
            ...log!.tasks.map(
              (task) => TaskLogTile(task: task, isEditable: isEditable),
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
