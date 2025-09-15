// lib/features/my_tasks/presentation/dialogs/task_list_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:provider/provider.dart';
import '../widgets/task_list.dart';
import 'task_dialogs.dart';

// Fungsi untuk menampilkan dialog
void showTaskListDialog(BuildContext context, TaskCategory category) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: TaskListDialog(category: category),
    ),
  );
}

class TaskListDialog extends StatelessWidget {
  final TaskCategory category;
  const TaskListDialog({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // Consumer diperlukan agar daftar tugas diperbarui secara real-time
    return Consumer<MyTaskProvider>(
      builder: (context, provider, child) {
        // Cari instance kategori terbaru dari provider
        final currentCategory = provider.categories.firstWhere(
          (c) => c.name == category.name,
          orElse: () => category, // Fallback jika kategori sudah dihapus
        );

        return AlertDialog(
          title: Text(currentCategory.name),
          content: SizedBox(
            width: double.maxFinite,
            // Jika tidak ada tugas, tampilkan pesan
            child: currentCategory.tasks.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text('Belum ada tugas di kategori ini.'),
                    ),
                  )
                // Jika ada tugas, tampilkan dalam list
                : SingleChildScrollView(
                    child: TaskList(
                      category: currentCategory,
                      isParentHidden: currentCategory.isHidden,
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tambah Tugas'),
              onPressed: () => showAddTaskDialog(context, currentCategory),
            ),
          ],
        );
      },
    );
  }
}
