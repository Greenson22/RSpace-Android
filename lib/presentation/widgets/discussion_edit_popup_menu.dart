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
  final VoidCallback onDateChange;
  final VoidCallback onCodeChange;

  final bool isFinished;
  final bool hasPoints;
  final bool hasFilePath;

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
    required this.onDateChange,
    required this.onCodeChange,
    this.isFinished = false,
    this.hasPoints = false,
    this.hasFilePath = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
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
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> menuItems = [];

        if (!isFinished) {
          menuItems.add(
            const PopupMenuItem<String>(
              value: 'add_point',
              child: Text('Tambah Poin'),
            ),
          );

          menuItems.add(const PopupMenuDivider());
          menuItems.add(
            PopupMenuItem<String>(
              value: 'set_file_path',
              child: Text(hasFilePath ? 'Ubah Path File' : 'Set Path File'),
            ),
          );
          if (hasFilePath) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'generate_html',
                child: Text('Generate Content with AI'),
              ),
            );
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'edit_file_path',
                child: Text('Edit File Konten'),
              ),
            );
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'remove_file_path',
                child: Text(
                  'Hapus Path File',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            );
          }
          menuItems.add(const PopupMenuDivider());
        }

        menuItems.add(
          const PopupMenuItem<String>(
            value: 'rename',
            child: Text('Ubah Nama'),
          ),
        );

        if (!hasPoints) {
          menuItems.add(
            const PopupMenuItem<String>(
              value: 'edit_date',
              child: Text('Ubah Tanggal'),
            ),
          );
          menuItems.add(
            const PopupMenuItem<String>(
              value: 'edit_code',
              child: Text('Ubah Kode Repetisi'),
            ),
          );
        }

        menuItems.add(const PopupMenuDivider());
        if (!isFinished) {
          menuItems.add(
            const PopupMenuItem<String>(
              value: 'finish',
              child: Text('Tandai Selesai'),
            ),
          );
        } else {
          menuItems.add(
            const PopupMenuItem<String>(
              value: 'reactivate',
              child: Text('Aktifkan Lagi'),
            ),
          );
        }

        menuItems.add(const PopupMenuDivider());
        menuItems.add(
          const PopupMenuItem<String>(
            value: 'delete',
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        );

        return menuItems;
      },
    );
  }
}
