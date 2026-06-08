import 'package:flutter/material.dart';

/// Menampilkan dialog gabungan untuk input nama topik dan ikon emoji sekaligus.
Future<void> showTopicTextInputDialog({
  required BuildContext context,
  required String title,
  String initialIcon = '📁',
  String initialValue = '',
  required Function(String name, String icon)
  onSave, // Menerima 2 parameter masukan
}) async {
  final nameController = TextEditingController(text: initialValue);
  final iconController = TextEditingController(text: initialIcon);

  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: iconController,
                    decoration: const InputDecoration(
                      labelText: 'Ikon',
                      hintText: 'Emoji',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nama Topik'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  iconController.text.isNotEmpty) {
                onSave(nameController.text, iconController.text);
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
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
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
