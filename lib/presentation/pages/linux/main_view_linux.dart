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

  // Controller dan state untuk panel topik
  final TextEditingController _topicSearchController = TextEditingController();
  bool _isSearchingTopics = false;

  // Controller dan state untuk panel subjek
  final TextEditingController _subjectSearchController =
      TextEditingController();
  bool _isSearchingSubjects = false;

  // Kelola provider di level State untuk kontrol yang lebih baik
  SubjectProvider? _subjectProvider;
  DiscussionProvider? _discussionProvider;

  @override
  void initState() {
    super.initState();
    _subjectProvider = SubjectProvider('');

    _topicSearchController.addListener(() {
      Provider.of<TopicProvider>(
        context,
        listen: false,
      ).search(_topicSearchController.text);
    });

    _subjectSearchController.addListener(() {
      // Pastikan subjectProvider tidak null sebelum digunakan
      _subjectProvider?.search(_subjectSearchController.text);
    });
  }

  @override
  void dispose() {
    _topicSearchController.dispose();
    _subjectSearchController.dispose();
    super.dispose();
  }

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

        // Reset state pencarian subjek
        _isSearchingSubjects = false;
        _subjectSearchController.clear();

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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
            Expanded(flex: 3, child: _buildTopicsPanel(context)),
            const VerticalDivider(width: 1),
            Expanded(flex: 4, child: _buildSubjectsPanel(context)),
            const VerticalDivider(width: 1),
            Expanded(flex: 6, child: _buildDiscussionsPanel(context)),
          ],
        ),
      ),
    );
  }

  // ... _buildTopicsPanel dan _buildTopicsList tidak berubah ...
  /// Membangun panel daftar Topik (Panel 1).
  Widget _buildTopicsPanel(BuildContext context) {
    final topicProvider = Provider.of<TopicProvider>(context);

    if (topicProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: _isSearchingTopics
                    ? TextField(
                        controller: _topicSearchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Cari topik...',
                          border: InputBorder.none,
                        ),
                      )
                    : const Text(
                        "Topics",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (!topicProvider.isReorderModeEnabled)
                IconButton(
                  icon: Icon(_isSearchingTopics ? Icons.close : Icons.search),
                  tooltip: "Cari Topik",
                  onPressed: () {
                    setState(() {
                      _isSearchingTopics = !_isSearchingTopics;
                      if (!_isSearchingTopics) {
                        _topicSearchController.clear();
                      }
                    });
                  },
                ),
              if (!topicProvider.isReorderModeEnabled)
                IconButton(
                  icon: Icon(
                    topicProvider.showHiddenTopics
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  tooltip: topicProvider.showHiddenTopics
                      ? 'Sembunyikan Topik Tersembunyi'
                      : 'Tampilkan Topik Tersembunyi',
                  onPressed: () => topicProvider.toggleShowHidden(),
                ),
              IconButton(
                icon: Icon(
                  topicProvider.isReorderModeEnabled ? Icons.check : Icons.sort,
                ),
                tooltip: topicProvider.isReorderModeEnabled
                    ? 'Selesai Mengurutkan'
                    : 'Urutkan Topik',
                onPressed: () {
                  if (topicProvider.isReorderModeEnabled &&
                      _isSearchingTopics) {
                    setState(() {
                      _isSearchingTopics = false;
                      _topicSearchController.clear();
                    });
                  }
                  topicProvider.toggleReorderMode();
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: "Tambah Topik",
                onPressed: () => _addTopic(context, topicProvider),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildTopicsList(context, topicProvider)),
      ],
    );
  }

  Widget _buildTopicsList(BuildContext context, TopicProvider topicProvider) {
    if (topicProvider.allTopics.isEmpty) {
      return const Center(child: Text('Tidak ada topik untuk ditampilkan.'));
    }

    final topicsToShow = topicProvider.filteredTopics;
    final isSearching = topicProvider.searchQuery.isNotEmpty;
    final isReorderActive = topicProvider.isReorderModeEnabled && !isSearching;

    if (topicsToShow.isEmpty) {
      if (isSearching) {
        return const Center(child: Text('Topik tidak ditemukan.'));
      }
      if (!topicProvider.showHiddenTopics) {
        return const Center(
          child: Text(
            'Tidak ada topik terlihat.\nCoba tampilkan topik tersembunyi.',
            textAlign: TextAlign.center,
          ),
        );
      }
    }

    return ReorderableListView.builder(
      itemCount: topicsToShow.length,
      buildDefaultDragHandles: isReorderActive,
      itemBuilder: (context, index) {
        final topic = topicsToShow[index];
        return TopicListTile(
          key: ValueKey(topic.name),
          topic: topic,
          isReorderActive: isReorderActive,
          onTap: isReorderActive ? null : () => _onTopicSelected(topic),
          onRename: () => _renameTopic(context, topicProvider, topic),
          onDelete: () => _deleteTopic(context, topicProvider, topic),
          onIconChange: () => _changeIcon(context, topicProvider, topic),
          onToggleVisibility: () =>
              _toggleVisibility(context, topicProvider, topic),
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (isReorderActive) {
          topicProvider.reorderTopics(oldIndex, newIndex);
        }
      },
    );
  }

  /// Membangun panel daftar Subjek (Panel 2).
  Widget _buildSubjectsPanel(BuildContext context) {
    if (_selectedTopic == null) {
      return const Center(child: Text('Pilih sebuah topik dari panel kiri'));
    }

    // Consumer diperlukan agar SubjectProvider yang dinamis dapat diakses
    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
        return Column(
          children: [
            Padding(
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSearchingSubjects ? Icons.close : Icons.search,
                    ),
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
                    onPressed: () => _addSubject(context, subjectProvider),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildSubjectsList(context, subjectProvider)),
          ],
        );
      },
    );
  }

  /// Membangun daftar Subjek untuk Panel 2.
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
            'Tidak ada subjek terlihat.\nCoba tampilkan subjek tersembunyi.',
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
              onPressed: () => _addSubject(context, subjectProvider),
            ),
          ],
        ),
      );
    }

    // Karena ReorderableListView tidak diperlukan di sini, kita gunakan ListView.builder biasa.
    return ListView.builder(
      itemCount: subjectsToShow.length,
      itemBuilder: (context, index) {
        final subject = subjectsToShow[index];
        return SubjectListTile(
          key: ValueKey(subject.name),
          subject: subject,
          onTap: () => _onSubjectSelected(subject),
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

  /// Membangun panel halaman Diskusi (Panel 3).
  Widget _buildDiscussionsPanel(BuildContext context) {
    if (_selectedSubject == null) {
      return const Center(child: Text('Pilih sebuah subjek dari panel tengah'));
    }

    return Consumer<DiscussionProvider>(
      builder: (context, discussionProvider, child) {
        return DiscussionsPage(
          subjectName: _selectedSubject!.name,
          onFilterOrSortChanged: () {
            _subjectProvider?.fetchSubjects();
          },
        );
      },
    );
  }

  // ... (helper methods untuk dialog topik tidak berubah) ...
  // Helper methods untuk dialog topik
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

  Future<void> _renameTopic(
    BuildContext context,
    TopicProvider provider,
    Topic topic,
  ) async {
    await showTopicTextInputDialog(
      context: context,
      title: 'Ubah Nama Topik',
      label: 'Nama Baru',
      initialValue: topic.name,
      onSave: (newName) async {
        try {
          await provider.renameTopic(topic.name, newName);
          showAppSnackBar(context, 'Topik diubah menjadi "$newName".');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _deleteTopic(
    BuildContext context,
    TopicProvider provider,
    Topic topic,
  ) async {
    await showDeleteTopicConfirmationDialog(
      context: context,
      topicName: topic.name,
      onDelete: () async {
        try {
          await provider.deleteTopic(topic.name);
          showAppSnackBar(context, 'Topik "${topic.name}" berhasil dihapus.');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _changeIcon(
    BuildContext context,
    TopicProvider provider,
    Topic topic,
  ) async {
    await showIconPickerDialog(
      context: context,
      onIconSelected: (newIcon) async {
        try {
          await provider.updateTopicIcon(topic.name, newIcon);
          showAppSnackBar(context, 'Ikon untuk "${topic.name}" diubah.');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _toggleVisibility(
    BuildContext context,
    TopicProvider provider,
    Topic topic,
  ) async {
    final newVisibility = !topic.isHidden;
    try {
      await provider.toggleTopicVisibility(topic.name, newVisibility);
      final message = newVisibility ? 'disembunyikan' : 'ditampilkan kembali';
      showAppSnackBar(context, 'Topik "${topic.name}" berhasil $message.');
    } catch (e) {
      showAppSnackBar(context, e.toString(), isError: true);
    }
  }

  // Helper methods untuk dialog subjek
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
