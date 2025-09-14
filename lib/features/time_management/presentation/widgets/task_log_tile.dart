// lib/features/time_management/presentation/widgets/task_log_tile.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/time_management/domain/models/time_log_model.dart';
import 'package:my_aplication/features/time_management/presentation/dialogs/link_task_dialog.dart';
import 'package:my_aplication/features/time_management/application/providers/time_log_provider.dart';
import 'package:provider/provider.dart';
import '../dialogs/task_log_dialogs.dart';

class TaskLogTile extends StatelessWidget {
  final LoggedTask task;
  final bool isEditable;

  const TaskLogTile({super.key, required this.task, this.isEditable = false});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeLogProvider>(context, listen: false);
    final theme = Theme.of(context);
    final hours = (task.durationMinutes / 60).floor();
    final minutes = task.durationMinutes % 60;
    final durationString =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

    final hasLinkedTasks = task.linkedTaskIds.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: hasLinkedTasks
            ? Icon(Icons.link, color: theme.primaryColor)
            : null,
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
            // ==> PERUBAHAN DI SINI <==
            // Tombol menu sekarang hanya muncul jika TIDAK dalam mode reorder/edit.
            if (!isEditable)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'increment') {
                    provider.incrementDuration(task, updateLinkedTasks: true);
                  } else if (value == 'edit') {
                    showEditDurationDialog(context, task);
                  } else if (value == 'link') {
                    showLinkTaskDialog(context, task);
                  } else if (value == 'delete') {
                    provider.deleteTask(task);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'increment',
                    child: Text('Tambah 30 Menit & Update'),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Ubah Durasi'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'link',
                    child: Text(
                      hasLinkedTasks
                          ? 'Ubah Tugas Terhubung'
                          : 'Hubungkan ke My Tasks',
                    ),
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
