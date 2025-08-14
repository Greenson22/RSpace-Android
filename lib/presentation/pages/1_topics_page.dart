// lib/presentation/pages/1_topics_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../data/models/topic_model.dart';
import '../providers/subject_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/topic_provider.dart';
import '2_subjects_page.dart';
import '1_topics_page/dialogs/topic_dialogs.dart';
import '1_topics_page/widgets/topic_list_tile.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';

class TopicsPage extends StatelessWidget {
  const TopicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // DIUBAH: ChangeNotifierProvider dihapus dari sini.
    // Provider sekarang diambil dari level atas (main.dart).
    return const _TopicsPageContent();
  }
}

class _TopicsPageContent extends StatefulWidget {
  const _TopicsPageContent();

  @override
  State<_TopicsPageContent> createState() => _TopicsPageContentState();
}

class _TopicsPageContentState extends State<_TopicsPageContent> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // DIUBAH: Sekarang aman untuk memanggil provider di initState
    // karena provider sudah ada sebelum widget ini dibuat.
    // Namun, kita tidak perlu memanggil fetchTopics() di sini karena
    // constructor TopicProvider sudah melakukannya.
    final topicProvider = Provider.of<TopicProvider>(context, listen: false);
    _searchController.addListener(() {
      topicProvider.search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addTopic(BuildContext context) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
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

  Future<void> _renameTopic(BuildContext context, Topic topic) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
    await showTopicTextInputDialog(
      context: context,
      title: 'Ubah Nama Topik',
      label: 'Nama Baru',
      initialValue: topic.name,
      onSave: (newName) async {
        try {
          await provider.renameTopic(topic.name, newName);
          showAppSnackBar(context, 'Topik berhasil diubah menjadi "$newName".');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _deleteTopic(BuildContext context, Topic topic) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
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

  Future<void> _changeIcon(BuildContext context, Topic topic) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
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

  // ==> FUNGSI BARU <==
  Future<void> _toggleVisibility(BuildContext context, Topic topic) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
    final newVisibility = !topic.isHidden;
    try {
      await provider.toggleTopicVisibility(topic.name, newVisibility);
      final message = newVisibility ? 'disembunyikan' : 'ditampilkan kembali';
      showAppSnackBar(context, 'Topik "${topic.name}" berhasil $message.');
    } catch (e) {
      showAppSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicProvider = Provider.of<TopicProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: topicProvider.isReorderModeEnabled
            ? const Text('Urutkan Topik')
            : (_isSearching
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
                  : const Text('Topics')),
        actions: [
          if (!topicProvider.isReorderModeEnabled) ...[
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) _searchController.clear();
                });
              },
            ),
            // ==> TOMBOL BARU UNTUK MENAMPILKAN/SEMBUNYIKAN TOPIK <==
            IconButton(
              icon: Icon(
                topicProvider.showHiddenTopics
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () => topicProvider.toggleShowHidden(),
              tooltip: topicProvider.showHiddenTopics
                  ? 'Sembunyikan Topik Tersembunyi'
                  : 'Tampilkan Topik Tersembunyi',
            ),
          ],
          IconButton(
            icon: Icon(
              topicProvider.isReorderModeEnabled ? Icons.check : Icons.sort,
            ),
            onPressed: () {
              if (!topicProvider.isReorderModeEnabled && _isSearching) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              }
              topicProvider.toggleReorderMode();
            },
            tooltip: topicProvider.isReorderModeEnabled
                ? 'Selesai Mengurutkan'
                : 'Urutkan Topik',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: topicProvider.isReorderModeEnabled
          ? null
          : FloatingActionButton(
              onPressed: () => _addTopic(context),
              tooltip: 'Tambah Topik',
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    return Consumer<TopicProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.allTopics.isEmpty) {
          return const Center(
            child: Text('Tidak ada topik. Tekan + untuk menambah.'),
          );
        }

        final topicsToShow = provider.filteredTopics;
        final isSearching = provider.searchQuery.isNotEmpty;
        final isReorderActive = provider.isReorderModeEnabled && !isSearching;

        if (topicsToShow.isEmpty && isSearching) {
          return const Center(child: Text('Topik tidak ditemukan.'));
        }
        if (topicsToShow.isEmpty && !provider.showHiddenTopics) {
          return const Center(
            child: Text(
              'Tidak ada topik yang terlihat. Coba tampilkan topik tersembunyi.',
            ),
          );
        }

        return ReorderableListView.builder(
          itemCount: topicsToShow.length,
          buildDefaultDragHandles: isReorderActive,
          itemBuilder: (context, index) {
            final topic = topicsToShow[index];
            return TopicListTile(
              key: ValueKey(topic.name),
              topic: topic,
              onTap: isReorderActive
                  ? null
                  : () async {
                      final topicsPath = await provider.getTopicsPath();
                      final folderPath = path.join(topicsPath, topic.name);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider(
                            create: (_) => SubjectProvider(folderPath),
                            child: SubjectsPage(topicName: topic.name),
                          ),
                        ),
                      );
                    },
              onRename: () => _renameTopic(context, topic),
              onDelete: () => _deleteTopic(context, topic),
              onIconChange: () => _changeIcon(context, topic),
              onToggleVisibility: () =>
                  _toggleVisibility(context, topic), // ==> DITAMBAHKAN
              isReorderActive: isReorderActive,
            );
          },
          onReorder: (oldIndex, newIndex) {
            if (isReorderActive) {
              provider.reorderTopics(oldIndex, newIndex);
            }
          },
        );
      },
    );
  }
}
