// lib/presentation/pages/1_topics_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../domain/models/topic_model.dart';
import '../../application/subject_provider.dart';
import '../../application/topic_provider.dart';
import '../subjects/subjects_page.dart';
import 'dialogs/topic_dialogs.dart';
import 'widgets/topic_grid_tile.dart';
import 'widgets/topic_list_tile.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';
import '../../../../presentation/widgets/ad_banner_widget.dart'; // Impor widget iklan

class TopicsPage extends StatelessWidget {
  const TopicsPage({super.key});

  @override
  Widget build(BuildContext context) {
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

  final FocusNode _focusNode = FocusNode();
  int _focusedIndex = 0;

  Timer? _focusTimer;
  bool _isKeyboardActive = false;

  @override
  void initState() {
    super.initState();
    final topicProvider = Provider.of<TopicProvider>(context, listen: false);
    _searchController.addListener(() {
      topicProvider.search(_searchController.text);
      setState(() => _focusedIndex = 0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    // ## PERBAIKAN: Abaikan event dari tombol Alt ##
    if (event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      return;
    }

    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() => _isKeyboardActive = true);
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isKeyboardActive = false);
        });

        final topicProvider = Provider.of<TopicProvider>(
          context,
          listen: false,
        );
        final totalItems = topicProvider.filteredTopics.length;
        if (totalItems == 0) return;

        int crossAxisCount = (MediaQuery.of(context).size.width > 600)
            ? (MediaQuery.of(context).size.width / 200).floor()
            : 1;

        setState(() {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _focusedIndex = (_focusedIndex + crossAxisCount);
            if (_focusedIndex >= totalItems) _focusedIndex = totalItems - 1;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _focusedIndex = (_focusedIndex - crossAxisCount);
            if (_focusedIndex < 0) _focusedIndex = 0;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _focusedIndex = (_focusedIndex + 1);
            if (_focusedIndex >= totalItems) _focusedIndex = totalItems - 1;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _focusedIndex = (_focusedIndex - 1);
            if (_focusedIndex < 0) _focusedIndex = 0;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        final topicProvider = Provider.of<TopicProvider>(
          context,
          listen: false,
        );
        if (_focusedIndex < topicProvider.filteredTopics.length) {
          _navigateToSubjectsPage(
            context,
            topicProvider.filteredTopics[_focusedIndex],
          );
        }
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _navigateToSubjectsPage(
    BuildContext context,
    Topic topic,
  ) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
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
    ).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    });
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

  // ==> FUNGSI INI DIPERBARUI <==
  Future<void> _changeIcon(BuildContext context, Topic topic) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
    await showIconPickerDialog(
      context: context,
      name: topic.name, // Kirim nama topik
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

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: null,
        appBar: AppBar(
          backgroundColor: null,
          elevation: null,
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
        body: Column(
          // Bungkus dengan Column
          children: [
            Expanded(
              // Bungkus konten utama dengan Expanded
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    return _buildGridView();
                  } else {
                    return _buildListView();
                  }
                },
              ),
            ),
            const AdBannerWidget(), // Tambahkan widget iklan di sini
          ],
        ),
        floatingActionButton: topicProvider.isReorderModeEnabled
            ? null
            : FloatingActionButton(
                onPressed: () => _addTopic(context),
                tooltip: 'Tambah Topik',
                child: const Icon(Icons.add),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildEmptyState(TopicProvider provider) {
    if (provider.allTopics.isEmpty) {
      return const Center(
        child: Text('Tidak ada topik. Tekan + untuk menambah.'),
      );
    }
    if (provider.filteredTopics.isEmpty && provider.searchQuery.isNotEmpty) {
      return const Center(child: Text('Topik tidak ditemukan.'));
    }
    if (provider.filteredTopics.isEmpty && !provider.showHiddenTopics) {
      return const Center(
        child: Text(
          'Tidak ada topik yang terlihat. Coba tampilkan topik tersembunyi.',
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildListView() {
    return Consumer<TopicProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final topicsToShow = provider.filteredTopics;
        if (topicsToShow.isEmpty) {
          return _buildEmptyState(provider);
        }

        final isReorderActive =
            provider.isReorderModeEnabled && provider.searchQuery.isEmpty;

        return ReorderableListView.builder(
          itemCount: topicsToShow.length,
          buildDefaultDragHandles: isReorderActive,
          itemBuilder: (context, index) {
            final topic = topicsToShow[index];
            return TopicListTile(
              key: ValueKey(topic.name),
              topic: topic,
              isFocused: _isKeyboardActive && index == _focusedIndex,
              onTap: isReorderActive
                  ? null
                  : () => _navigateToSubjectsPage(context, topic),
              onRename: () => _renameTopic(context, topic),
              onDelete: () => _deleteTopic(context, topic),
              onIconChange: () => _changeIcon(context, topic),
              onToggleVisibility: () => _toggleVisibility(context, topic),
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

  Widget _buildGridView() {
    return Consumer<TopicProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final topicsToShow = provider.filteredTopics;
        if (topicsToShow.isEmpty) {
          return _buildEmptyState(provider);
        }

        final isReorderActive =
            provider.isReorderModeEnabled && provider.searchQuery.isEmpty;

        return ReorderableGridView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: topicsToShow.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (MediaQuery.of(context).size.width / 200).floor(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final topic = topicsToShow[index];
            return TopicGridTile(
              key: ValueKey(topic.name),
              topic: topic,
              isFocused: _isKeyboardActive && index == _focusedIndex,
              onTap: isReorderActive
                  ? null
                  : () => _navigateToSubjectsPage(context, topic),
              onRename: () => _renameTopic(context, topic),
              onDelete: () => _deleteTopic(context, topic),
              onIconChange: () => _changeIcon(context, topic),
              onToggleVisibility: () => _toggleVisibility(context, topic),
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
