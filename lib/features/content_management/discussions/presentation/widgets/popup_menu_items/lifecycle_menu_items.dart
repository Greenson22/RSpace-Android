// lib/presentation/widgets/popup_menu_items/lifecycle_menu_items.dart
import 'package:flutter/material.dart';

/// Menampilkan item menu untuk mengubah status (lifecycle) item.
List<PopupMenuEntry<String>> buildLifecycleMenuItems({
  required bool isFinished,
  required VoidCallback onMarkAsFinished,
  required VoidCallback onReactivate,
  required VoidCallback onDelete,
}) {
  return [
    if (!isFinished)
      const PopupMenuItem<String>(
        value: 'finish',
        child: Text('Tandai Selesai'),
      )
    else
      const PopupMenuItem<String>(
        value: 'reactivate',
        child: Text('Aktifkan Lagi'),
      ),
    const PopupMenuDivider(),
    const PopupMenuItem<String>(
      value: 'delete',
      child: Text('Hapus', style: TextStyle(color: Colors.red)),
    ),
  ];
}
