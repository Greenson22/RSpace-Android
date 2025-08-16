// lib/presentation/pages/2_subjects_page.dart

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../data/models/subject_model.dart';
import '../providers/discussion_provider.dart';
import '../providers/subject_provider.dart';
import '3_discussions_page.dart';
import '2_subjects_page/dialogs/subject_dialogs.dart';
import '2_subjects_page/widgets/subject_grid_tile.dart'; // Impor widget baru
import '2_subjects_page/widgets/subject_list_tile.dart';

class SubjectsPage extends StatefulWidget {
  final String topicName;

  const SubjectsPage({super.key, required this.topicName});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    provider.fetchSubjects();
    _searchController.addListener(() {
      provider.search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _addSubject(BuildContext context) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await showSubjectTextInputDialog(
      context: context,
      title: 'Tambah Subject Baru',
      label: 'Nama Subject',
      onSave: (name) async {
        try {
          await provider.addSubject(name);
          _showSnackBar('Subject "$name" berhasil ditambahkan.');
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _renameSubject(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await showSubjectTextInputDialog(
      context: context,
      title: 'Ubah Nama Subject',
      label: 'Nama Baru',
      initialValue: subject.name,
      onSave: (newName) async {
        try {
          await provider.renameSubject(subject.name, newName);
          _showSnackBar('Subject berhasil diubah menjadi "$newName".');
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _deleteSubject(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await showDeleteConfirmationDialog(
      context: context,
      subjectName: subject.name,
      onDelete: () async {
        try {
          await provider.deleteSubject(subject.name);
          _showSnackBar('Subject "${subject.name}" berhasil dihapus.');
        } catch (e) {
          _showSnackBar(e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _changeIcon(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await showIconPickerDialog(
      context: context,
      onIconSelected: (newIcon) async {
        try {
          await provider.updateSubjectIcon(subject.name, newIcon);
          _showSnackBar('Ikon untuk "${subject.name}" diubah.');
        } catch (e) {
          _showSnackBar('Gagal mengubah ikon: ${e.toString()}', isError: true);
        }
      },
    );
  }

  Future<void> _toggleVisibility(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final newVisibility = !subject.isHidden;
    try {
      await provider.toggleSubjectVisibility(subject.name, newVisibility);
      final message = newVisibility ? 'disembunyikan' : 'ditampilkan kembali';
      _showSnackBar('Subject "${subject.name}" berhasil $message.');
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  void _navigateToDiscussionsPage(BuildContext context, Subject subject) {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final jsonFilePath = path.join(
      subjectProvider.topicPath,
      '${subject.name}.json',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => DiscussionProvider(jsonFilePath),
          child: DiscussionsPage(subjectName: subject.name),
        ),
      ),
    ).then((_) {
      // PERUBAHAN UTAMA: Panggil fetchSubjects() saat kembali dari DiscussionsPage
      subjectProvider.fetchSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? _buildSearchField()
            : Text(
                'Subjects: ${widget.topicName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          IconButton(
            icon: Icon(
              provider.showHiddenSubjects
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            onPressed: () => provider.toggleShowHidden(),
            tooltip: provider.showHiddenSubjects
                ? 'Sembunyikan Subjects Tersembunyi'
                : 'Tampilkan Subjects Tersembunyi',
          ),
        ],
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Jika lebar layar lebih dari 600, gunakan GridView.
          // Jika tidak, gunakan ListView.
          if (constraints.maxWidth > 600) {
            return _buildGridView(context);
          } else {
            return _buildListView(context);
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSubject(context),
        tooltip: 'Tambah Subject',
        icon: const Icon(Icons.add),
        label: const Text('Tambah Subject'),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Cari subject...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 18),
    );
  }

  // Method baru untuk membangun ListView (Tampilan Mobile)
  Widget _buildListView(BuildContext context) {
    return Consumer<SubjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.filteredSubjects.isEmpty) {
          return _buildEmptyState(provider);
        }
        final subjectsToShow = provider.filteredSubjects;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: subjectsToShow.length,
          itemBuilder: (context, index) {
            final subject = subjectsToShow[index];
            return SubjectListTile(
              key: ValueKey(subject.name),
              subject: subject,
              onTap: () => _navigateToDiscussionsPage(context, subject),
              onRename: () => _renameSubject(context, subject),
              onDelete: () => _deleteSubject(context, subject),
              onIconChange: () => _changeIcon(context, subject),
              onToggleVisibility: () => _toggleVisibility(context, subject),
            );
          },
        );
      },
    );
  }

  // Method baru untuk membangun GridView (Tampilan Desktop)
  Widget _buildGridView(BuildContext context) {
    return Consumer<SubjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.filteredSubjects.isEmpty) {
          return _buildEmptyState(provider);
        }
        final subjectsToShow = provider.filteredSubjects;
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (MediaQuery.of(context).size.width / 200).floor(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: subjectsToShow.length,
          itemBuilder: (context, index) {
            final subject = subjectsToShow[index];
            return SubjectGridTile(
              key: ValueKey(subject.name),
              subject: subject,
              onTap: () => _navigateToDiscussionsPage(context, subject),
              onRename: () => _renameSubject(context, subject),
              onDelete: () => _deleteSubject(context, subject),
              onIconChange: () => _changeIcon(context, subject),
              onToggleVisibility: () => _toggleVisibility(context, subject),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(SubjectProvider provider) {
    if (provider.allSubjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Subject',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambah subject di topik ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    final isSearching = provider.searchQuery.isNotEmpty;
    if (provider.filteredSubjects.isEmpty) {
      if (isSearching) {
        return const Center(child: Text('Subject tidak ditemukan.'));
      } else if (!provider.showHiddenSubjects) {
        return const Center(
          child: Text(
            'Tidak ada subject yang terlihat.\nCoba tampilkan subject tersembunyi.',
            textAlign: TextAlign.center,
          ),
        );
      }
    }
    return const SizedBox.shrink(); // Widget kosong jika tidak ada kondisi yang terpenuhi
  }
}
