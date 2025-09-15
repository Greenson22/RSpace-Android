// lib/features/content_management/presentation/topics/dialogs/topic_dialogs.dart
import 'package:flutter/material.dart';
// Ekspor dialog ikon agar bisa diimpor dari file ini saja.
export '../../../../../core/widgets/icon_picker_dialog.dart';

/// Menampilkan dialog untuk input teks (menambah/mengubah nama topik).
Future<void> showTopicTextInputDialog({
  required BuildContext context,
  required String title,
  required String label,
  String initialValue = '',
  required Function(String) onSave,
  TextInputType keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
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

/// Menampilkan dialog konfirmasi untuk menghapus topik.
Future<Map<String, bool>?> showDeleteTopicConfirmationDialog({
  required BuildContext context,
  required String topicName,
}) async {
  bool deleteFolder = false;

  return await showDialog<Map<String, bool>?>(
    context: context,
    builder: (context) {
      // Gunakan StatefulBuilder untuk mengelola state checkbox di dalam dialog
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Hapus Topik'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Anda yakin ingin menghapus topik "$topicName"?'),
                const SizedBox(height: 16),
                // Tampilkan checkbox
                CheckboxListTile(
                  title: const Text(
                    "Hapus juga folder & isinya di PerpusKu",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Lokasi: PerpusKu/data/file_contents/topics/$topicName",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: deleteFolder,
                  onChanged: (bool? value) {
                    setDialogState(() {
                      deleteFolder = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null), // Batal
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  // Kirim hasil konfirmasi dan pilihan checkbox
                  Navigator.pop(context, {
                    'confirmed': true,
                    'deleteFolder': deleteFolder,
                  });
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          );
        },
      );
    },
  );
}
