// lib/features/my_tasks/presentation/widgets/category_grid_tile.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:provider/provider.dart';
import '../dialogs/category_dialogs.dart';
import '../dialogs/task_dialogs.dart';

class CategoryGridTile extends StatelessWidget {
  final TaskCategory category;
  final VoidCallback onTap;
  final bool isFocused;

  const CategoryGridTile({
    super.key,
    required this.category,
    required this.onTap,
    this.isFocused = false,
  });

  void _toggleVisibility(BuildContext context, TaskCategory category) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    provider.toggleCategoryVisibility(category);
    final message = category.isHidden ? 'ditampilkan kembali' : 'disembunyikan';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kategori "${category.name}" berhasil $message.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isHidden = category.isHidden;

    final Color cardColor = isHidden
        ? theme.disabledColor.withOpacity(0.1)
        : theme.cardColor;
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final double elevation = isHidden ? 1 : 3;

    final totalTasks = category.tasks.length;
    final pendingTasks = category.tasks.where((t) => !t.checked).length;

    return Card(
      elevation: elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isFocused
            ? BorderSide(color: theme.primaryColor, width: 2.5)
            : BorderSide.none,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          splashColor: theme.primaryColor.withOpacity(0.1),
          highlightColor: theme.primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        category.icon,
                        style: TextStyle(fontSize: 32, color: textColor),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'rename') {
                          showRenameCategoryDialog(context, category);
                        } else if (value == 'change_icon') {
                          showIconPickerDialog(context, category);
                        } else if (value == 'toggle_visibility') {
                          _toggleVisibility(context, category);
                        } else if (value == 'delete') {
                          showDeleteCategoryDialog(context, category);
                        }
                      },
                      itemBuilder: (context) => [
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
                          child: Text(
                            'Hapus',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '$pendingTasks dari $totalTasks tugas',
                  style: theme.textTheme.bodySmall?.copyWith(color: textColor),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
