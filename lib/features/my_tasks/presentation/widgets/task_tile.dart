// lib/features/my_tasks/presentation/widgets/task_tile.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:provider/provider.dart';
import '../dialogs/task_dialogs.dart';

class TaskTile extends StatelessWidget {
  final TaskCategory category;
  final MyTask task;
  final bool isParentHidden;

  const TaskTile({
    super.key,
    required this.category,
    required this.task,
    required this.isParentHidden,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context);
    final theme = Theme.of(context);
    final isCategoryReorderMode = provider.isCategoryReorderEnabled;

    final bool isSelected =
        provider.selectedTasks[category.name]?.contains(task.id) ?? false;
    final bool isSelectionMode = provider.isTaskSelectionMode;

    // ==> PERUBAHAN DI SINI <==
    final textColor = isParentHidden ? Colors.grey : null;

    return ListTile(
      key: key,
      onLongPress: () {
        if (!isCategoryReorderMode) {
          provider.toggleTaskSelection(category, task);
        }
      },
      onTap: () {
        if (isSelectionMode) {
          provider.toggleTaskSelection(category, task);
        }
      },
      // ==> PERUBAHAN PADA LEADING: GANTI CHECKBOX DENGAN TOMBOL TAMBAH <==
      leading: isSelectionMode
          ? Icon(
              isSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: theme.primaryColor,
            )
          : IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: theme.primaryColor,
              onPressed: isCategoryReorderMode || isParentHidden
                  ? null
                  : () async {
                      final confirmed =
                          await showIncrementCountConfirmationDialog(context);
                      if (confirmed == true) {
                        provider.incrementTaskCount(category, task);
                      }
                    },
            ),
      tileColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
      title: Text(
        task.name,
        style: TextStyle(
          // Hapus text-decoration
          color: textColor,
        ),
      ),
      // ==> PERUBAHAN SUBTITLE UNTUK MENAMPILKAN COUNT HARI INI <==
      subtitle: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textColor),
          children: [
            if (task.countToday > 0) ...[
              TextSpan(
                text: '+${task.countToday} hari ini',
                style: TextStyle(
                  color: isParentHidden ? textColor : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' | '),
            ],
            const TextSpan(text: 'Total: '),
            TextSpan(
              text: task.count.toString(),
              style: TextStyle(
                color: isParentHidden ? textColor : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: ' | Due: '),
            TextSpan(
              text: task.date,
              style: TextStyle(
                color: isParentHidden ? textColor : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      trailing: isCategoryReorderMode || isParentHidden || isSelectionMode
          ? null
          : PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') {
                  showRenameTaskDialog(context, category, task);
                } else if (value == 'edit_date') {
                  showUpdateDateDialog(context, category, task);
                } else if (value == 'edit_count') {
                  showUpdateCountDialog(context, category, task);
                } else if (value == 'delete') {
                  showDeleteTaskDialog(context, category, task);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
                const PopupMenuItem(
                  value: 'edit_date',
                  child: Text('Ubah Tanggal'),
                ),
                const PopupMenuItem(
                  value: 'edit_count',
                  child: Text('Ubah Jumlah Total'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
    );
  }
}
