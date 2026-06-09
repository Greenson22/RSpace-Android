// lib/presentation/widgets/discussion_edit_popup_menu.dart
import 'package:flutter/material.dart';

class DiscussionEditPopupMenu extends StatelessWidget {
  final VoidCallback onAddPoint;
  final VoidCallback onRename;
  final VoidCallback onSetFilePath;
  final VoidCallback onGenerateHtml;
  final VoidCallback onEditFilePath;
  final VoidCallback onRemoveFilePath;
  final VoidCallback onMarkAsFinished;
  final VoidCallback onReactivate;
  final VoidCallback onDelete;
  final VoidCallback onCreateFile;
  final VoidCallback onDateChange;
  final VoidCallback onCodeChange;

  final bool isFinished;
  final bool hasPoints;
  final bool hasFilePath;
  final bool canCreateFile;

  // Properti tambahan untuk warna tema utama agar serasi dengan Subject
  final Color themeColor;

  const DiscussionEditPopupMenu({
    super.key,
    required this.onAddPoint,
    required this.onRename,
    required this.onSetFilePath,
    required this.onGenerateHtml,
    required this.onEditFilePath,
    required this.onRemoveFilePath,
    required this.onMarkAsFinished,
    required this.onReactivate,
    required this.onDelete,
    required this.onCreateFile,
    required this.onDateChange,
    required this.onCodeChange,
    this.isFinished = false,
    this.hasPoints = false,
    this.hasFilePath = false,
    this.canCreateFile = false,
    required this.themeColor, // Wajib diisi untuk keselarasan tema warna
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double basePopupIconSize = 18.0;
    final scaledPopupIconSize = basePopupIconSize * textScaleFactor;

    return Theme(
      data: theme.copyWith(
        popupMenuTheme: theme.popupMenuTheme.copyWith(
          textStyle: TextStyle(color: themeColor, fontSize: 14),
        ),
        iconTheme: theme.iconTheme.copyWith(color: themeColor),
      ),
      child: PopupMenuButton<String>(
        iconSize: scaledPopupIconSize,
        icon: Icon(
          Icons.more_vert,
          color:
              theme.iconTheme.color?.withOpacity(0.7) ??
              themeColor.withOpacity(0.7),
        ),
        padding: const EdgeInsets.all(12.0),
        // MENYAMAKAN LEBAR MAKSIMAL kontainer popup menu sesuai standar Subject
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
        onSelected: (value) {
          if (value == 'add_point') onAddPoint();
          if (value == 'rename') onRename();
          if (value == 'set_file_path') onSetFilePath();
          if (value == 'generate_html') onGenerateHtml();
          if (value == 'edit_file_path') onEditFilePath();
          if (value == 'remove_file_path') onRemoveFilePath();
          if (value == 'finish') onMarkAsFinished();
          if (value == 'reactivate') onReactivate();
          if (value == 'delete') onDelete();
          if (value == 'edit_date') onDateChange();
          if (value == 'edit_code') onCodeChange();
          if (value == 'create_file') onCreateFile();
        },
        itemBuilder: (BuildContext context) {
          final List<PopupMenuEntry<String>> menuItems = [];

          if (!isFinished) {
            menuItems.add(
              _buildMenuItem(
                'add_point',
                Icons.add_comment_outlined,
                'Tambah Poin',
              ),
            );

            menuItems.add(const PopupMenuDivider(height: 8));

            if (canCreateFile && !hasFilePath) {
              menuItems.add(
                _buildMenuItem(
                  'create_file',
                  Icons.note_add_outlined,
                  'Buat File HTML',
                ),
              );
            }

            menuItems.add(
              _buildMenuItem(
                'set_file_path',
                hasFilePath
                    ? Icons.folder_open_outlined
                    : Icons.create_new_folder_outlined,
                hasFilePath ? 'Ubah Path File' : 'Set Path File',
              ),
            );

            if (hasFilePath) {
              menuItems.add(
                _buildMenuItem(
                  'generate_html',
                  Icons.auto_awesome_outlined,
                  'Generate Content (AI)',
                ),
              );
              menuItems.add(
                _buildMenuItem(
                  'edit_file_path',
                  Icons.edit_document,
                  'Edit File Konten',
                ),
              );
              menuItems.add(
                _buildMenuItem(
                  'remove_file_path',
                  Icons.link_off,
                  'Hapus Path File',
                  color: Colors.orange,
                ),
              );
            }
            menuItems.add(const PopupMenuDivider(height: 8));
          }

          menuItems.add(
            _buildMenuItem(
              'rename',
              Icons.drive_file_rename_outline,
              'Ubah Nama',
            ),
          );

          if (!hasPoints) {
            menuItems.add(
              _buildMenuItem(
                'edit_date',
                Icons.calendar_today_outlined,
                'Ubah Tanggal',
              ),
            );
            menuItems.add(
              _buildMenuItem('edit_code', Icons.code, 'Ubah Kode Repetisi'),
            );
          }

          menuItems.add(const PopupMenuDivider(height: 8));
          if (!isFinished) {
            menuItems.add(
              _buildMenuItem(
                'finish',
                Icons.check_circle_outline,
                'Tandai Selesai',
              ),
            );
          } else {
            menuItems.add(
              _buildMenuItem('reactivate', Icons.replay, 'Aktifkan Lagi'),
            );
          }

          menuItems.add(const PopupMenuDivider(height: 8));
          menuItems.add(
            _buildMenuItem(
              'delete',
              Icons.delete_outline,
              'Hapus',
              color: Colors.red,
            ),
          );

          return menuItems;
        },
      ),
    );
  }

  // Fungsi helper pembentuk item dengan tinggi 40, ukuran icon 20, dan ukuran font teks 14
  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}
