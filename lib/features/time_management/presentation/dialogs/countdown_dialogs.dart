// lib/presentation/pages/countdown_page/dialogs/countdown_dialogs.dart
import 'package:flutter/material.dart';

Future<bool> showDeleteConfirmationDialog(
  BuildContext context,
  String timerName,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Anda yakin ingin menghapus timer "$timerName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ) ??
      false; // Mengembalikan false jika dialog ditutup begitu saja
}
