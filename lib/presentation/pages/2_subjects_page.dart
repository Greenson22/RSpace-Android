import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../data/services/local_file_service.dart';
import '../providers/discussion_provider.dart';
import '3_discussions_page.dart';
import '2_subjects_page/dialogs/subject_dialogs.dart';
import '2_subjects_page/widgets/subject_list_tile.dart';

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
  final TextEditingController _searchController = TextEditingController();
  List<String> _allSubjects = [];
  List<String> _filteredSubjects = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _refreshSubjects();
    _searchController.addListener(_filterSubjects);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshSubjects() {
    setState(() {
      _jsonFilesFuture = _fileService.getSubjects(widget.folderPath);
    });
  }

  void _filterSubjects() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSubjects = _allSubjects
          .where((subject) => subject.toLowerCase().contains(query))
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

  Future<void> _addSubject() async {
    await showSubjectTextInputDialog(
      context: context,
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
    await showSubjectTextInputDialog(
      context: context,
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
    await showDeleteConfirmationDialog(
      context: context,
      subjectName: subjectName,
      onDelete: () async {
        try {
          await _fileService.deleteSubject(widget.folderPath, subjectName);
          _showSnackBar('Subject "$subjectName" berhasil dihapus.');
          _refreshSubjects();
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      },
    );
  }

  void _navigateToDiscussionsPage(String subjectName) {
    final jsonFilePath = path.join(widget.folderPath, '$subjectName.json');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => DiscussionProvider(jsonFilePath),
          child: DiscussionsPage(subjectName: subjectName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari subject...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : Text('Subjects in ${widget.topicName}'),
        actions: [
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

          _allSubjects = snapshot.data!;
          final subjectsToShow = _searchController.text.isEmpty
              ? _allSubjects
              : _filteredSubjects;

          if (subjectsToShow.isEmpty && _searchController.text.isNotEmpty) {
            return const Center(child: Text('Subject tidak ditemukan.'));
          }

          return ListView.builder(
            itemCount: subjectsToShow.length,
            itemBuilder: (context, index) {
              final subjectName = subjectsToShow[index];
              return SubjectListTile(
                subjectName: subjectName,
                onTap: () => _navigateToDiscussionsPage(subjectName),
                onRename: () => _renameSubject(subjectName),
                onDelete: () => _deleteSubject(subjectName),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
