// lib/presentation/pages/2_subjects_page/dialogs/subject_dialogs.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/data/services/path_service.dart';
import 'package:file_picker/file_picker.dart'; // Impor file_picker

// ==> DIALOG BARU UNTUK MEMILIH ATAU MEMBUAT FOLDER PERPUSKU <==
Future<String?> showLinkOrCreatePerpuskuDialog({
  required BuildContext context,
  required String forSubjectName,
}) async {
  final pathService = PathService();
  String? perpuskuTopicsPath;
  try {
    perpuskuTopicsPath = await pathService.perpuskuDataPath;
    perpuskuTopicsPath = path.join(
      perpuskuTopicsPath,
      'file_contents',
      'topics',
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
    return null;
  }

  // Opsi 1: Memilih folder yang sudah ada
  Future<String?> pickExistingSubject() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => _PerpuskuPathPicker(basePath: perpuskuTopicsPath!),
    );
  }

  // Opsi 2: Membuat folder baru
  Future<String?> createNewSubject() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => _CreatePerpuskuSubjectDialog(
        basePath: perpuskuTopicsPath!,
        suggestedName: forSubjectName,
      ),
    );
  }

  return await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Tautkan ke PerpusKu'),
        content: Text(
          'Subject "$forSubjectName" harus ditautkan ke folder di PerpusKu. Pilih folder yang sudah ada atau buat yang baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          OutlinedButton(
            onPressed: () async {
              final result = await createNewSubject();
              if (result != null) Navigator.pop(context, result);
            },
            child: const Text('Buat Folder Baru'),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await pickExistingSubject();
              if (result != null) Navigator.pop(context, result);
            },
            child: const Text('Pilih Folder Ada'),
          ),
        ],
      );
    },
  );
}

class _CreatePerpuskuSubjectDialog extends StatefulWidget {
  final String basePath;
  final String suggestedName;

  const _CreatePerpuskuSubjectDialog({
    required this.basePath,
    required this.suggestedName,
  });

  @override
  State<_CreatePerpuskuSubjectDialog> createState() =>
      _CreatePerpuskuSubjectDialogState();
}

class _CreatePerpuskuSubjectDialogState
    extends State<_CreatePerpuskuSubjectDialog> {
  String _selectedTopic = '';
  List<Directory> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    try {
      final dir = Directory(widget.basePath);
      _topics = dir.listSync().whereType<Directory>().toList();
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createFolderAndPop() async {
    if (_selectedTopic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih topik terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final newSubjectPath = path.join(
        widget.basePath,
        _selectedTopic,
        widget.suggestedName,
      );
      final newDir = Directory(newSubjectPath);
      if (await newDir.exists()) {
        throw Exception(
          'Folder dengan nama "${widget.suggestedName}" sudah ada di dalam topik "$_selectedTopic".',
        );
      }
      await newDir.create(recursive: true);

      // Buat file metadata.json kosong
      final metadataFile = File(path.join(newDir.path, 'metadata.json'));
      await metadataFile.writeAsString(jsonEncode({"content": []}));

      final relativePath = path.join(_selectedTopic, widget.suggestedName);
      if (mounted) Navigator.pop(context, relativePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal membuat folder: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Buat Folder Subjek Baru'),
      content: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Akan membuat folder bernama:'),
                Text(
                  widget.suggestedName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTopic.isEmpty ? null : _selectedTopic,
                  hint: const Text('Pilih Topik Tujuan...'),
                  isExpanded: true,
                  items: _topics.map((dir) {
                    final topicName = path.basename(dir.path);
                    return DropdownMenuItem(
                      value: topicName,
                      child: Text(topicName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTopic = value);
                    }
                  },
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _createFolderAndPop,
          child: const Text('Buat & Tautkan'),
        ),
      ],
    );
  }
}

// Sisa kode dari file asli...
// (Kelas _PerpuskuPathPicker, showIconPickerDialog, showSubjectTextInputDialog, showDeleteConfirmationDialog, etc.)
// ... Letakkan semua fungsi lain yang sudah ada di sini ...

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
