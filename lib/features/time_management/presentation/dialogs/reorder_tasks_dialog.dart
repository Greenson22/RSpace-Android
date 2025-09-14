// lib/features/time_management/presentation/dialogs/reorder_tasks_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/time_log_provider.dart';
import '../../domain/models/time_log_model.dart';

// Fungsi untuk menampilkan dialog
void showReorderTasksDialog(BuildContext context, TimeLogEntry log) {
  final provider = Provider.of<TimeLogProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: _ReorderTasksDialog(log: log),
    ),
  );
}

// Widget dialog
class _ReorderTasksDialog extends StatefulWidget {
  final TimeLogEntry log;

  const _ReorderTasksDialog({required this.log});

  @override
  State<_ReorderTasksDialog> createState() => _ReorderTasksDialogState();
}

class _ReorderTasksDialogState extends State<_ReorderTasksDialog> {
  late List<LoggedTask> _tasks;

  @override
  void initState() {
    super.initState();
    // Buat salinan list agar bisa diubah urutannya
    _tasks = List<LoggedTask>.from(widget.log.tasks);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeLogProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Urutkan Tugas Jurnal'),
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
            // ==> PERUBAHAN DI SINI <==
            // Panggil provider untuk menyimpan urutan baru
            provider.updateTasksOrder(widget.log, _tasks);
            Navigator.pop(context);
          },
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}
