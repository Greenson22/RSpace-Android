// lib/presentation/pages/1_topics_page/widgets/topic_list_tile.dart
import 'package:flutter/material.dart';
import '../../../../data/models/topic_model.dart';

class TopicListTile extends StatelessWidget {
  final Topic topic;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final VoidCallback onToggleVisibility;
  final bool isReorderActive;
  final bool isLinux;
  final bool isCompact;
  final bool isSelected; // ==> DITAMBAHKAN

  const TopicListTile({
    super.key,
    required this.topic,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    required this.onToggleVisibility,
    this.isReorderActive = false,
    this.isLinux = false,
    this.isCompact = false,
    this.isSelected = false, // ==> DITAMBAHKAN
  });

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final bool isHidden = topic.isHidden;

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
      if (value == null) return;
      if (value == 'rename') onRename();
      if (value == 'change_icon') onIconChange();
      if (value == 'toggle_visibility') onToggleVisibility();
      if (value == 'delete') onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isHidden = topic.isHidden;
    // ==> LOGIKA WARNA DIPERBARUI <==
    Color cardColor;
    if (isSelected) {
      cardColor = theme.primaryColor.withOpacity(0.3);
    } else if (isHidden) {
      cardColor = theme.disabledColor.withOpacity(0.1);
    } else {
      cardColor = theme.cardColor;
    }
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final double elevation = isHidden ? 1 : 3;

    final double verticalMargin = isLinux ? 4 : 8;
    final double horizontalMargin = isLinux ? 8 : 16;

    final EdgeInsets padding = isCompact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : (isLinux
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 16));
    final double iconFontSize = isCompact ? 20 : (isLinux ? 22 : 28);
    final double titleFontSize = isCompact ? 14 : (isLinux ? 15 : 18);

    final tileContent = Material(
      borderRadius: BorderRadius.circular(isLinux ? 10 : 15),
      color: Colors.transparent,
      child: InkWell(
        onTap: isReorderActive ? null : onTap,
        borderRadius: BorderRadius.circular(isLinux ? 10 : 15),
        splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              if (!isCompact)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    topic.icon,
                    style: TextStyle(fontSize: iconFontSize, color: textColor),
                  ),
                ),
              if (!isCompact) const SizedBox(width: 12),
              // *** PERBAIKAN DI SINI ***
              Expanded(
                child: Text(
                  topic.name,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isReorderActive)
                ReorderableDragStartListener(
                  index: 0,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.drag_handle),
                  ),
                )
              else if (!isLinux)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'rename') onRename();
                    if (value == 'change_icon') onIconChange();
                    if (value == 'toggle_visibility') onToggleVisibility();
                    if (value == 'delete') onDelete();
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
                ),
            ],
          ),
        ),
      ),
    );

    return Card(
      elevation: elevation,
      color: cardColor,
      margin: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: verticalMargin,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isLinux ? 10 : 15),
      ),
      child: isLinux
          ? GestureDetector(
              onSecondaryTapUp: (details) {
                _showContextMenu(context, details.globalPosition);
              },
              child: tileContent,
            )
          : tileContent,
    );
  }
}
