// lib/presentation/pages/linux/main_view_linux/topics_panel.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/topic_model.dart';
import 'package:my_aplication/presentation/pages/1_topics_page/dialogs/topic_dialogs.dart';
import 'package:my_aplication/presentation/pages/1_topics_page/utils/scaffold_messenger_utils.dart';
import 'package:my_aplication/presentation/pages/1_topics_page/widgets/topic_list_tile.dart';
import 'package:my_aplication/presentation/providers/topic_provider.dart';
import 'package:provider/provider.dart';

class TopicsPanel extends StatefulWidget {
  final Function(Topic) onTopicSelected;

  const TopicsPanel({super.key, required this.onTopicSelected});

  @override
  State<TopicsPanel> createState() => _TopicsPanelState();
}

class _TopicsPanelState extends State<TopicsPanel> {
  final TextEditingController _topicSearchController = TextEditingController();
  bool _isSearchingTopics = false;

  @override
  void initState() {
    super.initState();
    final topicProvider = Provider.of<TopicProvider>(context, listen: false);
    _topicSearchController.addListener(() {
      topicProvider.search(_topicSearchController.text);
    });
  }

  @override
  void dispose() {
    _topicSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicProvider = Provider.of<TopicProvider>(context);

    if (topicProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildTopicsToolbar(context, topicProvider),
        const Divider(height: 1),
        Expanded(child: _buildTopicsList(context, topicProvider)),
      ],
    );
  }

  Widget _buildTopicsToolbar(
    BuildContext context,
    TopicProvider topicProvider,
  ) {
    return Padding(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              if (topicProvider.isReorderModeEnabled && _isSearchingTopics) {
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
            'Tidak ada topik terlihat.\\nCoba tampilkan topik tersembunyi.',
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
          onTap: isReorderActive ? null : () => widget.onTopicSelected(topic),
          onRename: () => _renameTopic(context, topicProvider, topic),
          onDelete: () => _deleteTopic(context, topicProvider, topic),
          onIconChange: () => _changeIcon(context, topicProvider, topic),
          onToggleVisibility: () =>
              _toggleVisibility(context, topicProvider, topic),
          isLinux: true, // Menerapkan gaya ringkas untuk Linux
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (isReorderActive) {
          topicProvider.reorderTopics(oldIndex, newIndex);
        }
      },
    );
  }

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
}
