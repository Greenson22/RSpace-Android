// lib/presentation/pages/my_tasks_page/dialogs/task_dialogs.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:provider/provider.dart';
import '../../../content_management/presentation/topics/dialogs/topic_dialogs.dart';

// FUNGSI BARU UNTUK MENAMPILKAN DIALOG PENGURUTAN
void showReorderTasksDialog(BuildContext context, TaskCategory category) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);

  showDialog(
    context: context,
    // Pastikan provider di-pass ke dalam konteks dialog
    builder: (dialogContext) => ChangeNotifierProvider.value(
      value: provider,
      child: _ReorderTasksDialog(category: category),
    ),
  );
}

// WIDGET BARU UNTUK DIALOG PENGURUTAN
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
    // Buat salinan list agar bisa diubah urutannya di dalam state dialog
    _tasks = List<MyTask>.from(widget.category.tasks);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);

    return AlertDialog(
      title: Text('Urutkan Task di "${widget.category.name}"'),
      content: SizedBox(
        width: double.maxFinite, // Agar dialog melebar
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
            // Panggil provider untuk menyimpan urutan baru
            provider.updateTasksOrder(widget.category, _tasks);
            Navigator.pop(context);
          },
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}

// --- KODE LAMA DI BAWAH INI TIDAK BERUBAH ---

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
    title: 'Ubah Jumlah (Count)',
    label: 'Jumlah Baru',
    initialValue: task.count.toString(),
    keyboardType: TextInputType.number,
    onSave: (newValue) {
      final newCount = int.tryParse(newValue);
      if (newCount != null) {
        provider.updateTaskCount(category, task, newCount);
        _showSnackBar(context, 'Jumlah task berhasil diubah.');
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

Future<bool?> showToggleConfirmationDialog(BuildContext context) async {
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

void showUncheckAllConfirmationDialog(BuildContext context) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Konfirmasi'),
      content: const Text(
        'Anda yakin ingin menghapus semua centang dari task?',
      ),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
        TextButton(
          child: const Text('Ya, Hapus'),
          onPressed: () {
            provider.uncheckAllTasks();
            Navigator.of(dialogContext).pop();
            _showSnackBar(context, 'Semua centang telah dihapus.');
          },
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
