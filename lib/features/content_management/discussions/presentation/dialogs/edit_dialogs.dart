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

// ==> BARU: Dialog untuk Highlight <==
Future<void> showHighlightDialog({
  required BuildContext context,
  required int? initialColor,
  required String? initialLabel,
  required Function(int?, String?) onSave,
}) async {
  final labelController = TextEditingController(text: initialLabel);
  int? selectedColor = initialColor;

  final List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Atur Highlight Diskusi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label (Opsional)',
                      hintText: 'Contoh: Penting, Baca Nanti',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Warna:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InkWell(
                        onTap: () => setState(() => selectedColor = null),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                            color: Colors.white,
                          ),
                          child: selectedColor == null
                              ? const Icon(Icons.check, color: Colors.black)
                              : const Icon(Icons.close, color: Colors.grey),
                        ),
                      ),
                      ...colors.map((color) {
                        final isSelected = selectedColor == color.value;
                        return InkWell(
                          onTap: () =>
                              setState(() => selectedColor = color.value),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  onSave(selectedColor, labelController.text.trim());
                  Navigator.pop(context);
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
