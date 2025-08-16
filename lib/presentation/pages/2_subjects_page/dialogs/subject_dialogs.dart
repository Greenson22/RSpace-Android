import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
