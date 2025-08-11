import 'package:flutter/material.dart';

class EditPopupMenu extends StatelessWidget {
  final VoidCallback onDateChange;
  final VoidCallback onCodeChange;
  final VoidCallback? onRename;

  const EditPopupMenu({
    super.key,
    required this.onDateChange,
    required this.onCodeChange,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit_date') onDateChange();
        if (value == 'edit_code') onCodeChange();
        if (value == 'rename' && onRename != null) onRename!();
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> menuItems = [
          const PopupMenuItem<String>(
            value: 'edit_date',
            child: Text('Ubah Tanggal'),
          ),
          const PopupMenuItem<String>(
            value: 'edit_code',
            child: Text('Ubah Kode Repetisi'),
          ),
        ];

        if (onRename != null) {
          menuItems.add(
            const PopupMenuItem<String>(
              value: 'rename',
              child: Text('Ubah Nama'),
            ),
          );
        }

        return menuItems;
      },
    );
  }
}
