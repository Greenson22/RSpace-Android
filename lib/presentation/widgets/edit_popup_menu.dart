import 'package:flutter/material.dart';

class EditPopupMenu extends StatelessWidget {
  final VoidCallback onDateChange;
  final VoidCallback onCodeChange;
  final VoidCallback? onRename;
  final VoidCallback? onMarkAsFinished;
  final VoidCallback? onAddPoint; // ==> CALLBACK BARU <==
  final bool isFinished;

  const EditPopupMenu({
    super.key,
    required this.onDateChange,
    required this.onCodeChange,
    this.onRename,
    this.onMarkAsFinished,
    this.onAddPoint, // ==> DITAMBAHKAN <==
    this.isFinished = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit_date') onDateChange();
        if (value == 'edit_code') onCodeChange();
        if (value == 'rename' && onRename != null) onRename!();
        if (value == 'finish' && onMarkAsFinished != null) onMarkAsFinished!();
        if (value == 'add_point' && onAddPoint != null)
          onAddPoint!(); // ==> LOGIKA BARU <==
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> menuItems = [];

        if (!isFinished) {
          // ==> MENU TAMBAH POIN DITAMBAHKAN DI SINI <==
          if (onAddPoint != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'add_point',
                child: Text('Tambah Poin'),
              ),
            );
          }

          menuItems.addAll([
            const PopupMenuItem<String>(
              value: 'edit_date',
              child: Text('Ubah Tanggal'),
            ),
            const PopupMenuItem<String>(
              value: 'edit_code',
              child: Text('Ubah Kode Repetisi'),
            ),
          ]);

          if (onRename != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'rename',
                child: Text('Ubah Nama'),
              ),
            );
          }
          if (onMarkAsFinished != null) {
            menuItems.add(const PopupMenuDivider());
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'finish',
                child: Text('Tandai Selesai'),
              ),
            );
          }
        } else {
          if (onRename != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'rename',
                child: Text('Ubah Nama'),
              ),
            );
          }
        }

        return menuItems;
      },
    );
  }
}
