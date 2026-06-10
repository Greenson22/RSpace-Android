// lib/features/content_management/presentation/topics/topics_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../models/topic_model.dart';
import '../../subjects/providers/subject_provider.dart';
import '../providers/topic_provider.dart';
import '../../subjects/presentation/subjects_page.dart';
import 'dialogs/topic_dialogs.dart';
import 'widgets/topic_list_tile.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';
// Import file konstanta rujukan Anda
import '../../../../core/constants/app_ui_constants.dart';

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
  final List<Color> _themePalettes = [
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
    Colors.green,
  ];

  // Fungsi pembantu untuk menghasilkan warna dinamis dari teks nama topik (Sama seperti di TopicListTile)
  Color _getThemeColorFromTitle(String title) {
    if (title.isEmpty) return Colors.deepPurple;
    final List<Color> themePalettes = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber.shade900,
      Colors.green.shade700,
      Colors.cyan.shade800,
      Colors.orange.shade800,
    ];
    final int hash = title.hashCode;
    final int index = hash.abs() % themePalettes.length;
    return themePalettes[index];
  }

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
          final selectedTopic = topicProvider.filteredTopics[_focusedIndex];
          final targetColor = _getThemeColorFromTitle(selectedTopic.name);
          _navigateToSubjectsPage(
            context,
            selectedTopic,
            targetColor, // Kirim warna saat navigasi via keyboard Enter
          );
        }
      }
    }
  }

  Future<void> _navigateToSubjectsPage(
    BuildContext context,
    Topic topic,
    Color themeColor, // Tambahkan parameter warna di sini
  ) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
    final topicsPath = await provider.getTopicsPath();
    final folderPath = path.join(topicsPath, topic.name);
    Navigator.push(
      context,
      PageRouteBuilder(
        // Menerapkan durasi transisi dari AppThemeTokens
        transitionDuration: AppThemeTokens.pageTransitionIn,
        reverseTransitionDuration: AppThemeTokens.pageTransitionOut,
        pageBuilder: (context, anim, secAnim) => ChangeNotifierProvider(
          create: (_) => SubjectProvider(folderPath),
          child: SubjectsPage(
            topicName: topic.name,
            themeColor:
                themeColor, // Oper warna ke halaman tujuan (SubjectsPage)
          ),
        ),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              // Menerapkan kurva dari AppThemeTokens
              CurvedAnimation(
                parent: anim,
                curve: AppThemeTokens.animationCurve,
              ),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(
                  parent: anim,
                  curve: AppThemeTokens.animationCurve,
                ),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.05).animate(
                  CurvedAnimation(
                    parent: secAnim,
                    curve: AppThemeTokens.animationCurve,
                  ),
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    ).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      });
    });
  }

  Future<void> _addTopic(BuildContext context) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
    await showTopicTextInputDialog(
      context: context,
      title: 'Tambah Topik Baru',
      onSave: (name, icon) async {
        try {
          await provider.addTopic(name);
          showAppSnackBar(context, 'Topik "$name" berhasil ditambahkan.');
        } catch (e) {
          showAppSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  Future<void> _editTopic(BuildContext context, Topic topic) async {
    final provider = Provider.of<TopicProvider>(context, listen: false);
    await showTopicTextInputDialog(
      context: context,
      title: 'Ubah Topik',
      initialValue: topic.name,
      initialIcon: topic.icon,
      onSave: (newName, newIcon) async {
        try {
          if (topic.icon != newIcon) {
            await provider.updateTopicIcon(topic.name, newIcon);
          }
          if (topic.name != newName) {
            await provider.renameTopic(topic.name, newName);
          }
          showAppSnackBar(context, 'Topik berhasil diubah.');
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
    // Menerapkan AppThemeTokens.iconSmall untuk ukuran dasar ikon AppBar
    final scaledAppBarIconSize = AppThemeTokens.iconSmall * textScaleFactor;
    final Color defaultThemeColor = _themePalettes[0];
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: isTransparent ? Colors.transparent : null,
        appBar: AppBar(
          backgroundColor: isTransparent
              ? Colors.transparent
              : defaultThemeColor,
          foregroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 48.0,
          iconTheme: IconThemeData(
            size: scaledAppBarIconSize,
            color: Colors.white,
          ),
          title: topicProvider.isReorderModeEnabled
              ? const Text(
                  'Urutkan Topik',
                  style: AppThemeTokens
                      .heading, // Menerapkan gaya teks heading standar
                )
              : (_isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Cari topik...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.white70),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      )
                    : const Text(
                        'Topics',
                        style: AppThemeTokens
                            .heading, // Menerapkan gaya teks heading standar
                      )),
          actions: [
            if (!topicProvider.isReorderModeEnabled) ...[
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                iconSize: scaledAppBarIconSize,
                color: Colors.white,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) _searchController.clear();
                  });
                },
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                iconSize: scaledAppBarIconSize,
                color: Colors.white,
                iconColor: Colors.white,
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
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          topicProvider.showHiddenTopics
                              ? 'Sembunyikan Tersembunyi'
                              : 'Tampilkan Tersembunyi',
                          style: AppThemeTokens
                              .body, // Menerapkan gaya teks body standar
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'sort_topics',
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: 20, color: Colors.black87),
                        SizedBox(width: 8),
                        Text(
                          'Urutkan Topik',
                          style: AppThemeTokens
                              .body, // Menerapkan gaya teks body standar
                        ),
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
                color: Colors.white,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => topicProvider.toggleReorderMode(),
                tooltip: 'Selesai Mengurutkan',
              ),
            ],
            const SizedBox(width: 12.0),
          ],
        ),
        body: Column(children: [Expanded(child: _buildListView())]),
        floatingActionButton: topicProvider.isReorderModeEnabled
            ? null
            : FloatingActionButton(
                onPressed: () => _addTopic(context),
                tooltip: 'Tambah Topik',
                backgroundColor: defaultThemeColor,
                foregroundColor: Colors.white,
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
          padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                  : () {
                      // Ambil warna tema spesifik dari topik yang diklik
                      final Color currentWarna = _getThemeColorFromTitle(
                        topic.name,
                      );
                      _navigateToSubjectsPage(context, topic, currentWarna);
                    },
              onEdit: () => _editTopic(context, topic),
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
    final Color defaultThemeColor = _themePalettes[0];
    if (provider.allTopics.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: defaultThemeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 80,
                  color: defaultThemeColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Belum Ada Topik',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mulai kelola konten Anda dengan menambahkan topik atau folder baru pertama Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppThemeTokens
                      .body
                      .fontSize, // Menyesuaikan ukuran font body rujukan
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _addTopic(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Tambah Topik Pertama',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: defaultThemeColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.filteredTopics.isEmpty && provider.searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 72,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Topik Tidak Ditemukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tidak ada hasil yang cocok untuk "${provider.searchQuery}". Coba periksa kembali ejaan Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppThemeTokens.body.fontSize,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.filteredTopics.isEmpty && !provider.showHiddenTopics) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_off_outlined,
                size: 72,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Semua Topik Tersembunyi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Aktifkan opsi "Tampilkan Tersembunyi" dari menu pojok kanan atas untuk melihat topik.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppThemeTokens.body.fontSize,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => provider.toggleShowHidden(),
                icon: Icon(Icons.visibility, color: defaultThemeColor),
                label: Text(
                  'Tampilkan Sekarang',
                  style: TextStyle(
                    color: defaultThemeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
