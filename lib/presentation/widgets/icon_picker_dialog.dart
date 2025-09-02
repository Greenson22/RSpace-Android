// lib/presentation/widgets/dialogs/icon_picker_dialog.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Menampilkan dialog pemilihan ikon yang reusable dengan opsi input dari keyboard.
Future<void> showIconPickerDialog({
  required BuildContext context,
  required Function(String) onIconSelected,
}) async {
  final TextEditingController iconController = TextEditingController();

  // Fungsi untuk memuat data ikon dari file JSON
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
                    // Input field untuk keyboard
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: TextField(
                        controller: iconController,
                        decoration: InputDecoration(
                          labelText: 'Ketik ikon di sini',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.done),
                            onPressed: () {
                              if (iconController.text.isNotEmpty) {
                                onIconSelected(iconController.text);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    // Tab kategori ikon
                    TabBar(
                      isScrollable: true,
                      tabs: iconCategories.keys
                          .map((title) => Tab(text: title))
                          .toList(),
                    ),
                    // Grid view untuk ikon
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
