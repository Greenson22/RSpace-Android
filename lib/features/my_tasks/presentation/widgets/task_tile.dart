// lib/presentation/pages/my_tasks_page/widgets/task_tile.dart
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

    // == LOGIKA BARU UNTUK UI SELEKSI ==
    final bool isSelected =
        provider.selectedTasks[category.name]?.contains(task.id) ?? false;
    final bool isSelectionMode = provider.isTaskSelectionMode;
    // --- AKHIR LOGIKA BARU ---

    final textColor = isParentHidden || task.checked ? Colors.grey : null;

    return ListTile(
      key: key,
      // == PERUBAHAN PADA onLongPress dan onTap ==
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
      // --- AKHIR PERUBAHAN ---
      // == PERUBAHAN PADA leading WIDGET ==
      leading: isSelectionMode
          ? Icon(
              isSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: theme.primaryColor,
            )
          : Checkbox(
              value: task.checked,
              onChanged: isCategoryReorderMode || isParentHidden
                  ? null
                  : (bool? value) async {
                      if (value == true) {
                        final shouldUpdate = await showToggleConfirmationDialog(
                          context,
                        );
                        if (shouldUpdate == true) {
                          provider.toggleTaskChecked(
                            category,
                            task,
                            confirmUpdate: true,
                          );
                        }
                      } else {
                        provider.toggleTaskChecked(
                          category,
                          task,
                          confirmUpdate: false,
                        );
                      }
                    },
            ),
      // --- AKHIR PERUBAHAN ---
      tileColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.checked ? TextDecoration.lineThrough : null,
          color: textColor,
        ),
      ),
      subtitle: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: textColor),
          children: [
            const TextSpan(text: 'Due: '),
            TextSpan(
              text: task.date,
              style: TextStyle(
                color: isParentHidden ? textColor : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: ' | Count: '),
            TextSpan(
              text: task.count.toString(),
              style: TextStyle(
                color: isParentHidden ? textColor : Colors.orange,
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
                  child: Text('Ubah Jumlah'),
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
