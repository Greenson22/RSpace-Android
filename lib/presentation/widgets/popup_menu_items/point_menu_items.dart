// lib/presentation/widgets/popup_menu_items/point_menu_items.dart
import 'package:flutter/material.dart';

/// Menampilkan item menu dasar untuk sebuah Poin (Point).
List<PopupMenuEntry<String>> buildPointMenuItems({
  required VoidCallback onDateChange,
  required VoidCallback onCodeChange,
  required VoidCallback onRename,
}) {
  return [
    const PopupMenuItem<String>(
      value: 'edit_date',
      child: Text('Ubah Tanggal'),
    ),
    const PopupMenuItem<String>(
      value: 'edit_code',
      child: Text('Ubah Kode Repetisi'),
    ),
    const PopupMenuItem<String>(value: 'rename', child: Text('Ubah Nama')),
  ];
}
