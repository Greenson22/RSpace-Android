// lib/features/content_management/presentation/topics/topics_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../domain/models/topic_model.dart';
import '../../application/subject_provider.dart';
import '../../application/topic_provider.dart';
import '../subjects/subjects_page.dart';
import 'dialogs/topic_dialogs.dart';
import 'widgets/topic_list_tile.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';

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
    if (event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      return;
    }

    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
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

        setState(() {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _focusedIndex = (_focusedIndex + 1);
            if (_focusedIndex >= totalItems) _focusedIndex = totalItems - 1;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
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
    final result = await showDeleteTopicConfirmationDialog(
      context: context,
      topicName: topic.name,
    );

    if (result != null && result['confirmed'] == true) {
      try {
        await provider.deleteTopic(
          topic.name,
          deletePerpuskuFolder: result['deleteFolder'] ?? false,
        );
        showAppSnackBar(context, 'Topik "${topic.name}" berhasil dihapus.');
      } catch (e) {
        showAppSnackBar(context, e.toString(), isError: true);
      }
    }
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
    const bool isTransparent = false;

    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // --- SKALA UKURAN APPBAR UNTUK MOBILE ---
    const double baseAppBarIconSize = 20.0; // Diturunkan dari 24.0[cite: 11]
    final scaledAppBarIconSize = baseAppBarIconSize * textScaleFactor;

    // Ambil warna teks bawaan tema aktif untuk mengatasi tulisan putih di atas background putih[cite: 11]
    final Color defaultTextColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: isTransparent ? Colors.transparent : null,
        appBar: AppBar(
          leadingWidth: 48.0, // Mengharmoniskan lebar tombol leading
          iconTheme: IconThemeData(
            size: scaledAppBarIconSize,
          ), // Memaksa tombol menu/back mengikuti skala kecil
          title: topicProvider.isReorderModeEnabled
              ? const Text(
                  'Urutkan Topik',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ), // Ukuran judul diperkecil[cite: 11]
                )
              : (_isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Cari topik...',
                          border: InputBorder.none,
                          // PERBAIKAN WARNA: Mengubah hint text menggunakan kontras warna tema[cite: 11]
                          hintStyle: TextStyle(
                            color: defaultTextColor.withOpacity(0.5),
                          ),
                        ),
                        // PERBAIKAN WARNA: Mengubah warna ketikan mengikuti kontras tema (gelap/hitam)[cite: 11]
                        style: TextStyle(
                          color: defaultTextColor,
                          fontSize: 16.0,
                        ),
                      )
                    : const Text(
                        'Topics',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                        ), // Ukuran judul diperkecil[cite: 11]
                      )),
          actions: [
            if (!topicProvider.isReorderModeEnabled) ...[
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                iconSize: scaledAppBarIconSize,
                padding: EdgeInsets
                    .zero, // Memaksimalkan area klik di ruang sempit mobile
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _searchController.clear();
                  });
                },
              ),
              const SizedBox(width: 8), // Menambahkan sela antar ikon tindakan
              // --- PENGGANTIAN MENU DROP DOWN (SHOW MENU) ---
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                iconSize: scaledAppBarIconSize,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (value) {
                  if (value == 'toggle_hidden') {
                    topicProvider.toggleShowHidden();
                  } else if (value == 'sort_topics') {
                    if (_isSearching) {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                      });
                    }
                    topicProvider.toggleReorderMode();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_hidden',
                    child: Row(
                      children: [
                        Icon(
                          topicProvider.showHiddenTopics
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          topicProvider.showHiddenTopics
                              ? 'Sembunyikan Tersembunyi'
                              : 'Tampilkan Tersembunyi',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'sort_topics',
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: 20),
                        SizedBox(width: 8),
                        Text('Urutkan Topik', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            if (topicProvider.isReorderModeEnabled) ...[
              IconButton(
                icon: const Icon(Icons.check),
                iconSize: scaledAppBarIconSize,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => topicProvider.toggleReorderMode(),
                tooltip: 'Selesai Mengurutkan',
              ),
            ],
            const SizedBox(width: 12.0), // Jarak aman ujung kanan AppBar
          ],
        ),
        body: Column(children: [Expanded(child: _buildListView())]),
        floatingActionButton: topicProvider.isReorderModeEnabled
            ? null
            : FloatingActionButton(
                onPressed: () => _addTopic(context),
                tooltip: 'Tambah Topik',
                child: const Icon(Icons.add),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
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
          padding: const EdgeInsets.symmetric(
            vertical: 4.0,
          ), // Memadatkan ruang vertikal[cite: 11]
          itemCount: topicsToShow.length,
          buildDefaultDragHandles: false,
          proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
                return Material(
                  elevation: 4,
                  color: Colors.transparent,
                  child: child,
                );
              },
          itemBuilder: (context, index) {
            final topic = topicsToShow[index];
            return TopicListTile(
              key: ValueKey(topic.name),
              topic: topic,
              index: index,
              isFocused: _isKeyboardActive && index == _focusedIndex,
              onTap: isReorderActive
                  ? null
                  : () => _navigateToSubjectsPage(context, topic),
              onRename: () => _renameTopic(context, topic),
              onDelete: () => _deleteTopic(context, topic),
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
}
