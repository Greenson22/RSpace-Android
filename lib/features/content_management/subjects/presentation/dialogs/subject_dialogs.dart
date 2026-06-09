// lib/features/content_management/presentation/subjects/dialogs/subject_dialogs.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import '../subjects_page.dart';

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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }

  String? currentTopicName;
  if (context.widget is SubjectsPage) {
    currentTopicName = (context.widget as SubjectsPage).topicName;
  }

  if (currentTopicName == null || currentTopicName.isEmpty) {
    final subjectsPage = context.findAncestorWidgetOfExactType<SubjectsPage>();
    currentTopicName = subjectsPage?.topicName;
  }

  if (currentTopicName != null && currentTopicName.isNotEmpty) {
    try {
      final safeFolderName = forSubjectName.trim().replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final newSubjectPath = path.join(
        perpuskuTopicsPath,
        currentTopicName,
        safeFolderName,
      );
      final newDir = Directory(newSubjectPath);
      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
        final metadataFile = File(path.join(newDir.path, 'metadata.json'));
        await metadataFile.writeAsString(jsonEncode({"content": []}));
        final indexFile = File(path.join(newDir.path, 'index.html'));
        const htmlTemplate = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Index</title>
</head>
<body>
    <div id="main-container"></div>
</body>
</html>''';
        await indexFile.writeAsString(htmlTemplate);
      }
      return path.join(currentTopicName, safeFolderName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuat folder otomatis: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<String?> pickExistingSubject() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => _PerpuskuPathPicker(basePath: perpuskuTopicsPath!),
    );
  }

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
        title: const Text('Tautkan ke PerpusKu'),
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
      // Abaikan jika error saat load
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
      final indexFile = File(path.join(newDir.path, 'index.html'));
      const htmlTemplate = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Index</title>
</head>
<body>
    <div id="main-container"></div>
</body>
</html>''';
      await indexFile.writeAsString(htmlTemplate);
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
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
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
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error memuat folder: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
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

// DIUBAH: Mendukung dual input Nama Subject dan Ikon Emoji sekaligus
Future<void> showSubjectTextInputDialog({
  required BuildContext context,
  required String title,
  required String label,
  String initialIcon = '📚',
  String initialValue = '',
  required Function(String name, String icon) onSave,
}) async {
  final nameController = TextEditingController(text: initialValue);
  final iconController = TextEditingController(text: initialIcon);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Ikon',
                  hintText: 'Emoji',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(labelText: label),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  iconController.text.isNotEmpty) {
                onSave(nameController.text, iconController.text);
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
Future<Map<String, bool>?> showDeleteConfirmationDialog({
  required BuildContext context,
  required String subjectName,
  required String? linkedPath,
}) async {
  bool deleteFolder = false;
  final bool isLinked = linkedPath != null && linkedPath.isNotEmpty;
  return await showDialog<Map<String, bool>?>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Hapus Subject'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Anda yakin ingin menghapus subject "$subjectName"?'),
                const SizedBox(height: 16),
                if (isLinked)
                  CheckboxListTile(
                    title: const Text(
                      "Hapus juga folder & isinya di PerpusKu",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Lokasi: $linkedPath",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: deleteFolder,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        deleteFolder = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'confirmed': true,
                    'deleteFolder': deleteFolder,
                  });
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          );
        },
      );
    },
  );
}
