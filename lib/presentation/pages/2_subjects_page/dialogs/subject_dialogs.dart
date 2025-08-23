// lib/presentation/pages/2_subjects_page/dialogs/subject_dialogs.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/data/services/path_service.dart';

// ==> DIALOG BARU UNTUK MEMILIH PATH DARI PERPUSKU <==
Future<String?> showPerpuskuPathPickerDialog({
  required BuildContext context,
}) async {
  final pathService = PathService();
  String? basePath;
  try {
    basePath = await pathService.perpuskuDataPath;
    basePath = path.join(basePath, 'file_contents', 'topics');
  } catch (e) {
    // Menampilkan pesan error jika path dasar tidak dapat diakses
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
    return null;
  }

  return showDialog<String>(
    context: context,
    builder: (context) => _PerpuskuPathPicker(basePath: basePath!),
  );
}

class _PerpuskuPathPicker extends StatefulWidget {
  final String basePath;
  const _PerpuskuPathPicker({required this.basePath});

  @override
  _PerpuskuPathPickerState createState() => _PerpuskuPathPickerState();
}

class _PerpuskuPathPickerState extends State<_PerpuskuPathPicker> {
  String _currentPath = '';
  List<Directory> _items = [];
  bool _isTopicView = true;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.basePath;
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final dir = Directory(_currentPath);
      if (!await dir.exists()) {
        throw Exception("Direktori tidak ditemukan: $_currentPath");
      }
      final items = dir.listSync().whereType<Directory>().toList();
      setState(() {
        _items = items;
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error memuat folder: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onItemTapped(Directory item) {
    if (_isTopicView) {
      setState(() {
        _currentPath = item.path;
        _isTopicView = false;
      });
      _loadItems();
    } else {
      // Saat subjek dipilih, kembalikan path relatif
      final relativePath = path.relative(item.path, from: widget.basePath);
      Navigator.of(context).pop(relativePath);
    }
  }

  void _onBackPressed() {
    if (!_isTopicView) {
      setState(() {
        _currentPath = widget.basePath;
        _isTopicView = true;
      });
      _loadItems();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isTopicView ? 'Pilih Topik' : 'Pilih Subjek'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _items.isEmpty
            ? const Center(child: Text("Tidak ada folder ditemukan."))
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(path.basename(item.path)),
                    onTap: () => _onItemTapped(item),
                  );
                },
              ),
      ),
      actions: [
        if (!_isTopicView)
          TextButton(
            onPressed: _onBackPressed,
            child: const Text('Kembali ke Topik'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
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
