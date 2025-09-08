// lib/presentation/pages/3_discussions_page/dialogs/edit_dialogs.dart
import 'package:flutter/material.dart';

Future<void> showTextInputDialog({
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

void showRepetitionCodeDialog(
  BuildContext context,
  String currentCode,
  List<String> repetitionCodes,
  Function(String) onCodeSelected,
) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      String? tempSelectedCode = currentCode;
      return StatefulBuilder(
        builder: (context, setStateInDialog) {
          return AlertDialog(
            title: const Text('Pilih Kode Repetisi'),
            content: DropdownButton<String>(
              value: tempSelectedCode,
              isExpanded: true,
              items: repetitionCodes.map((String code) {
                return DropdownMenuItem<String>(value: code, child: Text(code));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setStateInDialog(() => tempSelectedCode = newValue);
                  onCodeSelected(newValue);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      );
    },
  );
}
