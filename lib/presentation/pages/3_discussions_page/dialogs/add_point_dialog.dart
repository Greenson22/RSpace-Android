// lib/presentation/pages/3_discussions_page/dialogs/add_point_dialog.dart
import 'package:flutter/material.dart';

Future<void> showAddPointDialog({
  required BuildContext context,
  required String title,
  required String label,
  required Function(String, bool) onSave,
}) async {
  final controller = TextEditingController();
  bool inheritRepetitionCode = false;

  return showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(labelText: label),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text("Ikuti kode repetisi dari diskusi induk"),
                  value: inheritRepetitionCode,
                  onChanged: (bool? value) {
                    setDialogState(() {
                      inheritRepetitionCode = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
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
                  if (controller.text.isNotEmpty) {
                    onSave(controller.text, inheritRepetitionCode);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}
