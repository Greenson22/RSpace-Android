// lib/presentation/pages/1_topics_page/dialogs/topic_dialogs.dart
import 'package:flutter/material.dart';

// ==> DIALOG BARU UNTUK MEMASUKKAN PATH (BISA DIGUNAKAN UNTUK BACKUP & PENYIMPANAN) <==
Future<void> showPathInputDialog({
  required BuildContext context,
  required String title,
  required String label,
  required String hint,
  String initialValue = '',
  required Function(String) onSave,
}) async {
  final controller = TextEditingController(text: initialValue);
  return await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(labelText: label, hintText: hint),
              ),
              const SizedBox(height: 16),
              Text(
                "CATATAN: Untuk pengalaman terbaik, disarankan menggunakan package 'file_picker' agar pengguna dapat memilih folder secara visual.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSave(controller.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );
}

// Dialog backup sekarang menggunakan showPathInputDialog
Future<String?> showBackupPathDialog(BuildContext context) async {
  String? resultPath;
  await showPathInputDialog(
    context: context,
    title: "Pilih Folder Backup",
    label: "Path Folder Backup",
    hint: "Contoh: /storage/emulated/0/Download",
    onSave: (path) {
      resultPath = path;
    },
  );
  return resultPath;
}

// ==> DIALOG BAWAAN YANG TIDAK BERUBAH <==
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
