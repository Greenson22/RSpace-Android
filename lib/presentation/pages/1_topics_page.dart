import 'dart:io';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../data/services/local_file_service.dart';
import '../providers/subject_provider.dart';
import '../providers/theme_provider.dart';
import '2_subjects_page.dart';
import '1_topics_page/dialogs/topic_dialogs.dart';
import '1_topics_page/widgets/topic_list_tile.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart'; // Import file utils

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

  Future<void> _addTopic() async {
    await showTopicTextInputDialog(
      context: context,
      title: 'Tambah Topik Baru',
      label: 'Nama Topik',
      onSave: (name) async {
        try {
          await _fileService.addTopic(name);
          showAppSnackBar(context, 'Topik "$name" berhasil ditambahkan.');
          _refreshTopics();
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _renameTopic(String oldName) async {
    await showTopicTextInputDialog(
      context: context,
      title: 'Ubah Nama Topik',
      label: 'Nama Baru',
      initialValue: oldName,
      onSave: (newName) async {
        try {
          await _fileService.renameTopic(oldName, newName);
          showAppSnackBar(context, 'Topik berhasil diubah menjadi "$newName".');
          _refreshTopics();
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _deleteTopic(String topicName) async {
    await showDeleteTopicConfirmationDialog(
      context: context,
      topicName: topicName,
      onDelete: () async {
        try {
          await _fileService.deleteTopic(topicName);
          showAppSnackBar(context, 'Topik "$topicName" berhasil dihapus.');
          _refreshTopics();
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _backupContents() async {
    setState(() {
      _isBackingUp = true;
    });
    showAppSnackBar(context, 'Memulai proses backup...');

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

      String? savedPath = await FileSaver.instance.saveAs(
        name: zipFileName,
        bytes: await zipFile.readAsBytes(),
        fileExtension: 'zip',
        mimeType: MimeType.zip,
      );

      if (savedPath != null) {
        showAppSnackBar(
          context,
          'Backup berhasil disimpan di folder Downloads',
        );
      } else {
        showAppSnackBar(context, 'Backup dibatalkan atau gagal disimpan.');
      }
      await tempDir.delete(recursive: true);
    } catch (e) {
      showAppSnackBar(context, 'Terjadi error saat backup: $e', isError: true);
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
              return TopicListTile(
                topicName: folderName,
                onTap: () {
                  final folderPath = path.join(
                    _fileService.getTopicsPath(),
                    folderName,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => SubjectProvider(folderPath),
                        child: SubjectsPage(topicName: folderName),
                      ),
                    ),
                  );
                },
                onRename: () => _renameTopic(folderName),
                onDelete: () => _deleteTopic(folderName),
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
