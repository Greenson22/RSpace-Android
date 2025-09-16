// lib/features/content_management/presentation/discussions/discussions_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import '../../application/discussion_provider.dart';
import 'dialogs/discussion_dialogs.dart';
import 'widgets/discussion_list_item.dart';
import 'widgets/discussion_stats_header.dart';
import '../../../../core/widgets/ad_banner_widget.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';
import '../../../../core/providers/neuron_provider.dart';
import '../../domain/models/discussion_model.dart';
import 'dialogs/add_discussion_from_content_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<DiscussionProvider>(context, listen: false).searchQuery =
          _searchController.text;
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

  void _moveSelectedDiscussions(DiscussionProvider provider) async {
    final targetInfo = await showMoveDiscussionDialog(context);

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
      }
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isLong = false,
  }) {
    // Cek mounted di sini untuk keamanan
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
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        Navigator.of(context).pop();
      }
    }
  }

  void _togglePointsVisibility(int index) {
    setState(() {
      _arePointsVisible[index] = !(_arePointsVisible[index] ?? false);
    });
  }

  void _addDiscussion(DiscussionProvider provider) {
    showAddDiscussionDialog(
      context: context,
      title: 'Tambah Diskusi Baru',
      label: 'Nama Diskusi',
      subjectLinkedPath: widget.linkedPath,
      discussion: Discussion(discussion: '', repetitionCode: '', points: []),
      onSave: (name, createHtmlFile) async {
        try {
          await provider.addDiscussion(
            name,
            createHtmlFile: createHtmlFile,
            subjectLinkedPath: widget.linkedPath,
          );
          if (mounted) {
            _showSnackBar('Diskusi "$name" berhasil ditambahkan.');
            await Provider.of<NeuronProvider>(
              context,
              listen: false,
            ).addNeurons(10);
            showNeuronRewardSnackBar(context, 10);
          }
        } catch (e) {
          _showSnackBar("Gagal: ${e.toString()}", isError: true);
        }
      },
    );
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

          if (!mounted) return; // Cek mounted setelah await

          if (success) {
            await provider.deleteDiscussion(discussion);
            _showSnackBar(
              'Diskusi "${discussion.discussion}" berhasil dihapus.',
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

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        appBar: provider.isSelectionMode
            ? _buildSelectionAppBar(provider)
            : _buildDefaultAppBar(provider),
        body: Column(
          children: [
            Expanded(child: _buildBody(provider)),
            const AdBannerWidget(),
          ],
        ),
        floatingActionButton: provider.isSelectionMode
            ? null
            : SpeedDial(
                icon: Icons.add,
                activeIcon: Icons.close,
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                children: [
                  SpeedDialChild(
                    child: const Icon(Icons.title),
                    label: 'Tambah dari Judul',
                    onTap: () => _addDiscussion(provider),
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.article_outlined),
                    label: 'Tambah dari Konten (AI)',
                    onTap: () => showAddDiscussionFromContentDialog(
                      context: context,
                      subjectLinkedPath: widget.linkedPath,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  AppBar _buildSelectionAppBar(DiscussionProvider provider) {
    return AppBar(
      title: Text('${provider.selectedDiscussions.length} dipilih'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => provider.clearSelection(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () => provider.selectAllFiltered(),
          tooltip: 'Pilih Semua',
        ),
        IconButton(
          icon: const Icon(Icons.move_up),
          onPressed: () => _moveSelectedDiscussions(provider),
          tooltip: 'Pindahkan Pilihan',
        ),
      ],
    );
  }

  AppBar _buildDefaultAppBar(DiscussionProvider provider) {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari diskusi...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            )
          : Text(widget.subjectName, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () => setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) _searchController.clear();
          }),
        ),
        if (provider.activeFilterType != 'code')
          IconButton(
            icon: Icon(
              provider.showFinishedDiscussions
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            tooltip: provider.showFinishedDiscussions
                ? 'Sembunyikan Selesai'
                : 'Tampilkan Selesai',
            onPressed: () => provider.toggleShowFinished(),
          ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter Diskusi',
          onPressed: () => _showFilterDialog(provider),
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          tooltip: 'Urutkan Diskusi',
          onPressed: () => showSortDialog(
            context: context,
            initialSortType: provider.sortType,
            initialSortAscending: provider.sortAscending,
            onApplySort: (sortType, sortAscending) {
              provider.applySort(sortType, sortAscending);
              _showSnackBar('Diskusi telah diurutkan.');
            },
          ),
        ),
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
    return Column(
      children: [
        const DiscussionStatsHeader(),
        if (discussions.isEmpty && provider.allDiscussions.isNotEmpty)
          const Expanded(child: Center(child: Text('Diskusi tidak ditemukan.')))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              itemCount: discussions.length,
              itemBuilder: (context, index) {
                final discussion = discussions[index];
                final originalIndex = provider.allDiscussions.indexOf(
                  discussion,
                );
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
    final int middle = (discussions.length / 2).ceil();
    final List<dynamic> firstHalf = discussions.sublist(0, middle);
    final List<dynamic> secondHalf = discussions.sublist(middle);

    return Column(
      children: [
        const DiscussionStatsHeader(),
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
