// lib/presentation/widgets/point_edit_popup_menu.dart
import 'package:flutter/material.dart';

class PointEditPopupMenu extends StatelessWidget {
  final VoidCallback? onDateChange;
  final VoidCallback? onCodeChange;
  final VoidCallback? onRename;
  final VoidCallback? onMarkAsFinished;
  final VoidCallback? onReactivate;
  final VoidCallback? onDelete;
  final bool isFinished;

  const PointEditPopupMenu({
    super.key,
    this.onDateChange,
    this.onCodeChange,
    this.onRename,
    this.onMarkAsFinished,
    this.onReactivate,
    this.onDelete,
    this.isFinished = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'edit_date' && onDateChange != null) onDateChange!();
        if (value == 'edit_code' && onCodeChange != null) onCodeChange!();
        if (value == 'rename' && onRename != null) onRename!();
        if (value == 'finish' && onMarkAsFinished != null) onMarkAsFinished!();
        if (value == 'reactivate' && onReactivate != null) onReactivate!();
        if (value == 'delete' && onDelete != null) onDelete!();
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> menuItems = [];

        if (!isFinished) {
          if (onDateChange != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'edit_date',
                child: Text('Ubah Tanggal'),
              ),
            );
          }
          if (onCodeChange != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'edit_code',
                child: Text('Ubah Kode Repetisi'),
              ),
            );
          }
          if (onRename != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'rename',
                child: Text('Ubah Nama'),
              ),
            );
          }
        }

        menuItems.add(const PopupMenuDivider());

        if (!isFinished) {
          if (onMarkAsFinished != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'finish',
                child: Text('Tandai Selesai'),
              ),
            );
          }
        } else {
          if (onReactivate != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'reactivate',
                child: Text('Aktifkan Lagi'),
              ),
            );
          }
        }

        if (onDelete != null) {
          menuItems.add(const PopupMenuDivider());
          menuItems.add(
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          );
        }

        return menuItems;
      },
    );
  }
}
