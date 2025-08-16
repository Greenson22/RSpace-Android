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
  // File di folder saat ini (untuk pencarian lokal)
  List<File> _currentSubjectFiles = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> _fileTitles = {};

  // State untuk pencarian global
  List<Map<String, String>> _allFilesData = [];
  List<Map<String, String>> _filteredGlobalFiles = [];

  // State untuk pencarian lokal
  List<File> _filteredLocalFiles = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeDialog();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterContent(); // Panggil fungsi filter utama
      });
    });
  }

  Future<void> _initializeDialog() async {
    await _loadTopics();
    // Memuat semua file di latar belakang untuk pencarian global
    _loadAllFilesForSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllFilesForSearch() async {
    try {
      final topicsDir = Directory(widget.basePath);
      if (!await topicsDir.exists()) return;

      final allData = <Map<String, String>>[];
      final topicDirs = topicsDir.listSync().whereType<Directory>();

      for (final topicDir in topicDirs) {
        final subjectDirs = topicDir.listSync().whereType<Directory>();
        for (final subjectDir in subjectDirs) {
          final metadataFile = File(
            path.join(subjectDir.path, 'metadata.json'),
          );
          Map<String, String> currentTitles = {};
          if (await metadataFile.exists()) {
            final jsonString = await metadataFile.readAsString();
            final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
            final content = jsonData['content'] as List<dynamic>? ?? [];
            currentTitles = {
              for (var item in content)
                item['nama_file'] as String: item['judul'] as String,
            };
          }

          final htmlFiles = subjectDir.listSync().whereType<File>().where(
            (f) => f.path.toLowerCase().endsWith('.html'),
          );

          for (final file in htmlFiles) {
            final fileName = path.basename(file.path);
            allData.add({
              'title': currentTitles[fileName] ?? fileName,
              'fileName': fileName,
              'relativePath': path.join(
                path.basename(topicDir.path),
                path.basename(subjectDir.path),
                fileName,
              ),
            });
          }
        }
      }
      setState(() {
        _allFilesData = allData;
      });
    } catch (e) {
      debugPrint("Error loading all files for search: $e");
    }
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final topicsDir = Directory(widget.basePath);
      if (!await topicsDir.exists()) {
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
      _fileTitles = {};
    });
    try {
      final filesDir = Directory(subjectPath);
      final items = filesDir.listSync();
      _currentSubjectFiles = items
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.html'))
          .toList();

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

  // ==> FUNGSI FILTER UTAMA YANG DIPANGGIL LISTENER <==
  void _filterContent() {
    if (_searchQuery.isEmpty) {
      _filteredGlobalFiles = [];
      _filteredLocalFiles = [];
      return;
    }

    // Jika di view file, lakukan pencarian LOKAL
    if (_currentView == _PickerViewState.files) {
      _filteredLocalFiles = _currentSubjectFiles.where((file) {
        final fileName = path.basename(file.path).toLowerCase();
        final fileTitle =
            _fileTitles[path.basename(file.path)]?.toLowerCase() ?? '';
        return fileName.contains(_searchQuery) ||
            fileTitle.contains(_searchQuery);
      }).toList();
    }
    // Jika di view topik atau subjek, lakukan pencarian GLOBAL
    else {
      _filteredGlobalFiles = _allFilesData.where((fileData) {
        final title = fileData['title']!.toLowerCase();
        final fileName = fileData['fileName']!.toLowerCase();
        final relativePath = fileData['relativePath']!.toLowerCase();
        return title.contains(_searchQuery) ||
            fileName.contains(_searchQuery) ||
            relativePath.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _selectPerpuskuDataFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Sumber Data PerpusKu (PerpusKu/data)',
    );

    if (selectedDirectory != null) {
      final prefs = SharedPreferencesService();
      await prefs.savePerpuskuDataPath(selectedDirectory);

      if (mounted) {
        Navigator.of(context).pop('RELOAD_WITH_NEW_PATH');
      }
    }
  }

  // Widget untuk menampilkan hasil pencarian GLOBAL
  Widget _buildGlobalSearchView() {
    if (_filteredGlobalFiles.isEmpty) {
      return const Center(
        child: Text("File tidak ditemukan di semua direktori."),
      );
    }
    return ListView.builder(
      itemCount: _filteredGlobalFiles.length,
      itemBuilder: (context, index) {
        final fileData = _filteredGlobalFiles[index];
        return ListTile(
          leading: const Icon(Icons.description),
          title: Text(fileData['title']!),
          subtitle: Text(fileData['relativePath']!),
          onTap: () => Navigator.of(context).pop(fileData['relativePath']),
        );
      },
    );
  }

  // Widget untuk menampilkan hasil pencarian LOKAL
  Widget _buildLocalSearchView() {
    if (_filteredLocalFiles.isEmpty) {
      return const Center(child: Text("File tidak ditemukan di folder ini."));
    }
    return _buildListView(_filteredLocalFiles, (item) {
      final selectedFile = path.basename(item.path);
      final resultPath = path.join(
        _selectedTopic,
        _selectedSubject,
        selectedFile,
      );
      Navigator.of(context).pop(resultPath);
    });
  }

  // Widget untuk navigasi folder
  Widget _buildNavigationView() {
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
        return _buildListView(_currentSubjectFiles, (item) {
          final selectedFile = path.basename(item.path);
          final resultPath = path.join(
            _selectedTopic,
            _selectedSubject,
            selectedFile,
          );
          Navigator.of(context).pop(resultPath);
        });
    }
  }

  Widget _buildListView(
    List<FileSystemEntity> items,
    ValueChanged<FileSystemEntity> onTap,
  ) {
    if (items.isEmpty) {
      return const Center(child: Text("Tidak ada item ditemukan."));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final fileName = path.basename(item.path);
        final title = _fileTitles[fileName] ?? fileName;

        return ListTile(
          leading: Icon(item is Directory ? Icons.folder : Icons.description),
          title: Text(title),
          subtitle: title != fileName ? Text(fileName) : null,
          onTap: () => onTap(item),
        );
      },
    );
  }

  String get _title {
    if (_searchQuery.isNotEmpty) return 'Hasil Pencarian';
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
    if (_searchQuery.isNotEmpty) {
      _searchController.clear();
      return;
    }

    if (_currentView == _PickerViewState.files) {
      setState(() => _currentView = _PickerViewState.subjects);
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
      contentPadding: const EdgeInsets.all(0),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: _currentView == _PickerViewState.files
                      ? 'Cari di folder ini...'
                      : 'Cari di semua file...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_searchQuery.isEmpty) {
                    return _buildNavigationView();
                  } else if (_currentView == _PickerViewState.files) {
                    return _buildLocalSearchView();
                  } else {
                    return _buildGlobalSearchView();
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text('Pilih Folder PerpusKu'),
          onPressed: _selectPerpuskuDataFolder,
        ),
        // PERBAIKAN: Spacer dihapus dari sini untuk mencegah crash
        if (_currentView != _PickerViewState.topics || _searchQuery.isNotEmpty)
          TextButton(onPressed: _onBackPressed, child: const Text('Kembali')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
