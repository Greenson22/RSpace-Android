// lib/presentation/pages/1_topics_page/dialogs/topic_dialogs.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ... (kode showPathInputDialog dan showIconPickerDialog tidak berubah) ...
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

Future<void> showIconPickerDialog({
  required BuildContext context,
  required Function(String) onIconSelected,
}) async {
  Future<Map<String, List<String>>> loadIcons() async {
    final String response = await rootBundle.loadString('assets/icons.json');
    final data = await json.decode(response) as Map<String, dynamic>;
    return data.map((key, value) {
      return MapEntry(key, List<String>.from(value as List));
    });
  }

  return showDialog<void>(
    context: context,
    builder: (context) {
      return FutureBuilder<Map<String, List<String>>>(
        future: loadIcons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return AlertDialog(
              title: const Text('Error'),
              content: const Text('Gagal memuat ikon.'),
              actions: [
                TextButton(
                  child: const Text('Tutup'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          }

          final iconCategories = snapshot.data!;

          return AlertDialog(
            title: const Text('Pilih Ikon Baru'),
            content: DefaultTabController(
              length: iconCategories.length,
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabs: iconCategories.keys
                          .map((title) => Tab(text: title))
                          .toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: iconCategories.entries.map((entry) {
                          final icons = entry.value;
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: icons.length,
                            itemBuilder: (context, index) {
                              final iconSymbol = icons[index];
                              return InkWell(
                                onTap: () {
                                  onIconSelected(iconSymbol);
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Center(
                                  child: Text(
                                    iconSymbol,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
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
    },
  );
}

Future<void> showTopicTextInputDialog({
  required BuildContext context,
  required String title,
  required String label,
  String initialValue = '',
  required Function(String) onSave,
  // ==> PARAMETER DITAMBAHKAN <==
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
          // ==> DIGUNAKAN DI SINI <==
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
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );
}
