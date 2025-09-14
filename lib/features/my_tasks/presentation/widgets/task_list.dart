// lib/presentation/pages/my_tasks_page/widgets/task_list.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:provider/provider.dart';
import 'task_tile.dart';

class TaskList extends StatelessWidget {
  final TaskCategory category;
  final bool isParentHidden;

  const TaskList({
    super.key,
    required this.category,
    required this.isParentHidden,
  });

  @override
  Widget build(BuildContext context) {
    // Hapus semua logika reordering dari sini
    return Column(
      children: category.tasks
          .map(
            (task) => TaskTile(
              // Pastikan key yang stabil tetap ada
              key: ValueKey(task.id),
              category: category,
              task: task,
              isParentHidden: isParentHidden,
            ),
          )
          .toList(),
    );
  }
}
