// lib/features/progress/presentation/widgets/progress_topic_grid_tile.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/progress/domain/models/progress_topic_model.dart';

class ProgressTopicGridTile extends StatelessWidget {
  final ProgressTopic topic;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; // Tambahan onLongPress
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final VoidCallback onHide;

  // ==> Properti Baru untuk Multi-select
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const ProgressTopicGridTile({
    super.key,
    required this.topic,
    required this.onTap,
    this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.onIconChange,
    required this.onHide,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: topic.isHidden
          ? theme.cardColor.withOpacity(0.6)
          : theme.cardColor,
      // Beri border jika item dipilih
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 3.0)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isSelectionMode ? onSelect : onTap,
        onLongPress: onLongPress, // Trigger selection mode
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    topic.icon,
                    style: TextStyle(
                      fontSize: 40,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    topic.topics,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: topic.isHidden
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Tampilan Popup Menu (Disembunyikan saat mode select)
            if (!isSelectionMode)
              Positioned(
                top: 4,
                right: 4,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: PopupMenuButton<String>(
                    iconSize: 18,
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      } else if (value == 'icon') {
                        onIconChange();
                      } else if (value == 'hide') {
                        onHide();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit Nama'),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'icon',
                            child: ListTile(
                              leading: Icon(Icons.emoji_emotions_outlined),
                              title: Text('Ubah Ikon'),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'hide',
                            child: ListTile(
                              leading: Icon(
                                topic.isHidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              title: Text(
                                topic.isHidden ? 'Tampilkan' : 'Sembunyikan',
                              ),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              title: Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                  ),
                ),
              ),

            // Tampilan Checkbox saat mode select
            if (isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor
                        : Colors.grey.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                ),
              ),

            // Indikator visual hidden
            if (topic.isHidden && !isSelectionMode)
              Positioned(
                top: 8,
                left: 8,
                child: Icon(
                  Icons.visibility_off,
                  size: 16,
                  color: theme.disabledColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
