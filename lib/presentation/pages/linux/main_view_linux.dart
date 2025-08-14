// lib/presentation/pages/linux/main_view_linux.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

import '../../../data/models/topic_model.dart';
import '../../../data/models/subject_model.dart';
import '../../providers/topic_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/discussion_provider.dart';
import '../1_topics_page/widgets/topic_list_tile.dart';
import '../2_subjects_page/widgets/subject_list_tile.dart';
import '../3_discussions_page.dart';
import '../1_topics_page/dialogs/topic_dialogs.dart'; // Impor untuk dialog
import '../2_subjects_page/dialogs/subject_dialogs.dart'
    as subject_dialogs; // Impor untuk dialog subjek
import 'package:my_aplication/presentation/pages/1_topics_page/utils/scaffold_messenger_utils.dart'; // Impor untuk snackbar

/// A view that combines Topics, Subjects, and Discussions in a three-panel layout for Linux.
class MainViewLinux extends StatefulWidget {
  const MainViewLinux({super.key});

  @override
  State<MainViewLinux> createState() => _MainViewLinuxState();
}

class _MainViewLinuxState extends State<MainViewLinux> {
  Topic? _selectedTopic;
  Subject? _selectedSubject;

  // Kelola provider di level State untuk kontrol yang lebih baik
  SubjectProvider? _subjectProvider;
  DiscussionProvider? _discussionProvider;

  @override
  void initState() {
    super.initState();
    // Inisialisasi provider dengan path kosong. Akan diperbarui saat topik dipilih.
    _subjectProvider = SubjectProvider('');
  }

  /// Dipanggil ketika pengguna memilih sebuah topik dari daftar.
  void _onTopicSelected(Topic topic) async {
    final topicProvider = Provider.of<TopicProvider>(context, listen: false);
    try {
      // Ambil path dasar untuk semua topik secara asinkron
      final topicsPath = await topicProvider.getTopicsPath();
      final newTopicPath = path.join(topicsPath, topic.name);

      setState(() {
        _selectedTopic = topic;
        _selectedSubject = null; // Reset subjek saat topik berganti
        _discussionProvider = null; // Reset diskusi

        // Buat instance SubjectProvider baru dengan path yang benar
        _subjectProvider = SubjectProvider(newTopicPath);
        // Langsung panggil fetchSubjects untuk memuat data di panel kedua
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
      // Buat instance DiscussionProvider baru
      _discussionProvider = DiscussionProvider(subjectJsonPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan MultiProvider untuk menyediakan provider yang dibuat secara dinamis
    return MultiProvider(
      providers: [
        // .value constructor digunakan karena kita mengelola instance provider sendiri
        if (_subjectProvider != null)
          ChangeNotifierProvider.value(value: _subjectProvider!),
        if (_discussionProvider != null)
          ChangeNotifierProvider.value(value: _discussionProvider!),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'RSpace: ${_selectedTopic?.name ?? "Pilih Topik"} / ${_selectedSubject?.name ?? "Pilih Subjek"}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Row(
          children: [
            // Panel 1: Topics
            Expanded(flex: 3, child: _buildTopicsPanel(context)),
            const VerticalDivider(width: 1),

            // Panel 2: Subjects
            Expanded(flex: 4, child: _buildSubjectsPanel(context)),
            const VerticalDivider(width: 1),

            // Panel 3: Discussions
            Expanded(flex: 6, child: _buildDiscussionsPanel(context)),
          ],
        ),
      ),
    );
  }

  /// Membangun panel daftar Topik (Panel 1).
  Widget _buildTopicsPanel(BuildContext context) {
    final topicProvider = Provider.of<TopicProvider>(context);

    if (topicProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (topicProvider.allTopics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tidak ada topik.'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tambah Topik'),
              onPressed: () => _addTopic(context, topicProvider),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Topics",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: "Tambah Topik",
                onPressed: () => _addTopic(context, topicProvider),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: topicProvider.filteredTopics.length,
            itemBuilder: (context, index) {
              final topic = topicProvider.filteredTopics[index];
              return TopicListTile(
                topic: topic,
                onTap: () => _onTopicSelected(topic),
                // Aksi-aksi ini sekarang hanya placeholder, perlu implementasi dialog jika diperlukan
                onRename: () {},
                onDelete: () {},
                onIconChange: () {},
                onToggleVisibility: () {},
              );
            },
          ),
        ),
      ],
    );
  }

  /// Membangun panel daftar Subjek (Panel 2).
  Widget _buildSubjectsPanel(BuildContext context) {
    if (_selectedTopic == null) {
      return const Center(child: Text('Pilih sebuah topik dari panel kiri'));
    }

    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
        if (subjectProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (subjectProvider.topicPath.isEmpty) {
          return const Center(child: Text('Memuat subjek...'));
        }
        if (subjectProvider.allSubjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Tidak ada subjek.'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Subjek'),
                  onPressed: () => _addSubject(context, subjectProvider),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Subjects",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: "Tambah Subjek",
                    onPressed: () => _addSubject(context, subjectProvider),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: subjectProvider.filteredSubjects.length,
                itemBuilder: (context, index) {
                  final subject = subjectProvider.filteredSubjects[index];
                  return SubjectListTile(
                    subject: subject,
                    onTap: () => _onSubjectSelected(subject),
                    // Aksi-aksi ini sekarang hanya placeholder
                    onRename: () {},
                    onDelete: () {},
                    onIconChange: () {},
                    onToggleVisibility: () {},
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Membangun panel halaman Diskusi (Panel 3).
  Widget _buildDiscussionsPanel(BuildContext context) {
    if (_selectedSubject == null) {
      return const Center(child: Text('Pilih sebuah subjek dari panel tengah'));
    }

    // Consumer diperlukan agar DiscussionProvider dapat ditemukan dalam konteks
    return Consumer<DiscussionProvider>(
      builder: (context, discussionProvider, child) {
        // Menggunakan kembali widget DiscussionsPage yang sudah ada
        return DiscussionsPage(
          subjectName: _selectedSubject!.name,
          // Callback ini penting untuk me-refresh daftar subjek jika filter/sort diskusi
          // berpotensi mengubah data yang ditampilkan di panel subjek.
          onFilterOrSortChanged: () {
            _subjectProvider?.fetchSubjects();
          },
        );
      },
    );
  }

  // Helper methods untuk dialog
  Future<void> _addTopic(BuildContext context, TopicProvider provider) async {
    await showTopicTextInputDialog(
      context: context,
      title: 'Tambah Topik Baru',
      label: 'Nama Topik',
      onSave: (name) async {
        try {
          await provider.addTopic(name);
          showAppSnackBar(context, 'Topik "$name" berhasil ditambahkan.');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

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
}
