// lib/presentation/pages/my_tasks_page/widgets/category_card.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:provider/provider.dart';
import '../dialogs/category_dialogs.dart';
import '../dialogs/task_dialogs.dart';
import 'task_list.dart';

class CategoryCard extends StatelessWidget {
  final TaskCategory category;
  final bool isFocused;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const CategoryCard({
    super.key,
    required this.category,
    this.isFocused = false,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context);
    final theme = Theme.of(context);
    final isHidden = category.isHidden;
    final isCategoryReorderMode = provider.isCategoryReorderEnabled;
    final isCardDisabled = isCategoryReorderMode;

    final selectedInCategory = provider.selectedTasks[category.name] ?? {};
    final areAllTasksSelected =
        selectedInCategory.length == category.tasks.length &&
        category.tasks.isNotEmpty;

    final Color cardColor = isHidden
        ? theme.disabledColor.withOpacity(0.1)
        : (isCardDisabled
              ? theme.disabledColor.withOpacity(0.1)
              : theme.cardColor);
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final double elevation = isHidden ? 1 : 3;

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isFocused
            ? BorderSide(color: theme.primaryColor, width: 2.5)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        key: PageStorageKey(category.name),
        initiallyExpanded: isExpanded,
        // ## PERBAIKAN DI SINI: Nonaktifkan callback saat mode reorder ##
        onExpansionChanged: isCardDisabled ? null : onExpansionChanged,
        enabled: !isCategoryReorderMode,
        leading: provider.isTaskSelectionMode
            ? Checkbox(
                value: areAllTasksSelected,
                tristate: selectedInCategory.isNotEmpty && !areAllTasksSelected,
                onChanged: (bool? value) {
                  provider.selectAllTasksInCategory(category, value ?? false);
                },
              )
            : Text(
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
        trailing: isCategoryReorderMode
            ? ReorderableDragStartListener(
                index: provider.categories.indexOf(category),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.drag_handle),
                ),
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
                    showReorderTasksDialog(context, category);
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
        children: provider.isCategoryReorderEnabled
            ? []
            : [TaskList(category: category, isParentHidden: isHidden)],
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
