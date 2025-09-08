// lib/presentation/pages/2_subjects_page/dialogs/subject_dialogs.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/data/services/path_service.dart';

// Ekspor dialog ikon agar bisa diimpor dari file ini.
export '../../../../../presentation/widgets/icon_picker_dialog.dart';

// Dialog untuk menautkan atau membuat folder baru di PerpusKu
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

// Widget internal untuk membuat folder baru
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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _folderNameController;
  String _selectedTopic = '';
  List<Directory> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _folderNameController = TextEditingController(text: widget.suggestedName);
    _loadTopics();
  }

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      final newFolderName = _folderNameController.text.trim();
      final newSubjectPath = path.join(
        widget.basePath,
        _selectedTopic,
        newFolderName,
      );
      final newDir = Directory(newSubjectPath);
      if (await newDir.exists()) {
        throw Exception(
          'Folder dengan nama "$newFolderName" sudah ada di dalam topik "$_selectedTopic".',
        );
      }
      await newDir.create(recursive: true);

      final metadataFile = File(path.join(newDir.path, 'metadata.json'));
      await metadataFile.writeAsString(jsonEncode({"content": []}));

      final relativePath = path.join(_selectedTopic, newFolderName);
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
      title: const Text('Buat Folder Subjek Baru'),
      content: Form(
        key: _formKey,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _folderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Folder di PerpusKu',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama folder tidak boleh kosong.';
                      }
                      return null;
                    },
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Silakan pilih topik.'
                        : null,
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
          onPressed: _createFolderAndPop,
          child: const Text('Buat & Tautkan'),
        ),
      ],
    );
  }
}

// Widget internal untuk memilih path yang sudah ada
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

// Dialog untuk input teks
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

// Dialog konfirmasi hapus
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );
}
