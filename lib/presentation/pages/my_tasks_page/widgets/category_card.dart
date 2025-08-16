// lib/presentation/pages/my_tasks_page/widgets/category_card.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:my_aplication/presentation/providers/my_task_provider.dart';
import 'package:provider/provider.dart';
import '../dialogs/category_dialogs.dart';
import '../dialogs/task_dialogs.dart';
import 'task_list.dart';

class CategoryCard extends StatelessWidget {
  final TaskCategory category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context);
    final theme = Theme.of(context);
    final isHidden = category.isHidden;
    final isThisCategoryReorderingTask =
        provider.reorderingCategoryName == category.name;
    final isCategoryReorderMode = provider.isCategoryReorderEnabled;
    final isAnotherTaskReordering =
        provider.reorderingCategoryName != null &&
        !isThisCategoryReorderingTask;
    final isCardDisabled = isCategoryReorderMode || isAnotherTaskReordering;

    final Color cardColor = isHidden
        ? theme.disabledColor.withOpacity(0.1)
        : (isAnotherTaskReordering
              ? theme.disabledColor.withOpacity(0.1)
              : theme.cardColor);
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final double elevation = isHidden ? 1 : 3;

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: elevation,
      color: cardColor,
      child: ExpansionTile(
        enabled: !isCategoryReorderMode,
        initiallyExpanded: isThisCategoryReorderingTask,
        leading: Text(
          category.icon,
          style: TextStyle(
            fontSize: 28,
            color: isHidden ? textColor : theme.primaryColor,
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
        trailing: isThisCategoryReorderingTask
            ? TextButton.icon(
                icon: const Icon(Icons.done),
                label: const Text('Selesai'),
                onPressed: () => provider.disableReordering(),
              )
            : PopupMenuButton<String>(
                enabled: !isCardDisabled,
                onSelected: (value) {
                  if (value == 'rename') {
                    showRenameCategoryDialog(context, category);
                  } else if (value == 'change_icon') {
                    showIconPickerDialog(context, category);
                  } else if (value == 'toggle_visibility') {
                    _toggleVisibility(context, category);
                  } else if (value == 'delete') {
                    showDeleteCategoryDialog(context, category);
                  } else if (value == 'add_task') {
                    showAddTaskDialog(context, category);
                  } else if (value == 'reorder_tasks') {
                    provider.enableTaskReordering(category.name);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_task',
                    child: Text('Tambah Task'),
                  ),
                  const PopupMenuItem(
                    value: 'reorder_tasks',
                    child: Text('Urutkan Task'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Ubah Nama'),
                  ),
                  const PopupMenuItem(
                    value: 'change_icon',
                    child: Text('Ubah Ikon'),
                  ),
                  PopupMenuItem(
                    value: 'toggle_visibility',
                    child: Text(isHidden ? 'Tampilkan' : 'Sembunyikan'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
        children: [
          TaskList(
            category: category,
            isReordering: isThisCategoryReorderingTask,
            isParentHidden: isHidden,
          ),
        ],
      ),
    );
  }

  void _toggleVisibility(BuildContext context, TaskCategory category) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    provider.toggleCategoryVisibility(category);
    final message = category.isHidden ? 'ditampilkan kembali' : 'disembunyikan';
    _showSnackBar(context, 'Kategori "${category.name}" berhasil $message.');
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
}
