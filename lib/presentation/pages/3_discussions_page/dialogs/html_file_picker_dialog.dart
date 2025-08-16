// lib/presentation/pages/3_discussions_page/dialogs/html_file_picker_dialog.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../../../data/services/shared_preferences_service.dart';
import '../../../providers/discussion_provider.dart';
import '../../1_topics_page/utils/scaffold_messenger_utils.dart';

// Enum untuk mengelola state tampilan dialog saat ini
enum _PickerViewState { topics, subjects, files }

class HtmlFilePickerDialog extends StatefulWidget {
  final String basePath;

  const HtmlFilePickerDialog({super.key, required this.basePath});

  @override
  State<HtmlFilePickerDialog> createState() => _HtmlFilePickerDialogState();
}

class _HtmlFilePickerDialogState extends State<HtmlFilePickerDialog> {
  _PickerViewState _currentView = _PickerViewState.topics;
  String _selectedTopic = '';
  String _selectedSubject = '';

  List<Directory> _topics = [];
  List<Directory> _subjects = [];
  List<File> _files = [];
  final TextEditingController _searchController = TextEditingController();
  List<File> _filteredFiles = [];
  String _searchQuery = '';
  // ==> TAMBAHKAN STATE UNTUK MENYIMPAN MAPPING JUDUL <==
  Map<String, String> _fileTitles = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTopics();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterFiles();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final topicsDir = Directory(widget.basePath);
      if (!await topicsDir.exists()) {
        // ==> PESAN ERROR DIUBAH <==
        throw Exception(
          "Direktori base PerpusKu tidak ditemukan.\nPastikan Anda telah memilih folder 'PerpusKu/data' yang benar di pengaturan backup atau pilih ulang melalui tombol di bawah.",
        );
      }
      final items = topicsDir.listSync();
      _topics = items.whereType<Directory>().toList();
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadSubjects(String topicPath) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final subjectsDir = Directory(topicPath);
      final items = subjectsDir.listSync();
      _subjects = items.whereType<Directory>().toList();
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadFiles(String subjectPath) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _fileTitles = {}; // Reset judul setiap kali memuat
    });
    try {
      final filesDir = Directory(subjectPath);
      final items = filesDir.listSync();
      _files = items
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.html'))
          .toList();
      _filteredFiles = _files;

      // ==> LOGIKA BARU: BACA METADATA.JSON DAN BUAT MAPPING <==
      final metadataFile = File(path.join(subjectPath, 'metadata.json'));
      if (await metadataFile.exists()) {
        final jsonString = await metadataFile.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        final content = jsonData['content'] as List<dynamic>? ?? [];
        _fileTitles = {
          for (var item in content)
            item['nama_file'] as String: item['judul'] as String,
        };
      }
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  void _filterFiles() {
    if (_searchQuery.isEmpty) {
      _filteredFiles = _files;
    } else {
      _filteredFiles = _files.where((file) {
        final fileName = path.basename(file.path).toLowerCase();
        final fileTitle =
            _fileTitles[path.basename(file.path)]?.toLowerCase() ?? '';
        return fileName.contains(_searchQuery) ||
            fileTitle.contains(_searchQuery);
      }).toList();
    }
  }

  // ==> FUNGSI BARU UNTUK MEMILIH FOLDER PERPUSKU <==
  Future<void> _selectPerpuskuDataFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Sumber Data PerpusKu (PerpusKu/data)',
    );

    if (selectedDirectory != null) {
      final prefs = SharedPreferencesService();
      await prefs.savePerpuskuDataPath(selectedDirectory);

      // Reload provider and dialog state
      if (mounted) {
        // Tutup dialog saat ini dan buka kembali dengan path yang baru
        Navigator.of(
          context,
        ).pop('RELOAD_WITH_NEW_PATH'); // Kirim sinyal untuk memuat ulang
      }
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Error: $_error",
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    switch (_currentView) {
      case _PickerViewState.topics:
        return _buildListView(_topics, (item) {
          _selectedTopic = path.basename(item.path);
          _loadSubjects(item.path);
          setState(() => _currentView = _PickerViewState.subjects);
        });
      case _PickerViewState.subjects:
        return _buildListView(_subjects, (item) {
          _selectedSubject = path.basename(item.path);
          _loadFiles(item.path);
          setState(() => _currentView = _PickerViewState.files);
        });
      case _PickerViewState.files:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari file...',
                  hintText: 'Masukkan nama atau judul file',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildListView(_filteredFiles, (item) {
                final selectedFile = path.basename(item.path);
                final resultPath = path.join(
                  _selectedTopic,
                  _selectedSubject,
                  selectedFile,
                );
                Navigator.of(context).pop(resultPath);
              }),
            ),
          ],
        );
    }
  }

  Widget _buildListView(
    List<FileSystemEntity> items,
    ValueChanged<FileSystemEntity> onTap,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          _currentView == _PickerViewState.files && _searchQuery.isNotEmpty
              ? "File tidak ditemukan."
              : "Tidak ada item ditemukan.",
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final fileName = path.basename(item.path);
        // ==> AMBIL JUDUL DARI MAP, GUNAKAN NAMA FILE JIKA TIDAK ADA <==
        final title = _fileTitles[fileName] ?? fileName;

        return ListTile(
          leading: Icon(item is Directory ? Icons.folder : Icons.description),
          // ==> TAMPILKAN JUDUL DI SINI <==
          title: Text(title),
          // ==> TAMPILKAN NAMA FILE SEBAGAI SUBTITLE JIKA BERBEDA <==
          subtitle: title != fileName ? Text(fileName) : null,
          onTap: () => onTap(item),
        );
      },
    );
  }

  String get _title {
    switch (_currentView) {
      case _PickerViewState.topics:
        return 'Pilih Topik';
      case _PickerViewState.subjects:
        return 'Pilih Subjek (dari: $_selectedTopic)';
      case _PickerViewState.files:
        return 'Pilih File HTML (dari: $_selectedSubject)';
    }
  }

  void _onBackPressed() {
    if (_currentView == _PickerViewState.files) {
      setState(() {
        _currentView = _PickerViewState.subjects;
        _searchController.clear();
      });
    } else if (_currentView == _PickerViewState.subjects) {
      setState(() => _currentView = _PickerViewState.topics);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: _buildContent(),
      ),
      actions: [
        // ==> TOMBOL BARU DITAMBAHKAN DI SINI <==
        ElevatedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text('Pilih Folder PerpusKu'),
          onPressed: _selectPerpuskuDataFolder,
        ),
        const Spacer(),
        if (_currentView != _PickerViewState.topics)
          TextButton(onPressed: _onBackPressed, child: const Text('Kembali')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
