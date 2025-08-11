import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../data/services/local_file_service.dart';
import '2_subjects_page.dart';

class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  final LocalFileService _fileService = LocalFileService();
  late Future<List<String>> _folderListFuture;

  @override
  void initState() {
    super.initState();
    _refreshTopics();
  }

  void _refreshTopics() {
    setState(() {
      _folderListFuture = _fileService.getTopics();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Topics')),
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

          final folders = snapshot.data!;
          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folderName = folders[index];
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
    );
  }
}
