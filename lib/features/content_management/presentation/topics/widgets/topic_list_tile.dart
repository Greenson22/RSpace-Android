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

  // Metode pembantu untuk menghasilkan warna dinamis yang konsisten berdasarkan judul (hash)
  Color _getThemeColorFromTitle(String title) {
    if (title.isEmpty) return Colors.deepPurple;

    // Kumpulan palet warna menarik yang cocok untuk latar belakang/aksen tema
    final List<Color> themePalettes = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber.shade900,
      Colors.green.shade700,
      Colors.cyan.shade800,
      Colors.orange.shade800,
    ];

    final int hash = title.hashCode;
    final int index = hash.abs() % themePalettes.length;
    return themePalettes[index];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isHidden = topic.isHidden;

    // Mendapatkan warna utama berbasis judul satu kali untuk seluruh widget ini
    final Color mainThemeColor = _getThemeColorFromTitle(topic.name);
    final Color cardColor = isHidden
        ? theme.disabledColor.withOpacity(0.1)
        : theme.cardColor;
    final Color? textColor = isHidden ? theme.disabledColor : null;
    final double elevation = isHidden ? 1 : 2;

    // --- DIUBAH AGAR LEBIH KECIL (MOBILE FRIENDLY) ---
    final double verticalMargin = 4;
    final double horizontalMargin = 8;
    final EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8,
    );
    final double iconFontSize = 20;
    final double titleFontSize = 14;
    // -------------------------------------------------

    final tileContent = Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.transparent,
      child: InkWell(
        onTap: isReorderActive ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: mainThemeColor.withOpacity(0.1),
        highlightColor: mainThemeColor.withOpacity(0.05),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  // Menggunakan warna utama berbasis judul dengan opasitas rendah
                  color: isHidden
                      ? theme.disabledColor.withOpacity(0.1)
                      : mainThemeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  topic.icon,
                  style: TextStyle(fontSize: iconFontSize, color: textColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  topic.name,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: isHidden
                        ? textColor
                        : mainThemeColor, // Warna teks mengikuti judul jika aktif
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isReorderActive)
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.drag_handle,
                      size: 20,
                      color: isHidden ? textColor : mainThemeColor,
                    ),
                  ),
                )
              else
                Theme(
                  data: theme.copyWith(
                    // Mengubah teks menu opsi item menjadi warna tema
                    popupMenuTheme: theme.popupMenuTheme.copyWith(
                      textStyle: TextStyle(color: mainThemeColor, fontSize: 14),
                    ),
                    // Mengubah warna ikon default di dalam menu popup
                    iconTheme: theme.iconTheme.copyWith(color: mainThemeColor),
                  ),
                  child: PopupMenuButton<String>(
                    iconSize: 20,
                    icon: Icon(
                      Icons.more_vert,
                      color: isHidden
                          ? textColor
                          : mainThemeColor.withOpacity(0.7),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    onSelected: (value) {
                      if (value == 'rename') onRename();
                      if (value == 'toggle_visibility') onToggleVisibility();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        height: 40,
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
                        height: 40,
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
                        height: 40,
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
                      const PopupMenuDivider(height: 8),
                      const PopupMenuItem(
                        value: 'delete',
                        height: 40,
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
        borderRadius: BorderRadius.circular(10),
        side: isFocused
            ? BorderSide(
                color:
                    mainThemeColor, // Border fokus mengikuti warna judul dinamis
                width: 2.0,
              )
            : BorderSide.none,
      ),
      child: tileContent,
    );
  }
}
