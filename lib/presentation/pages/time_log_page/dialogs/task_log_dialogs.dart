// lib/presentation/pages/time_log_page/dialogs/task_log_dialogs.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/time_log_model.dart';
import 'package:my_aplication/presentation/providers/time_log_provider.dart';
import 'package:provider/provider.dart';

void showAddTaskLogDialog(BuildContext context) {
  final provider = Provider.of<TimeLogProvider>(context, listen: false);
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tambah Tugas Baru'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nama Tugas'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              provider.addTask(controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

void showEditDurationDialog(BuildContext context, LoggedTask task) {
  final provider = Provider.of<TimeLogProvider>(context, listen: false);
  final controller = TextEditingController(
    text: task.durationMinutes.toString(),
  );
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Ubah Durasi: ${task.name}'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Durasi (menit)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            final newDuration = int.tryParse(controller.text);
            if (newDuration != null) {
              provider.updateDuration(task, newDuration);
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}
