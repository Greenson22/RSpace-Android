// lib/presentation/widgets/popup_menu_items/file_menu_items.dart
import 'package:flutter/material.dart';

/// Menampilkan item menu yang berhubungan dengan file.
List<PopupMenuEntry<String>> buildFileMenuItems({
  required bool hasFilePath,
  required VoidCallback onSetFilePath,
  required VoidCallback onGenerateHtml,
  required VoidCallback onEditFilePath,
  required VoidCallback onRemoveFilePath,
}) {
  return [
    PopupMenuItem<String>(
      value: 'set_file_path',
      child: Text(hasFilePath ? 'Ubah Path File' : 'Set Path File'),
    ),
    if (hasFilePath) ...[
      const PopupMenuItem<String>(
        value: 'generate_html',
        child: Text('Generate Content with AI'),
      ),
      const PopupMenuItem<String>(
        value: 'edit_file_path',
        child: Text('Edit File Konten'),
      ),
      const PopupMenuItem<String>(
        value: 'remove_file_path',
        child: Text('Hapus Path File', style: TextStyle(color: Colors.orange)),
      ),
    ],
  ];
}
