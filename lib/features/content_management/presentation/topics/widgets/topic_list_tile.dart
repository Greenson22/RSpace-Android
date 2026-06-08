// lib/features/content_management/presentation/topics/widgets/topic_list_tile.dart
import 'package:flutter/material.dart';
import '../../../domain/models/topic_model.dart';

class TopicListTile extends StatelessWidget {
  final Topic topic;
  final int index; // Ditambahkan: untuk mengetahui posisi item
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;
  final bool isReorderActive;
  final bool isFocused;

  const TopicListTile({
    super.key,
    required this.topic,
    required this.index, // Ditambahkan
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onToggleVisibility,
    this.isReorderActive = false,
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
    final double elevation = isHidden
        ? 1
        : 2; // Dikurangi sedikit agar lebih flat khas mobile

    // --- DIUBAH AGAR LEBIH KECIL (MOBILE FRIENDLY) ---
    final double verticalMargin = 4; // Sebelumnya: 8
    final double horizontalMargin = 8; // Sebelumnya: 16
    final EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8, // Sebelumnya: 16
    );
    final double iconFontSize = 20; // Sebelumnya: 28
    final double titleFontSize = 14; // Sebelumnya: 18
    // -------------------------------------------------

    final tileContent = Material(
      borderRadius: BorderRadius.circular(10), // Diperkecil dari 15
      color: Colors.transparent,
      child: InkWell(
        onTap: isReorderActive ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Diperkecil dari 8
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6), // Diperkecil dari 8
                ),
                child: Text(
                  topic.icon,
                  style: TextStyle(fontSize: iconFontSize, color: textColor),
                ),
              ),
              const SizedBox(width: 10), // Diperkecil dari 12
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
                  index: index, // Diperbarui: Menggunakan index yang benar
                  child: const Padding(
                    padding: EdgeInsets.all(6.0), // Diperkecil dari 8.0
                    child: Icon(
                      Icons.drag_handle,
                      size: 20,
                    ), // Diberi ukuran tetap yang lebih kecil
                  ),
                )
              else
                PopupMenuButton<String>(
                  iconSize: 20, // Tetap kecil secara visual
                  // DIUBAH: Berikan sedikit padding agar area sentuh pas ~44-48 dp (nyaman untuk jari)
                  padding: const EdgeInsets.all(12.0),
                  // DIUBAH: Hapus BoxConstraints() kosong agar mengembalikan ruang sentuh standar
                  onSelected: (value) {
                    if (value == 'rename') onRename();
                    if (value == 'toggle_visibility') onToggleVisibility();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      height:
                          40, // Ditambahkan: Sedikit lebih padat dari default (48), namun tetap aman disentuh
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Ubah Nama', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'change_icon',
                      height: 40, // Ditambahkan
                      child: Row(
                        children: [
                          Icon(Icons.emoji_emotions_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Ubah Ikon', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'toggle_visibility',
                      height: 40, // Ditambahkan
                      child: Row(
                        children: [
                          Icon(
                            isHidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isHidden ? 'Tampilkan' : 'Sembunyikan',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(
                      height: 8,
                    ), // Disesuaikan tingginya agar rapi
                    const PopupMenuItem(
                      value: 'delete',
                      height: 40, // Ditambahkan
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hapus',
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ],
                      ),
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
        borderRadius: BorderRadius.circular(
          10,
        ), // Menyeimbangkan dengan isi content
        side: isFocused
            ? BorderSide(
                color: theme.primaryColor,
                width: 2.0,
              ) // Diturunkan ketebalannya dari 2.5
            : BorderSide.none,
      ),
      child: tileContent,
    );
  }
}
