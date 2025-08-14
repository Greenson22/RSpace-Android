// lib/presentation/pages/linux/main_view_linux.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/presentation/pages/1_topics_page/utils/scaffold_messenger_utils.dart'; // Impor untuk snackbar
import 'package:my_aplication/presentation/pages/3_discussions_page/dialogs/discussion_dialogs.dart'; // Impor untuk dialog diskusi
import 'package:my_aplication/presentation/pages/2_subjects_page/dialogs/subject_dialogs.dart'
    as subject_dialogs; // Impor untuk dialog subjek

import '../../../data/models/topic_model.dart';
import '../../../data/models/subject_model.dart';
import '../../providers/topic_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/discussion_provider.dart';

// Impor panel yang baru dibuat
import 'main_view_linux/topics_panel.dart';
import 'main_view_linux/subjects_panel.dart';
import 'main_view_linux/discussions_panel.dart';

/// A view that combines Topics, Subjects, and Discussions in a three-panel layout for Linux.
class MainViewLinux extends StatefulWidget {
  const MainViewLinux({super.key});

  @override
  State<MainViewLinux> createState() => _MainViewLinuxState();
}

class _MainViewLinuxState extends State<MainViewLinux> {
  Topic? _selectedTopic;
  Subject? _selectedSubject;

  SubjectProvider? _subjectProvider;
  DiscussionProvider? _discussionProvider;

  /// Dipanggil ketika pengguna memilih sebuah topik dari daftar.
  void _onTopicSelected(Topic topic) async {
    final topicProvider = Provider.of<TopicProvider>(context, listen: false);
    try {
      final topicsPath = await topicProvider.getTopicsPath();
      final newTopicPath = path.join(topicsPath, topic.name);

      setState(() {
        _selectedTopic = topic;
        _selectedSubject = null;
        _discussionProvider = null;

        _subjectProvider = SubjectProvider(newTopicPath);
        _subjectProvider!.fetchSubjects();
      });
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Error: Gagal mendapatkan path topik. $e',
          isError: true,
        );
      }
    }
  }

  /// Dipanggil ketika pengguna memilih sebuah subjek dari daftar.
  void _onSubjectSelected(Subject subject) {
    final subjectPath = _subjectProvider?.topicPath;
    if (subjectPath == null || subjectPath.isEmpty) return;

    final subjectJsonPath = path.join(subjectPath, '${subject.name}.json');

    setState(() {
      _selectedSubject = subject;
      _discussionProvider = DiscussionProvider(subjectJsonPath);
    });
  }

  void _onAddSubject() {
    if (_subjectProvider == null) return;
    _addSubject(context, _subjectProvider!);
  }

  void _onAddDiscussion() {
    if (_discussionProvider == null) return;
    _addDiscussion(context, _discussionProvider!);
  }

  void _onFilterOrSortChanged() {
    _subjectProvider?.fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RSpace: ${_selectedTopic?.name ?? "Pilih Topik"} / ${_selectedSubject?.name ?? "Pilih Subjek"}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: TopicsPanel(onTopicSelected: _onTopicSelected),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 4,
            child: SubjectsPanel(
              subjectProvider: _subjectProvider,
              onSubjectSelected: _onSubjectSelected,
              onAddSubject: _onAddSubject,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 6,
            child: DiscussionsPanel(
              discussionProvider: _discussionProvider,
              selectedSubjectName: _selectedSubject?.name,
              onAddDiscussion: _onAddDiscussion,
              onFilterOrSortChanged: _onFilterOrSortChanged,
            ),
          ),
        ],
      ),
    );
  }

  // --- Logika Dialog Tetap di Sini untuk Mengakses Provider ---
  Future<void> _addSubject(
    BuildContext context,
    SubjectProvider provider,
  ) async {
    await subject_dialogs.showSubjectTextInputDialog(
      context: context,
      title: 'Tambah Subject Baru',
      label: 'Nama Subject',
      onSave: (name) async {
        try {
          await provider.addSubject(name);
          showAppSnackBar(context, 'Subject "$name" berhasil ditambahkan.');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  void _addDiscussion(BuildContext context, DiscussionProvider provider) {
    showTextInputDialog(
      context: context,
      title: 'Tambah Diskusi Baru',
      label: 'Nama Diskusi',
      onSave: (name) {
        provider.addDiscussion(name);
        showAppSnackBar(context, 'Diskusi "$name" berhasil ditambahkan.');
      },
    );
  }
}
