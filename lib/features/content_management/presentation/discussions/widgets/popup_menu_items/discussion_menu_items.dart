// lib/presentation/widgets/popup_menu_items/discussion_menu_items.dart
import 'package:flutter/material.dart';

/// Menampilkan item menu standar untuk sebuah diskusi.
List<PopupMenuEntry<String>> buildDiscussionMenuItems({
  required VoidCallback onAddPoint,
  required VoidCallback onRename,
  required bool isFinished,
}) {
  if (isFinished) {
    return [
      const PopupMenuItem<String>(value: 'rename', child: Text('Ubah Nama')),
    ];
  }
  return [
    const PopupMenuItem<String>(value: 'add_point', child: Text('Tambah Poin')),
    const PopupMenuItem<String>(value: 'rename', child: Text('Ubah Nama')),
  ];
}
