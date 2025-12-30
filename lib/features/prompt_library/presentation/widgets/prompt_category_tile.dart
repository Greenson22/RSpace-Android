import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/icon_picker_dialog.dart';
import '../../application/prompt_provider.dart';
import 'prompt_dialogs.dart';

class PromptCategoryTile extends StatelessWidget {
  final String title;
  final String originalName;
  final Color color;
  final bool isHidden;
  final String? customIcon;
  final VoidCallback onTap;

  const PromptCategoryTile({
    super.key,
    required this.title,
    required this.originalName,
    required this.color,
    required this.isHidden,
    required this.customIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<PromptProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: customIcon != null
              ? Text(customIcon!, style: const TextStyle(fontSize: 24))
              : Icon(
                  isHidden ? Icons.visibility_off : Icons.folder_copy_rounded,
                  color: color,
                  size: 24,
                ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHidden ? Colors.grey : theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildPopupMenu(context, provider),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, PromptProvider provider) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onSelected: (value) async {
        if (value == 'edit') {
          showRenameCategoryDialog(context, originalName);
        } else if (value == 'change_icon') {
          await showIconPickerDialog(
            context: context,
            name: title,
            onIconSelected: (newIcon) {
              provider.updateCategoryIcon(originalName, newIcon);
            },
          );
        } else if (value == 'delete') {
          _showDeleteDialog(context, provider);
        } else if (value == 'hide') {
          provider.hideCategory(originalName);
        } else if (value == 'unhide') {
          provider.unhideCategory(originalName);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Ubah Nama'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'change_icon',
          child: Row(
            children: [
              Icon(Icons.emoji_emotions_outlined, size: 20),
              SizedBox(width: 8),
              Text('Ubah Ikon'),
            ],
          ),
        ),
        PopupMenuItem(
          value: isHidden ? 'unhide' : 'hide',
          child: Row(
            children: [
              Icon(
                isHidden ? Icons.visibility : Icons.visibility_off,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(isHidden ? 'Tampilkan' : 'Sembunyikan'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Hapus', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, PromptProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Topik'),
        content: Text(
          'Hapus topik "$title" dan SEMUA prompt di dalamnya?\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteCategory(originalName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Topik berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal hapus: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
