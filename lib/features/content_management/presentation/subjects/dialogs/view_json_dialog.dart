// lib/features/content_management/presentation/subjects/dialogs/view_json_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showViewJsonDialog(
  BuildContext context,
  String subjectName,
  String jsonContent,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('JSON Mentah: $subjectName'),
      content: SingleChildScrollView(
        child: SelectableText(
          jsonContent,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Salin'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: jsonContent));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Konten JSON disalin ke clipboard!'),
              ),
            );
          },
        ),
      ],
    ),
  );
}
