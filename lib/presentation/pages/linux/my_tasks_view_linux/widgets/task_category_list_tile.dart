// lib/presentation/pages/linux/my_tasks_view_linux/widgets/task_category_list_tile.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';

class TaskCategoryListTile extends StatelessWidget {
  final TaskCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final VoidCallback onToggleVisibility;

  const TaskCategoryListTile({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    required this.onToggleVisibility,
  });

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final bool isHidden = category.isHidden;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
        const PopupMenuItem(value: 'change_icon', child: Text('Ubah Ikon')),
        PopupMenuItem<String>(
          value: 'toggle_visibility',
          child: Text(isHidden ? 'Tampilkan' : 'Sembunyikan'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
      ],
    ).then((value) {
      if (value == 'rename') onRename();
      if (value == 'change_icon') onIconChange();
      if (value == 'toggle_visibility') onToggleVisibility();
      if (value == 'delete') onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHidden = category.isHidden;
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final Color? tileColor = isSelected
        ? theme.primaryColor.withOpacity(0.1)
        : (isHidden ? theme.disabledColor.withOpacity(0.05) : null);

    final tileContent = ListTile(
      leading: Text(
        category.icon,
        style: TextStyle(
          fontSize: 24,
          color: isHidden ? textColor : theme.primaryColor,
        ),
      ),
      title: Text(
        category.name,
        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      tileColor: tileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          _showContextMenu(context, details.globalPosition);
        },
        child: tileContent,
      ),
    );
  }
}
