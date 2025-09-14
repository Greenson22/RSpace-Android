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
  final bool isFocused; // Tambahkan properti isFocused
  final bool isExpanded; // Tambahkan properti isExpanded
  final ValueChanged<bool> onExpansionChanged; // Tambahkan callback

  const CategoryCard({
    super.key,
    required this.category,
    this.isFocused = false, // Beri nilai default
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
      // Tambahkan shape untuk menampilkan border saat fokus
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isFocused
            ? BorderSide(color: theme.primaryColor, width: 2.5)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        key: PageStorageKey(category.name), // Tambahkan key untuk menjaga state
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        enabled: !isCategoryReorderMode,
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
                    // PANGGIL DIALOG BARU
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
        children: [TaskList(category: category, isParentHidden: isHidden)],
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
