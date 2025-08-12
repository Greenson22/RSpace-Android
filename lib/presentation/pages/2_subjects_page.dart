import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../data/models/subject_model.dart';
import '../providers/discussion_provider.dart';
import '../providers/subject_provider.dart';
import '3_discussions_page.dart';
import '2_subjects_page/dialogs/subject_dialogs.dart';
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

  void _navigateToDiscussionsPage(BuildContext context, Subject subject) {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final jsonFilePath = path.join(provider.topicPath, '${subject.name}.json');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => DiscussionProvider(jsonFilePath),
          child: DiscussionsPage(subjectName: subject.name),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: subjectProvider.isReorderModeEnabled
            ? const Text('Urutkan Subject')
            : (_isSearching
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
                  : Text('Subjects in ${widget.topicName}')),
        actions: [
          if (!subjectProvider.isReorderModeEnabled)
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
              subjectProvider.isReorderModeEnabled ? Icons.check : Icons.sort,
            ),
            onPressed: () {
              if (!subjectProvider.isReorderModeEnabled && _isSearching) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              }
              subjectProvider.toggleReorderMode();
            },
            tooltip: subjectProvider.isReorderModeEnabled
                ? 'Selesai Mengurutkan'
                : 'Urutkan Subject',
          ),
        ],
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.allSubjects.isEmpty) {
            return const Center(
              child: Text('Tidak ada subject. Tekan + untuk menambah.'),
            );
          }

          final subjectsToShow = provider.filteredSubjects;
          final isSearching = provider.searchQuery.isNotEmpty;
          final isReorderActive = provider.isReorderModeEnabled && !isSearching;

          if (subjectsToShow.isEmpty && isSearching) {
            return const Center(child: Text('Subject tidak ditemukan.'));
          }

          return ReorderableListView.builder(
            itemCount: subjectsToShow.length,
            buildDefaultDragHandles: isReorderActive,
            itemBuilder: (context, index) {
              final subject = subjectsToShow[index];
              return SubjectListTile(
                key: ValueKey(subject.name),
                subject: subject,
                onTap: isReorderActive
                    ? null
                    : () => _navigateToDiscussionsPage(context, subject),
                onRename: () => _renameSubject(context, subject),
                onDelete: () => _deleteSubject(context, subject),
                onIconChange: () => _changeIcon(context, subject),
                isReorderActive: isReorderActive,
              );
            },
            onReorder: (oldIndex, newIndex) {
              if (isReorderActive) {
                provider.reorderSubjects(oldIndex, newIndex);
              }
            },
          );
        },
      ),
      floatingActionButton: subjectProvider.isReorderModeEnabled
          ? null
          : FloatingActionButton(
              onPressed: () => _addSubject(context),
              tooltip: 'Tambah Subject',
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
