import 'package:flutter/material.dart';

// ==> DIALOG BARU UNTUK MEMILIH IKON <==
Future<void> showIconPickerDialog({
  required BuildContext context,
  required Function(String) onIconSelected,
}) async {
  // Daftar ikon berupa simbol emoji
  final List<String> icons = [
    '📁',
    '📚',
    '💡',
    '🔬',
    '🎨',
    '🎵',
    '💻',
    '📈',
    '⭐',
    '❤️',
    '💼',
    '🏠',
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

Future<void> showTopicTextInputDialog({
  required BuildContext context,
  required String title,
  required String label,
  String initialValue = '',
  required Function(String) onSave,
  TextInputType keyboardType = TextInputType.text, // ==> DITAMBAHKAN
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
          keyboardType: keyboardType, // ==> DIGUNAKAN DI SINI
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
