// lib/presentation/pages/1_topics_page/widgets/topic_grid_tile.dart
import 'package:flutter/material.dart';
import '../../../../data/models/topic_model.dart';

class TopicGridTile extends StatelessWidget {
  final Topic topic;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final VoidCallback onToggleVisibility;
  final bool isFocused;

  const TopicGridTile({
    super.key,
    required this.topic,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    required this.onToggleVisibility,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isHidden = topic.isHidden;
    final Color cardColor = isHidden
        ? theme.disabledColor.withOpacity(0.1)
        : theme.cardColor;
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final double elevation = isHidden ? 1 : 3;

    final tileContent = Material(
      borderRadius: BorderRadius.circular(15),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                topic.icon,
                style: TextStyle(fontSize: 40, color: textColor),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  topic.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'rename') onRename();
                    if (value == 'change_icon') onIconChange();
                    if (value == 'toggle_visibility') onToggleVisibility();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('Ubah Nama'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'change_icon',
                      child: Row(
                        children: [
                          Icon(Icons.emoji_emotions_outlined),
                          SizedBox(width: 8),
                          Text('Ubah Ikon'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'toggle_visibility',
                      child: Row(
                        children: [
                          Icon(
                            isHidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          const SizedBox(width: 8),
                          Text(isHidden ? 'Tampilkan' : 'Sembunyikan'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Card(
      elevation: elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isFocused
            ? BorderSide(color: theme.primaryColor, width: 2.5)
            : BorderSide.none,
      ),
      child: tileContent,
    );
  }
}
