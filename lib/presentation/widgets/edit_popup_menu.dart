import 'package:flutter/material.dart';

class EditPopupMenu extends StatelessWidget {
  final VoidCallback onDateChange;
  final VoidCallback onCodeChange;
  final VoidCallback? onRename;
  final VoidCallback? onMarkAsFinished; // ==> CALLBACK BARU <==
  final bool isFinished; // ==> STATE BARU <==

  const EditPopupMenu({
    super.key,
    required this.onDateChange,
    required this.onCodeChange,
    this.onRename,
    this.onMarkAsFinished, // ==> DITAMBAHKAN <==
    this.isFinished = false, // ==> DITAMBAHKAN <==
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit_date') onDateChange();
        if (value == 'edit_code') onCodeChange();
        if (value == 'rename' && onRename != null) onRename!();
        // ==> LOGIKA BARU <==
        if (value == 'finish' && onMarkAsFinished != null) onMarkAsFinished!();
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> menuItems = [];

        // ==> KONDISI UNTUK MENAMPILKAN MENU <==
        if (!isFinished) {
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
