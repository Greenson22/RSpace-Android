import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

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
  // ==> TAMBAHKAN CONTROLLER DAN STATE UNTUK PENCARIAN <==
  final TextEditingController _searchController = TextEditingController();
  List<File> _filteredFiles = [];
  String _searchQuery = '';

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTopics();
    // ==> TAMBAHKAN LISTENER UNTUK PENCARIAN <==
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterFiles();
      });
    });
  }

  // ==> TAMBAHKAN FUNGSI DISPOSE UNTUK MEMBERSIHKAN CONTROLLER <==
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
        throw Exception(
          "Direktori base PerpusKu tidak ditemukan:\n${widget.basePath}",
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
    });
    try {
      final filesDir = Directory(subjectPath);
      final items = filesDir.listSync();
      _files = items
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.html'))
          .toList();
      // ==> INISIALISASI FILE YANG DIFILTER <==
      _filteredFiles = _files;
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  // ==> FUNGSI BARU UNTUK MELAKUKAN FILTER <==
  void _filterFiles() {
    if (_searchQuery.isEmpty) {
      _filteredFiles = _files;
    } else {
      _filteredFiles = _files
          .where(
            (file) =>
                path.basename(file.path).toLowerCase().contains(_searchQuery),
          )
          .toList();
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          "Error: $_error",
          style: const TextStyle(color: Colors.red),
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
        // ==> MODIFIKASI TAMPILAN FILE UNTUK MENAMBAHKAN PENCARIAN <==
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari file...',
                  hintText: 'Masukkan nama file',
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
        return ListTile(
          leading: Icon(item is Directory ? Icons.folder : Icons.description),
          title: Text(path.basename(item.path)),
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
        _searchController.clear(); // Bersihkan pencarian saat kembali
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
      // ==> PERBESAR SEDIKIT TINGGI DIALOG UNTUK SEARCH BAR <==
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: _buildContent(),
      ),
      actions: [
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
