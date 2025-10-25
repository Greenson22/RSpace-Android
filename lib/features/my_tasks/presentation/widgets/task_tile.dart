// lib/features/my_tasks/presentation/widgets/task_tile.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:provider/provider.dart';
import '../dialogs/task_dialogs.dart'; // Pastikan dialog baru diimpor

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

    final textColor = isParentHidden ? Colors.grey : null;

    final isProgressTask = task.type == TaskType.progress;
    final progressValue = task.progressPercentage; // Sekarang bisa > 1.0
    // Persentase teks akan otomatis menampilkan nilai > 100%
    final progressText = isProgressTask
        ? '${(progressValue * 100).toStringAsFixed(0)}%'
        : '';

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
        } else {
          // Selalu buka dialog edit saat di-tap (untuk simple & progress)
          showEditTaskDialog(context, category, task);
        }
      },
      leading: isSelectionMode
          ? Icon(
              isSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: theme.primaryColor,
            )
          : IconButton(
              icon: Icon(
                isProgressTask
                    ? Icons.add_chart_outlined
                    : Icons.add_circle_outline,
              ),
              color: theme.primaryColor,
              onPressed: isCategoryReorderMode || isParentHidden
                  ? null
                  : () async {
                      // **--- PERUBAHAN LOGIKA ICON BUTTON ---**
                      if (isProgressTask) {
                        // Untuk task progress, tampilkan konfirmasi tambah 1
                        final confirmed =
                            await showAddOneProgressConfirmationDialog(
                              context,
                              task.name,
                            );
                        if (confirmed == true) {
                          provider.addProgressCount(category, task, 1);
                        }
                      } else {
                        // Untuk task simple, konfirmasi increment count
                        final confirmed =
                            await showIncrementCountConfirmationDialog(context);
                        if (confirmed == true) {
                          provider.incrementTaskCount(category, task);
                        }
                      }
                      // **--- AKHIR PERUBAHAN ---**
                    },
              tooltip: isProgressTask
                  ? 'Tambah 1 Progress'
                  : 'Tambah Hitungan', // Update tooltip
            ),
      tileColor: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(task.name, style: TextStyle(color: textColor)),
          ),
          if (isProgressTask)
            Text(
              progressText, // Teks ini sekarang bisa > 100%
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isProgressTask)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
              child: LinearProgressIndicator(
                // **--- CLAMP DITAMBAHKAN DI SINI UNTUK VISUAL ---**
                value: progressValue.clamp(0.0, 1.0), // Clamp value for the bar
                backgroundColor: theme.primaryColor.withOpacity(0.2),
                minHeight: 6,
              ),
            ),
          RichText(
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: textColor, fontSize: 11),
              children: [
                if (task.countToday > 0 || task.targetCountToday > 0) ...[
                  TextSpan(
                    text: task.targetCountToday > 0
                        ? '+${task.countToday} / ${task.targetCountToday} hari ini'
                        : '+${task.countToday} hari ini',
                    style: TextStyle(
                      color: isParentHidden
                          ? textColor
                          : (task.targetCountToday > 0 &&
                                    task.countToday >= task.targetCountToday
                                ? Colors.green
                                : Colors.lightBlue),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' | '),
                ],
                if (isProgressTask) ...[
                  const TextSpan(text: 'Progress: '),
                  TextSpan(
                    text: '${task.count} / ${task.targetCount}',
                    style: TextStyle(
                      color: isParentHidden ? textColor : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  const TextSpan(text: 'Total: '),
                  TextSpan(
                    text: task.count.toString(),
                    style: TextStyle(
                      color: isParentHidden ? textColor : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
        ],
      ),
      trailing: isCategoryReorderMode || isParentHidden || isSelectionMode
          ? null
          : PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  showEditTaskDialog(context, category, task);
                } else if (value == 'delete') {
                  showDeleteTaskDialog(context, category, task);
                } else if (value == 'add_progress_manual') {
                  // Tambahkan opsi ini jika ingin tetap bisa input manual via menu
                  showAddProgressCountDialog(context, category, task);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Detail')),
                // Tambahkan opsi ini jika diperlukan
                if (isProgressTask)
                  const PopupMenuItem(
                    value: 'add_progress_manual',
                    child: Text('Input Progress Manual'),
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
