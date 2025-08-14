// lib/presentation/pages/linux/main_view_linux/subjects_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/subject_model.dart';
import '../../../providers/subject_provider.dart';
import '../../1_topics_page/utils/scaffold_messenger_utils.dart';
import '../../2_subjects_page/dialogs/subject_dialogs.dart' as subject_dialogs;
import '../../2_subjects_page/widgets/subject_list_tile.dart';

class SubjectsPanel extends StatefulWidget {
  final SubjectProvider? subjectProvider;
  final Function(Subject) onSubjectSelected;
  final VoidCallback onAddSubject;

  const SubjectsPanel({
    super.key,
    required this.subjectProvider,
    required this.onSubjectSelected,
    required this.onAddSubject,
  });

  @override
  State<SubjectsPanel> createState() => _SubjectsPanelState();
}

class _SubjectsPanelState extends State<SubjectsPanel> {
  final TextEditingController _subjectSearchController =
      TextEditingController();
  bool _isSearchingSubjects = false;

  @override
  void initState() {
    super.initState();
    _subjectSearchController.addListener(() {
      widget.subjectProvider?.search(_subjectSearchController.text);
    });
  }

  @override
  void dispose() {
    _subjectSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjectProvider == null) {
      return const Center(child: Text('Pilih sebuah topik dari panel kiri'));
    }

    return ChangeNotifierProvider.value(
      value: widget.subjectProvider!,
      child: Consumer<SubjectProvider>(
        builder: (context, subjectProvider, child) {
          return Column(
            children: [
              _buildSubjectsToolbar(context, subjectProvider),
              const Divider(height: 1),
              Expanded(child: _buildSubjectsList(context, subjectProvider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubjectsToolbar(
    BuildContext context,
    SubjectProvider subjectProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: _isSearchingSubjects
                ? TextField(
                    controller: _subjectSearchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Cari subjek...',
                      border: InputBorder.none,
                    ),
                  )
                : const Text(
                    "Subjects",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
          IconButton(
            icon: Icon(_isSearchingSubjects ? Icons.close : Icons.search),
            tooltip: "Cari Subjek",
            onPressed: () {
              setState(() {
                _isSearchingSubjects = !_isSearchingSubjects;
                if (!_isSearchingSubjects) {
                  _subjectSearchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              subjectProvider.showHiddenSubjects
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            tooltip: subjectProvider.showHiddenSubjects
                ? 'Sembunyikan Subjek Tersembunyi'
                : 'Tampilkan Subjek Tersembunyi',
            onPressed: () => subjectProvider.toggleShowHidden(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Tambah Subjek",
            onPressed: widget.onAddSubject,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList(
    BuildContext context,
    SubjectProvider subjectProvider,
  ) {
    if (subjectProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (subjectProvider.topicPath.isEmpty) {
      return const Center(child: Text('Memuat subjek...'));
    }

    final subjectsToShow = subjectProvider.filteredSubjects;
    final isSearching = subjectProvider.searchQuery.isNotEmpty;

    if (subjectsToShow.isEmpty) {
      if (isSearching) {
        return const Center(child: Text('Subjek tidak ditemukan.'));
      }
      if (!subjectProvider.showHiddenSubjects) {
        return const Center(
          child: Text(
            'Tidak ada subjek terlihat.\\nCoba tampilkan subjek tersembunyi.',
            textAlign: TextAlign.center,
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tidak ada subjek.'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tambah Subjek'),
              onPressed: widget.onAddSubject,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: subjectsToShow.length,
      itemBuilder: (context, index) {
        final subject = subjectsToShow[index];
        return SubjectListTile(
          key: ValueKey(subject.name),
          subject: subject,
          onTap: () => widget.onSubjectSelected(subject),
          onRename: () => _renameSubject(context, subjectProvider, subject),
          onDelete: () => _deleteSubject(context, subjectProvider, subject),
          onIconChange: () =>
              _changeSubjectIcon(context, subjectProvider, subject),
          onToggleVisibility: () =>
              _toggleSubjectVisibility(context, subjectProvider, subject),
        );
      },
    );
  }

  Future<void> _renameSubject(
    BuildContext context,
    SubjectProvider provider,
    Subject subject,
  ) async {
    await subject_dialogs.showSubjectTextInputDialog(
      context: context,
      title: 'Ubah Nama Subject',
      label: 'Nama Baru',
      initialValue: subject.name,
      onSave: (newName) async {
        try {
          await provider.renameSubject(subject.name, newName);
          showAppSnackBar(
            context,
            'Subject berhasil diubah menjadi "$newName".',
          );
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _deleteSubject(
    BuildContext context,
    SubjectProvider provider,
    Subject subject,
  ) async {
    await subject_dialogs.showDeleteConfirmationDialog(
      context: context,
      subjectName: subject.name,
      onDelete: () async {
        try {
          await provider.deleteSubject(subject.name);
          showAppSnackBar(
            context,
            'Subject "${subject.name}" berhasil dihapus.',
          );
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _changeSubjectIcon(
    BuildContext context,
    SubjectProvider provider,
    Subject subject,
  ) async {
    await subject_dialogs.showIconPickerDialog(
      context: context,
      onIconSelected: (newIcon) async {
        try {
          await provider.updateSubjectIcon(subject.name, newIcon);
          showAppSnackBar(context, 'Ikon untuk "${subject.name}" diubah.');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _toggleSubjectVisibility(
    BuildContext context,
    SubjectProvider provider,
    Subject subject,
  ) async {
    final newVisibility = !subject.isHidden;
    try {
      await provider.toggleSubjectVisibility(subject.name, newVisibility);
      final message = newVisibility ? 'disembunyikan' : 'ditampilkan kembali';
      showAppSnackBar(context, 'Subject "${subject.name}" berhasil $message.');
    } catch (e) {
      showAppSnackBar(context, e.toString(), isError: true);
    }
  }
}
