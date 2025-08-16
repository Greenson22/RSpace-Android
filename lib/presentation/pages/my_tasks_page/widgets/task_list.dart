// lib/presentation/pages/my_tasks_page/widgets/task_list.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:my_aplication/presentation/providers/my_task_provider.dart';
import 'package:provider/provider.dart';
import 'task_tile.dart';

class TaskList extends StatelessWidget {
  final TaskCategory category;
  final bool isReordering;
  final bool isParentHidden;

  const TaskList({
    super.key,
    required this.category,
    required this.isReordering,
    required this.isParentHidden,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);

    if (isReordering) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: category.tasks.length,
        buildDefaultDragHandles: true,
        itemBuilder: (context, index) {
          final task = category.tasks[index];
          return TaskTile(
            key: ValueKey(task),
            category: category,
            task: task,
            isReordering: isReordering,
            isParentHidden: isParentHidden,
          );
        },
        onReorder: (oldIndex, newIndex) {
          provider.reorderTasks(category, oldIndex, newIndex);
        },
      );
    } else {
      return Column(
        children: category.tasks
            .map(
              (task) => TaskTile(
                category: category,
                task: task,
                isReordering: isReordering,
                isParentHidden: isParentHidden,
              ),
            )
            .toList(),
      );
    }
  }
}
