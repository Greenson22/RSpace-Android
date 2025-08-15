// lib/presentation/pages/linux/my_tasks_view_linux/widgets/my_task_list_tile.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:my_aplication/presentation/pages/1_topics_page/dialogs/topic_dialogs.dart';
import 'package:my_aplication/presentation/providers/my_task_provider.dart';
import 'package:provider/provider.dart';

class MyTaskListTile extends StatelessWidget {
  final TaskCategory category;
  final MyTask task;
  final bool isReordering;

  const MyTaskListTile({
    super.key,
    required this.category,
    required this.task,
    this.isReordering = false,
  });

  void _showContextMenu(
    BuildContext context,
    Offset position,
    MyTaskProvider provider,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
        const PopupMenuItem(value: 'edit_date', child: Text('Ubah Tanggal')),
        const PopupMenuItem(value: 'edit_count', child: Text('Ubah Jumlah')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
      ],
    ).then((value) {
      if (value == 'rename') _showRenameTaskDialog(context, provider);
      if (value == 'edit_date') _showUpdateDateDialog(context, provider);
      if (value == 'edit_count') _showUpdateCountDialog(context, provider);
      if (value == 'delete') _showDeleteTaskDialog(context, provider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    final textColor = task.checked ? Colors.grey : null;

    final tileContent = ListTile(
      leading: isReordering
          ? Icon(Icons.drag_handle, color: textColor)
          : Checkbox(
              value: task.checked,
              onChanged: (bool? value) async {
                if (value == true) {
                  final shouldUpdate = await _showToggleConfirmationDialog(
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
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: ' | Count: '),
            TextSpan(
              text: task.count.toString(),
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    return GestureDetector(
      onSecondaryTapUp: (details) =>
          _showContextMenu(context, details.globalPosition, provider),
      child: tileContent,
    );
  }

  // --- Dialog Methods for Task ---
  Future<bool?> _showToggleConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penyelesaian'),
        content: const Text(
          'Update tanggal ke hari ini dan tambah jumlah (count) sebanyak 1?',
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Ya, Update'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  void _showRenameTaskDialog(BuildContext context, MyTaskProvider provider) {
    showTopicTextInputDialog(
      context: context,
      title: 'Ubah Nama Task',
      label: 'Nama Baru',
      initialValue: task.name,
      onSave: (newName) => provider.renameTask(category, task, newName),
    );
  }

  void _showDeleteTaskDialog(BuildContext context, MyTaskProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Task'),
        content: Text('Anda yakin ingin menghapus task "${task.name}"?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Hapus'),
            onPressed: () {
              provider.deleteTask(category, task);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateDateDialog(
    BuildContext context,
    MyTaskProvider provider,
  ) async {
    final initialDate = DateTime.tryParse(task.date) ?? DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (newDate != null) {
      provider.updateTaskDate(category, task, newDate);
    }
  }

  void _showUpdateCountDialog(BuildContext context, MyTaskProvider provider) {
    showTopicTextInputDialog(
      context: context,
      title: 'Ubah Jumlah (Count)',
      label: 'Jumlah Baru',
      initialValue: task.count.toString(),
      keyboardType: TextInputType.number,
      onSave: (newValue) {
        final newCount = int.tryParse(newValue);
        if (newCount != null) {
          provider.updateTaskCount(category, task, newCount);
        }
      },
    );
  }
}
