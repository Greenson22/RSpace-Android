// lib/features/content_management/presentation/discussions/discussions_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/discussion_provider.dart';
import 'dialogs/discussion_dialogs.dart'; // Import utama untuk dialog
import 'widgets/discussion_list_item.dart';
import 'widgets/discussion_stats_header.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';
import '../../../../core/providers/neuron_provider.dart';
import '../../domain/models/discussion_model.dart';

class DiscussionsPage extends StatefulWidget {
  final String subjectName;
  final String? linkedPath;

  const DiscussionsPage({
    super.key,
    required this.subjectName,
    this.linkedPath,
  });

  @override
  State<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, bool> _arePointsVisible = {};
  bool _isSearching = false;
  final FocusNode _focusNode = FocusNode();
  int _focusedIndex = 0;
  Timer? _focusTimer;
  bool _isKeyboardActive = false;
  int? _reorderingDiscussionIndex;

  // Daftar warna palet untuk menyamakan tampilan tema dengan content card
  final List<Color> _themePalettes = [
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
    Colors.green,
  ];

  // Fungsi utilitas untuk menghasilkan warna dinamis yang konsisten berdasarkan judul subjek
  Color _getThemeColorFromTitle(String title) {
    if (title.isEmpty) return _themePalettes[0];
    int hash = title.hashCode;
    int index = hash.abs() % _themePalettes.length;
    return _themePalettes[index];
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<DiscussionProvider>(context, listen: false).searchQuery =
          _searchController.text;
      setState(() => _focusedIndex = 0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  void _moveSelectedDiscussions(DiscussionProvider provider) async {
    final targetInfo = await showMoveDiscussionDialog(
      context,
      widget.subjectName,
    );
    if (targetInfo != null && mounted) {
      try {
        final String targetJsonPath = targetInfo['jsonPath']!;
        final String? targetLinkedPath = targetInfo['linkedPath'];
        final String logMessage = await provider.moveSelectedDiscussions(
          targetJsonPath,
          targetLinkedPath,
        );
        _showSnackBar(logMessage, isLong: true);
      } catch (e) {
        _showSnackBar(
          'Gagal memindahkan diskusi: ${e.toString()}',
          isError: true,
        );
      } finally {
        provider.clearSelection();
      }
    } else {
      provider.clearSelection();
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isLong = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: isLong
            ? const Duration(seconds: 10)
            : const Duration(seconds: 4),
        action: isLong
            ? SnackBarAction(
                label: 'TUTUP',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final provider = Provider.of<DiscussionProvider>(context, listen: false);
      if (provider.isSelectionMode) {
        if (event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.backspace) {
          provider.clearSelection();
        }
        return;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() => _isKeyboardActive = true);
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isKeyboardActive = false);
        });
        final discussions = provider.filteredDiscussions;
        final totalItems = discussions.length;
        if (totalItems == 0) return;
        final isTwoColumn = MediaQuery.of(context).size.width > 800.0;
        final int middle = (totalItems / 2).ceil();
        setState(() {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (isTwoColumn) {
              if (_focusedIndex < middle - 1) {
                _focusedIndex++;
              } else if (_focusedIndex >= middle &&
                  _focusedIndex < totalItems - 1) {
                _focusedIndex++;
              }
            } else {
              if (_focusedIndex < totalItems - 1) _focusedIndex++;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            if (_focusedIndex > 0) {
              if (isTwoColumn && _focusedIndex >= middle) {
                if (_focusedIndex > middle) {
                  _focusedIndex--;
                }
              } else {
                _focusedIndex--;
              }
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (isTwoColumn && _focusedIndex < middle) {
              int targetIndex = _focusedIndex + middle;
              _focusedIndex = targetIndex < totalItems
                  ? targetIndex
                  : totalItems - 1;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (isTwoColumn && _focusedIndex >= middle) {
              _focusedIndex -= middle;
            }
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_focusedIndex < provider.filteredDiscussions.length) {
          final discussion = provider.filteredDiscussions[_focusedIndex];
          final originalIndex = provider.allDiscussions.indexOf(discussion);
          _togglePointsVisibility(originalIndex);
        }
      }
    }
  }

  void _togglePointsVisibility(int index) {
    setState(() {
      _arePointsVisible[index] = !(_arePointsVisible[index] ?? false);
      if (_arePointsVisible[index] == false) {
        if (_reorderingDiscussionIndex == index) {
          _reorderingDiscussionIndex = null;
        }
      }
    });
  }

  void _addDiscussion(DiscussionProvider provider) async {
    final result = await showAddDiscussionDialog(
      context: context,
      title: 'Tambah Diskusi Baru',
      label: 'Nama Diskusi',
      subjectLinkedPath: widget.linkedPath,
    );
    if (result != null && mounted) {
      try {
        await provider.addDiscussion(result);
        _showSnackBar('Diskusi "${result.name}" berhasil ditambahkan.');
        await Provider.of<NeuronProvider>(
          context,
          listen: false,
        ).addNeurons(10);
        showNeuronRewardSnackBar(context, 10);
      } catch (e) {
        _showSnackBar("Gagal: ${e.toString()}", isError: true);
      }
    }
  }

  void _deleteDiscussion(DiscussionProvider provider, Discussion discussion) {
    showDeleteDiscussionConfirmationDialog(
      context: context,
      discussionName: discussion.discussion,
      hasLinkedFile:
          discussion.filePath != null && discussion.filePath!.isNotEmpty,
      onDelete: () async {
        try {
          final neuronProvider = Provider.of<NeuronProvider>(
            context,
            listen: false,
          );
          final bool success = await neuronProvider.spendNeurons(15);
          if (!mounted) return;
          if (success) {
            await provider.deleteDiscussion(discussion);
            _showSnackBar(
              'Diskusi "${discussion.discussion}" berhasil deleted.',
            );
            showNeuronPenaltySnackBar(context, 15);
          } else {
            _showSnackBar(
              "Gagal menghapus: Neuron tidak cukup.",
              isError: true,
            );
          }
        } catch (e) {
          if (mounted) {
            _showSnackBar("Gagal menghapus: ${e.toString()}", isError: true);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context);
    const bool isTransparent = false;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double baseAppBarIconSize = 20.0;
    final scaledAppBarIconSize = baseAppBarIconSize * textScaleFactor;

    // Menghitung warna dinamis berdasarkan nama subjek halaman saat ini
    final Color dynamicAppBarColor = _getThemeColorFromTitle(
      widget.subjectName,
    );

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: isTransparent ? Colors.transparent : null,
        appBar: provider.isSelectionMode
            ? _buildSelectionAppBar(
                provider,
                scaledAppBarIconSize,
                dynamicAppBarColor,
              )
            : _buildDefaultAppBar(
                provider,
                scaledAppBarIconSize,
                dynamicAppBarColor,
                isTransparent: isTransparent,
              ),
        body: Column(children: [Expanded(child: _buildBody(provider))]),
        floatingActionButton:
            provider.isSelectionMode || _reorderingDiscussionIndex != null
            ? null
            : FloatingActionButton(
                onPressed: () => _addDiscussion(provider),
                tooltip: 'Tambah Diskusi Baru',
                backgroundColor:
                    dynamicAppBarColor, // Menyesuaikan warna FAB dengan warna AppBar
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  AppBar _buildSelectionAppBar(
    DiscussionProvider provider,
    double scaledIconSize,
    Color backgroundColor,
  ) {
    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(size: scaledIconSize, color: Colors.white),
      elevation: 0,
      title: Text(
        '${provider.selectedDiscussions.length} dipilih',
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close),
        iconSize: scaledIconSize,
        onPressed: () => provider.clearSelection(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          iconSize: scaledIconSize,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => provider.selectAllFiltered(),
          tooltip: 'Pilih Semua',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.move_up),
          iconSize: scaledIconSize,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => _moveSelectedDiscussions(provider),
          tooltip: 'Pindahkan Pilihan',
        ),
        const SizedBox(width: 12.0),
      ],
    );
  }

  AppBar _buildDefaultAppBar(
    DiscussionProvider provider,
    double scaledIconSize,
    Color backgroundColor, {
    required bool isTransparent,
  }) {
    return AppBar(
      backgroundColor: isTransparent ? Colors.transparent : backgroundColor,
      foregroundColor: Colors.white,
      elevation: isTransparent ? 0 : 0,
      leadingWidth: 48.0,
      iconTheme: IconThemeData(size: scaledIconSize, color: Colors.white),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari diskusi...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
            )
          : Text(
              widget.subjectName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          iconSize: scaledIconSize,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) _searchController.clear();
          }),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          iconSize: scaledIconSize,
          color: Colors.white, // Latar belakang menu popup
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onSelected: (value) {
            if (value == 'toggle_finished') {
              provider.toggleShowFinished();
            } else if (value == 'filter_discussions') {
              _showFilterDialog(provider);
            } else if (value == 'sort_discussions') {
              showSortDialog(
                context: context,
                initialSortType: provider.sortType,
                initialSortAscending: provider.sortAscending,
                onApplySort: (sortType, sortAscending) {
                  provider.applySort(sortType, sortAscending);
                  _showSnackBar('Diskusi dan poin telah diurutkan.');
                },
              );
            }
          },
          itemBuilder: (context) => [
            if (provider.activeFilterType != 'code')
              PopupMenuItem(
                value: 'toggle_finished',
                height: 40,
                child: Row(
                  children: [
                    Icon(
                      provider.showFinishedDiscussions
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      provider.showFinishedDiscussions
                          ? 'Sembunyikan Selesai'
                          : 'Tampilkan Selesai',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'filter_discussions',
              height: 40,
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 20, color: Colors.black87),
                  SizedBox(width: 10),
                  Text(
                    'Filter Diskusi',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sort_discussions',
              height: 40,
              child: Row(
                children: [
                  Icon(Icons.sort, size: 20, color: Colors.black87),
                  SizedBox(width: 10),
                  Text(
                    'Urutkan Diskusi & Poin',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 12.0),
      ],
    );
  }

  Widget _buildBody(DiscussionProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.allDiscussions.isEmpty) {
      return const Center(
        child: Text('Tidak ada diskusi. Tekan + untuk menambah.'),
      );
    }
    final discussionsToShow = provider.filteredDiscussions;
    return LayoutBuilder(
      builder: (context, constraints) {
        const double breakpoint = 800.0;
        if (constraints.maxWidth > breakpoint) {
          return _buildTwoColumnLayout(provider, discussionsToShow);
        } else {
          return _buildSingleColumnLayout(provider, discussionsToShow);
        }
      },
    );
  }

  Widget _buildSingleColumnLayout(
    DiscussionProvider provider,
    List<dynamic> discussions,
  ) {
    final Color dynamicColor = _getThemeColorFromTitle(widget.subjectName);

    return Column(
      children: [
        DiscussionStatsHeader(themeColor: dynamicColor),
        if (discussions.isEmpty && provider.allDiscussions.isNotEmpty)
          const Expanded(child: Center(child: Text('Diskusi tidak ditemukan.')))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 80),
              itemCount: discussions.length,
              itemBuilder: (context, index) {
                final discussion = discussions[index];
                final originalIndex = provider.allDiscussions.indexOf(
                  discussion,
                );
                final isPointReorderMode =
                    originalIndex == _reorderingDiscussionIndex;
                return DiscussionListItem(
                  key: ValueKey(discussion.hashCode),
                  discussion: discussion,
                  index: originalIndex,
                  isFocused: _isKeyboardActive && index == _focusedIndex,
                  arePointsVisible: _arePointsVisible,
                  onToggleVisibility: _togglePointsVisibility,
                  subjectName: widget.subjectName,
                  subjectLinkedPath: widget.linkedPath,
                  onDelete: () => _deleteDiscussion(provider, discussion),
                  isPointReorderMode: isPointReorderMode,
                  onToggleReorder: () {
                    setState(() {
                      if (isPointReorderMode) {
                        _reorderingDiscussionIndex = null;
                      } else {
                        _reorderingDiscussionIndex = originalIndex;
                        if (!(_arePointsVisible[originalIndex] ?? false)) {
                          _arePointsVisible[originalIndex] = true;
                        }
                      }
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTwoColumnLayout(
    DiscussionProvider provider,
    List<dynamic> discussions,
  ) {
    final Color dynamicColor = _getThemeColorFromTitle(widget.subjectName);
    final int middle = (discussions.length / 2).ceil();
    final List<dynamic> firstHalf = discussions.sublist(0, middle);
    final List<dynamic> secondHalf = discussions.sublist(middle);
    return Column(
      children: [
        DiscussionStatsHeader(themeColor: dynamicColor),
        if (discussions.isEmpty && provider.allDiscussions.isNotEmpty)
          const Expanded(child: Center(child: Text('Diskusi tidak ditemukan.')))
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildColumnListView(provider, firstHalf, 0)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildColumnListView(provider, secondHalf, middle),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildColumnListView(
    DiscussionProvider provider,
    List<dynamic> discussionList,
    int indexOffset,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: discussionList.length,
      itemBuilder: (context, index) {
        final discussion = discussionList[index];
        final originalIndex = provider.allDiscussions.indexOf(discussion);
        final overallIndex = index + indexOffset;
        final isPointReorderMode = originalIndex == _reorderingDiscussionIndex;
        return DiscussionListItem(
          key: ValueKey(discussion.hashCode),
          discussion: discussion,
          index: originalIndex,
          isFocused: _isKeyboardActive && overallIndex == _focusedIndex,
          arePointsVisible: _arePointsVisible,
          onToggleVisibility: _togglePointsVisibility,
          subjectName: widget.subjectName,
          subjectLinkedPath: widget.linkedPath,
          onDelete: () => _deleteDiscussion(provider, discussion),
          isPointReorderMode: isPointReorderMode,
          onToggleReorder: () {
            setState(() {
              if (isPointReorderMode) {
                _reorderingDiscussionIndex = null;
              } else {
                _reorderingDiscussionIndex = originalIndex;
                if (!(_arePointsVisible[originalIndex] ?? false)) {
                  _arePointsVisible[originalIndex] = true;
                }
              }
            });
          },
        );
      },
    );
  }

  void _showFilterDialog(DiscussionProvider provider) {
    showFilterDialog(
      context: context,
      isFilterActive: provider.activeFilterType != null,
      onClearFilters: () {
        provider.clearFilters();
        _showSnackBar('Semua filter telah dihapus.');
      },
      onShowRepetitionCodeFilter: () => showRepetitionCodeFilterDialog(
        context: context,
        repetitionCodes: provider.repetitionCodes,
        onSelectCode: (code) {
          provider.applyCodeFilter(code);
          _showSnackBar('Filter diterapkan: Kode = $code');
        },
      ),
      onShowDateFilter: () => showDateFilterDialog(
        context: context,
        initialDateRange: null,
        onSelectRange: (range) {
          provider.applyDateFilter(range);
          _showSnackBar('Filter tanggal diterapkan.');
        },
        onSelectTodayAndBefore: () {
          provider.applyTodayAndBeforeFilter();
          _showSnackBar('Filter diterapkan: Hari ini dan sebelumnya.');
        },
      ),
    );
  }
}
