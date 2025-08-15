// lib/presentation/pages/linux/my_tasks_view_linux/tasks_panel.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:my_aplication/presentation/pages/1_topics_page/dialogs/topic_dialogs.dart';
import 'package:my_aplication/presentation/providers/my_task_provider.dart';
import 'package:provider/provider.dart';
import 'widgets/my_task_list_tile.dart';

class TasksPanel extends StatefulWidget {
  final TaskCategory? selectedCategory;

  const TasksPanel({super.key, this.selectedCategory});

  @override
  State<TasksPanel> createState() => _TasksPanelState();
}

class _TasksPanelState extends State<TasksPanel> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context);

    if (widget.selectedCategory == null) {
      return const Center(child: Text('Pilih sebuah kategori dari panel kiri'));
    }

    // Find the latest version of the selected category from the provider
    final currentCategory = provider.categories.firstWhere(
      (c) => c.name == widget.selectedCategory!.name,
      orElse: () => widget.selectedCategory!,
    );

    return Column(
      children: [
        _buildToolbar(context, provider, currentCategory),
        const Divider(height: 1),
        Expanded(child: _buildTaskList(context, provider, currentCategory)),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
  ) {
    final bool isTaskReordering =
        provider.reorderingCategoryName == category.name;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isTaskReordering ? "Urutkan Task" : "Daftar Task",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(isTaskReordering ? Icons.check : Icons.sort),
            tooltip: isTaskReordering ? 'Selesai Mengurutkan' : 'Urutkan Task',
            onPressed: () {
              if (isTaskReordering) {
                provider.disableReordering();
              } else {
                provider.enableTaskReordering(category.name);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Tambah Task",
            onPressed: () => _showAddTaskDialog(context, provider, category),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
  ) {
    final bool isReordering = provider.reorderingCategoryName == category.name;
    final tasks = category.tasks;

    if (tasks.isEmpty) {
      return const Center(child: Text('Tidak ada task di kategori ini.'));
    }

    return ReorderableListView.builder(
      itemCount: tasks.length,
      buildDefaultDragHandles: isReordering,
      onReorder: (oldIndex, newIndex) {
        if (isReordering) {
          provider.reorderTasks(category, oldIndex, newIndex);
        }
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        return MyTaskListTile(
          key: ValueKey(task.name + task.date),
          category: category,
          task: task,
          isReordering: isReordering,
        );
      },
    );
  }

  // --- Dialog Methods ---
  void _showAddTaskDialog(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
  ) {
    showTopicTextInputDialog(
      context: context,
      title: 'Tambah Task Baru',
      label: 'Nama Task',
      onSave: (name) {
        provider.addTask(category, name);
      },
    );
  }
}
