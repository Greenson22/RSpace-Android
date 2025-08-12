import 'package:flutter/material.dart';

Future<void> showTopicTextInputDialog({
  required BuildContext context,
  required String title,
  required String label,
  String initialValue = '',
  required Function(String) onSave,
}) async {
  final controller = TextEditingController(text: initialValue);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSave(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );
}

Future<void> showDeleteTopicConfirmationDialog({
  required BuildContext context,
  required String topicName,
  required VoidCallback onDelete,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Hapus Topik'),
        content: Text('Anda yakin ingin menghapus topik "$topicName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(
                context,
              ); // Dialog ditutup setelah onDelete dipanggil
            },
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );
}
