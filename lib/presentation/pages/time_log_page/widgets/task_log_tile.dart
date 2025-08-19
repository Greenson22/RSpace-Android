// lib/presentation/pages/time_log_page/widgets/task_log_tile.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/time_log_model.dart';
import 'package:my_aplication/presentation/providers/time_log_provider.dart';
import 'package:provider/provider.dart';
import '../dialogs/task_log_dialogs.dart';

class TaskLogTile extends StatelessWidget {
  final LoggedTask task;
  // ==> TAMBAHKAN PROPERTI BARU <==
  final bool isEditable;

  const TaskLogTile({
    super.key,
    required this.task,
    this.isEditable = false, // Nilai default
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeLogProvider>(context, listen: false);
    final theme = Theme.of(context);
    final hours = (task.durationMinutes / 60).floor();
    final minutes = task.durationMinutes % 60;
    final durationString =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(
          task.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Total Durasi: $durationString jam'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${task.durationMinutes} mnt',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // ==> Nonaktifkan tombol jika tidak bisa diedit <==
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: isEditable
                  ? () => provider.incrementDuration(task)
                  : null,
              tooltip: 'Tambah 30 menit',
            ),
            // ==> Sembunyikan menu jika tidak bisa diedit <==
            if (isEditable)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    showEditDurationDialog(context, task);
                  } else if (value == 'delete') {
                    provider.deleteTask(task);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Ubah Durasi'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
