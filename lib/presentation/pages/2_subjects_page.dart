import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../data/services/local_file_service.dart';
import '3_discussions_page.dart';

class SubjectsPage extends StatefulWidget {
  final String folderPath;
  final String topicName;

  const SubjectsPage({
    super.key,
    required this.folderPath,
    required this.topicName,
  });

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final LocalFileService _fileService = LocalFileService();
  late Future<List<String>> _jsonFilesFuture;

  @override
  void initState() {
    super.initState();
    _refreshSubjects();
  }

  void _refreshSubjects() {
    setState(() {
      _jsonFilesFuture = _fileService.getSubjects(widget.folderPath);
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

  Future<void> _addSubject() async {
    await _showTextInputDialog(
      title: 'Tambah Subject Baru',
      label: 'Nama Subject',
      onSave: (name) async {
        try {
          await _fileService.addSubject(widget.folderPath, name);
          _showSnackBar('Subject "$name" berhasil ditambahkan.');
          _refreshSubjects();
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _renameSubject(String oldName) async {
    await _showTextInputDialog(
      title: 'Ubah Nama Subject',
      label: 'Nama Baru',
      initialValue: oldName,
      onSave: (newName) async {
        try {
          await _fileService.renameSubject(widget.folderPath, oldName, newName);
          _showSnackBar('Subject berhasil diubah menjadi "$newName".');
          _refreshSubjects();
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _deleteSubject(String subjectName) async {
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
              onPressed: () async {
                try {
                  await _fileService.deleteSubject(
                    widget.folderPath,
                    subjectName,
                  );
                  _showSnackBar('Subject "$subjectName" berhasil dihapus.');
                  _refreshSubjects();
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
      appBar: AppBar(title: Text('Subjects in ${widget.topicName}')),
      body: FutureBuilder<List<String>>(
        future: _jsonFilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Tidak ada subject. Tekan + untuk menambah.'),
            );
          }

          final files = snapshot.data!;
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final subjectName = files[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.orange),
                  title: Text(subjectName),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiscussionsPage(
                          jsonFilePath: path.join(
                            widget.folderPath,
                            '$subjectName.json',
                          ),
                          subjectName: subjectName,
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') _renameSubject(subjectName);
                      if (value == 'delete') _deleteSubject(subjectName);
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
        onPressed: _addSubject,
        tooltip: 'Tambah Subject',
        child: const Icon(Icons.add),
      ),
    );
  }
}
