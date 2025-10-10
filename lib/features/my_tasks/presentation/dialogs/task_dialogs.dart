// lib/features/my_tasks/presentation/dialogs/task_dialogs.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:provider/provider.dart';
import '../../../content_management/presentation/topics/dialogs/topic_dialogs.dart';

void showReorderTasksDialog(BuildContext context, TaskCategory category) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (dialogContext) => ChangeNotifierProvider.value(
      value: provider,
      child: _ReorderTasksDialog(category: category),
    ),
  );
}

class _ReorderTasksDialog extends StatefulWidget {
  final TaskCategory category;

  const _ReorderTasksDialog({required this.category});

  @override
  State<_ReorderTasksDialog> createState() => _ReorderTasksDialogState();
}

class _ReorderTasksDialogState extends State<_ReorderTasksDialog> {
  late List<MyTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List<MyTask>.from(widget.category.tasks);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);

    return AlertDialog(
      title: Text('Urutkan Task di "${widget.category.name}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return Card(
              key: ValueKey(task.id),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(task.name),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = _tasks.removeAt(oldIndex);
              _tasks.insert(newIndex, item);
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            provider.updateTasksOrder(widget.category, _tasks);
            Navigator.pop(context);
          },
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}

void showAddTaskDialog(BuildContext context, TaskCategory category) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showTopicTextInputDialog(
    context: context,
    title: 'Tambah Task Baru',
    label: 'Nama Task',
    onSave: (name) {
      provider.addTask(category, name);
      _showSnackBar(context, 'Task "$name" berhasil ditambahkan.');
    },
  );
}

void showRenameTaskDialog(
  BuildContext context,
  TaskCategory category,
  MyTask task,
) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showTopicTextInputDialog(
    context: context,
    title: 'Ubah Nama Task',
    label: 'Nama Baru',
    initialValue: task.name,
    onSave: (newName) {
      provider.renameTask(category, task, newName);
      _showSnackBar(context, 'Task diubah menjadi "$newName".');
    },
  );
}

void showDeleteTaskDialog(
  BuildContext context,
  TaskCategory category,
  MyTask task,
) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
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
            _showSnackBar(context, 'Task "${task.name}" berhasil dihapus.');
          },
        ),
      ],
    ),
  );
}

Future<void> showUpdateDateDialog(
  BuildContext context,
  TaskCategory category,
  MyTask task,
) async {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  final initialDate = DateTime.tryParse(task.date) ?? DateTime.now();
  final newDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );

  if (newDate != null) {
    provider.updateTaskDate(category, task, newDate);
    _showSnackBar(context, 'Tanggal task berhasil diubah.');
  }
}

void showUpdateCountDialog(
  BuildContext context,
  TaskCategory category,
  MyTask task,
) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showTopicTextInputDialog(
    context: context,
    title: 'Ubah Jumlah Total (Count)',
    label: 'Jumlah Baru',
    initialValue: task.count.toString(),
    keyboardType: TextInputType.number,
    onSave: (newValue) {
      final newCount = int.tryParse(newValue);
      if (newCount != null) {
        provider.updateTaskCount(category, task, newCount);
        _showSnackBar(context, 'Jumlah total task berhasil diubah.');
      } else {
        _showSnackBar(
          context,
          'Input tidak valid. Harap masukkan angka.',
          isError: true,
        );
      }
    },
  );
}

// ==> FUNGSI BARU UNTUK DIALOG TARGET HARIAN <==
void showUpdateTargetCountDialog(
  BuildContext context,
  TaskCategory category,
  MyTask task,
) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showTopicTextInputDialog(
    context: context,
    title: 'Atur Target Harian',
    label: 'Target Jumlah Harian (0 = tanpa target)',
    initialValue: task.targetCountToday.toString(),
    keyboardType: TextInputType.number,
    onSave: (newValue) {
      final newCount = int.tryParse(newValue);
      if (newCount != null) {
        provider.updateTaskTargetCount(category, task, newCount);
        _showSnackBar(context, 'Target harian berhasil diubah.');
      } else {
        _showSnackBar(
          context,
          'Input tidak valid. Harap masukkan angka.',
          isError: true,
        );
      }
    },
  );
}

Future<bool?> showIncrementCountConfirmationDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Konfirmasi'),
      content: const Text(
        'Tambah hitungan hari ini dan total hitungan sebanyak 1? Tanggal "due" juga akan diperbarui ke hari ini.',
      ),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          child: const Text('Ya, Tambah'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
}

void _showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
    ),
  );
}
