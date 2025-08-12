import 'package:flutter/material.dart';

// ==> DIALOG BARU UNTUK MEMILIH IKON SUBJECT <==
Future<void> showIconPickerDialog({
  required BuildContext context,
  required Function(String) onIconSelected,
}) async {
  // Daftar ikon berupa simbol emoji
  final List<String> icons = [
    '📄',
    '📝',
    '📓',
    '🔖',
    '🔗',
    '📈',
    '🧪',
    '💬',
    '💡',
    '📌',
    '🛠️',
    '⚙️',
  ];

  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Pilih Ikon Baru'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: icons.map((iconSymbol) {
            return InkWell(
              onTap: () {
                onIconSelected(iconSymbol);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(iconSymbol, style: const TextStyle(fontSize: 32)),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

// Dialog untuk input teks (menambah/mengubah nama subject)
Future<void> showSubjectTextInputDialog({
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

// Dialog untuk konfirmasi penghapusan subject
Future<void> showDeleteConfirmationDialog({
  required BuildContext context,
  required String subjectName,
  required VoidCallback onDelete,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Hapus Subject'),
        content: Text('Anda yakin ingin menghapus subject "$subjectName"?'),
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
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );
}
