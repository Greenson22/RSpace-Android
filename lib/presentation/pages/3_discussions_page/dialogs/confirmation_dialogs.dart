// lib/presentation/pages/3_discussions_page/dialogs/confirmation_dialogs.dart
import 'package:flutter/material.dart';

Future<void> showDeleteDiscussionConfirmationDialog({
  required BuildContext context,
  required String discussionName,
  required VoidCallback onDelete,
  bool hasLinkedFile = false,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Hapus Diskusi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin menghapus diskusi "$discussionName" beserta semua isinya?',
            ),
            if (hasLinkedFile) ...[
              const SizedBox(height: 16),
              const Text(
                'PERINGATAN: File HTML yang tertaut dengan diskusi ini juga akan dihapus secara permanen.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );
}

Future<void> showDeletePointConfirmationDialog({
  required BuildContext context,
  required String pointText,
  required VoidCallback onDelete,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Hapus Poin'),
        content: Text('Anda yakin ingin menghapus poin "$pointText"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );
}

Future<bool> showRemoveFilePathConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Hapus Path File'),
            content: const Text(
              'Anda yakin ingin menghapus tautan path file dari diskusi ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<bool> showRepetitionCodeUpdateConfirmationDialog({
  required BuildContext context,
  required String currentCode,
  required String nextCode,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Konfirmasi Perubahan Kode'),
            content: Text(
              'Anda yakin ingin mengubah kode repetisi dari "$currentCode" menjadi "$nextCode"? Tanggal juga akan diperbarui.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Ubah'),
              ),
            ],
          );
        },
      ) ??
      false;
}
