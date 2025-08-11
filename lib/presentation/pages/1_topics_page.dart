import 'dart:io';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../data/services/local_file_service.dart';
import '../providers/theme_provider.dart';
import '2_subjects_page.dart';

class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  final LocalFileService _fileService = LocalFileService();
  late Future<List<String>> _folderListFuture;
  final TextEditingController _searchController = TextEditingController();
  List<String> _allTopics = [];
  List<String> _filteredTopics = [];
  bool _isSearching = false;
  bool _isBackingUp = false;

  @override
  void initState() {
    super.initState();
    _refreshTopics();
    _searchController.addListener(_filterTopics);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshTopics() {
    setState(() {
      _folderListFuture = _fileService.getTopics();
    });
  }

  void _filterTopics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTopics = _allTopics
          .where((topic) => topic.toLowerCase().contains(query))
          .toList();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _showTextInputDialog({
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
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addTopic() async {
    await _showTextInputDialog(
      title: 'Tambah Topik Baru',
      label: 'Nama Topik',
      onSave: (name) async {
        try {
          await _fileService.addTopic(name);
          _showSnackBar('Topik "$name" berhasil ditambahkan.');
          _refreshTopics();
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _renameTopic(String oldName) async {
    await _showTextInputDialog(
      title: 'Ubah Nama Topik',
      label: 'Nama Baru',
      initialValue: oldName,
      onSave: (newName) async {
        try {
          await _fileService.renameTopic(oldName, newName);
          _showSnackBar('Topik berhasil diubah menjadi "$newName".');
          _refreshTopics();
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _deleteTopic(String topicName) async {
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
              onPressed: () async {
                try {
                  await _fileService.deleteTopic(topicName);
                  _showSnackBar('Topik "$topicName" berhasil dihapus.');
                  _refreshTopics();
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  _showSnackBar(e.toString(), isError: true);
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _backupContents() async {
    setState(() {
      _isBackingUp = true;
    });
    _showSnackBar('Memulai proses backup...', isError: false);

    try {
      final contentsPath = _fileService.getContentsPath();
      final sourceDir = Directory(contentsPath);

      if (!await sourceDir.exists()) {
        throw Exception('Direktori "contents" tidak ditemukan.');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final zipFileName = 'backup_contents_$timestamp.zip';

      final tempDir = await Directory.systemTemp.createTemp();
      final zipFile = File(path.join(tempDir.path, zipFileName));

      await ZipFile.createFromDirectory(
        sourceDir: sourceDir,
        zipFile: zipFile,
        recurseSubDirs: true,
      );

      // Mengubah 'ext' menjadi 'fileExtension'
      String? savedPath = await FileSaver.instance.saveAs(
        name: zipFileName,
        bytes: await zipFile.readAsBytes(),
        fileExtension: 'zip', // <-- PERUBAHAN DI SINI
        mimeType: MimeType.zip,
      );

      if (savedPath != null) {
        _showSnackBar('Backup berhasil disimpan di folder Downloads');
      } else {
        _showSnackBar('Backup dibatalkan atau gagal disimpan.');
      }
      await tempDir.delete(recursive: true);
    } catch (e) {
      _showSnackBar('Terjadi error saat backup: $e', isError: true);
    } finally {
      setState(() {
        _isBackingUp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari topik...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : const Text('Topics'),
        actions: [
          if (_isBackingUp)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.backup),
              onPressed: _backupContents,
              tooltip: 'Backup Seluruh Konten',
            ),
          IconButton(
            icon: Icon(
              themeProvider.darkTheme ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            onPressed: () {
              themeProvider.darkTheme = !themeProvider.darkTheme;
            },
            tooltip: 'Ganti Tema',
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _folderListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Tidak ada topik. Tekan + untuk menambah.'),
            );
          }

          _allTopics = snapshot.data!;
          final topicsToShow = _searchController.text.isEmpty
              ? _allTopics
              : _filteredTopics;

          if (topicsToShow.isEmpty && _searchController.text.isNotEmpty) {
            return const Center(child: Text('Topik tidak ditemukan.'));
          }

          return ListView.builder(
            itemCount: topicsToShow.length,
            itemBuilder: (context, index) {
              final folderName = topicsToShow[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.folder_open, color: Colors.teal),
                  title: Text(folderName),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubjectsPage(
                          folderPath: path.join(
                            _fileService.getTopicsPath(),
                            folderName,
                          ),
                          topicName: folderName,
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') _renameTopic(folderName);
                      if (value == 'delete') _deleteTopic(folderName);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Ubah Nama'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTopic,
        tooltip: 'Tambah Topik',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
