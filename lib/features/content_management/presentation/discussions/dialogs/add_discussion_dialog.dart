// lib/presentation/pages/3_discussions_page/dialogs/add_discussion_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';

Future<void> showAddDiscussionDialog({
  required BuildContext context,
  required String title,
  required String label,
  required Function(String, bool) onSave,
  required String? subjectLinkedPath,
  required Discussion discussion,
}) async {
  final controller = TextEditingController();
  bool createHtmlFile = false;

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
                if (subjectLinkedPath != null && subjectLinkedPath.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: CheckboxListTile(
                      title: const Text("Buat file HTML tertaut"),
                      subtitle: Text(
                        "Akan membuat file .html baru di dalam folder:\n$subjectLinkedPath",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: createHtmlFile,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          createHtmlFile = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
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
                    onSave(controller.text, createHtmlFile);
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
