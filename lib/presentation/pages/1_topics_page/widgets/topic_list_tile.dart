import 'package:flutter/material.dart';
import '../../../../data/models/topic_model.dart';

class TopicListTile extends StatelessWidget {
  final Topic topic;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final VoidCallback onToggleVisibility; // ==> DITAMBAHKAN
  final bool isReorderActive;

  const TopicListTile({
    super.key,
    required this.topic,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    required this.onToggleVisibility, // ==> DITAMBAHKAN
    this.isReorderActive = false,
  });

  @override
  Widget build(BuildContext context) {
    // ==> PERUBAHAN Tampilan untuk item yang tersembunyi <==
    final bool isHidden = topic.isHidden;
    final Color cardColor = isHidden
        ? Theme.of(context).disabledColor.withOpacity(0.1)
        : Theme.of(context).cardColor;
    final Color? textColor = isHidden ? Theme.of(context).disabledColor : null;
    final double elevation = isHidden ? 1 : 3;

    return Card(
      elevation: elevation, // DIUBAH
      color: cardColor, // DIUBAH
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        color: Colors.transparent, // DIUBAH
        child: InkWell(
          onTap: isReorderActive ? null : onTap,
          borderRadius: BorderRadius.circular(15),
          splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
          highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    topic.icon,
                    style: TextStyle(fontSize: 28, color: textColor), // DIUBAH
                  ),
                ),
                const SizedBox(width: 16),
                // Topic Name
                Expanded(
                  child: Text(
                    topic.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor, // DIUBAH
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Reorder Handle or Popup Menu
                if (isReorderActive)
                  ReorderableDragStartListener(
                    index:
                        0, // Indeks ini akan di-handle oleh ReorderableListView
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.drag_handle),
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') onRename();
                      if (value == 'change_icon') onIconChange();
                      if (value == 'toggle_visibility')
                        onToggleVisibility(); // DIUBAH
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
                      // ==> OPSI MENU BARU <==
                      PopupMenuItem<String>(
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
          ),
        ),
      ),
    );
  }
}
