// lib/presentation/pages/3_discussions_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/discussion_provider.dart';
import '3_discussions_page/dialogs/discussion_dialogs.dart';
import '3_discussions_page/widgets/discussion_card.dart';
import '3_discussions_page/widgets/discussion_stats_header.dart';

class DiscussionsPage extends StatefulWidget {
  final String subjectName;
  final String? linkedPath; // ==> DITAMBAHKAN

  const DiscussionsPage({
    super.key,
    required this.subjectName,
    this.linkedPath, // ==> DITAMBAHKAN
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

  void _handleKeyEvent(RawKeyEvent event) {
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

        final provider = Provider.of<DiscussionProvider>(
          context,
          listen: false,
        );
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
              // Di kolom kanan, lompat ke atas
              if (isTwoColumn && _focusedIndex >= middle) {
                // jika ada item di atasnya di kolom yang sama
                if (_focusedIndex > middle) {
                  _focusedIndex--;
                }
              }
              // Di kolom kiri
              else {
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
        final provider = Provider.of<DiscussionProvider>(
          context,
          listen: false,
        );
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _addDiscussion(DiscussionProvider provider) {
    showTextInputDialog(
      context: context,
      title: 'Tambah Diskusi Baru',
      label: 'Nama Diskusi',
      onSave: (name) {
        provider.addDiscussion(name);
        _showSnackBar('Diskusi "$name" berhasil ditambahkan.');
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
        appBar: _buildAppBar(provider),
        body: _buildBody(provider),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addDiscussion(provider),
          tooltip: 'Tambah Diskusi',
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  AppBar _buildAppBar(DiscussionProvider provider) {
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
                return DiscussionCard(
                  key: ValueKey(discussion.hashCode),
                  discussion: discussion,
                  index: originalIndex,
                  isFocused: _isKeyboardActive && index == _focusedIndex,
                  arePointsVisible: _arePointsVisible,
                  onToggleVisibility: _togglePointsVisibility,
                  subjectLinkedPath: widget.linkedPath, // ==> DITERUSKAN
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
        return DiscussionCard(
          key: ValueKey(discussion.hashCode),
          discussion: discussion,
          index: originalIndex,
          isFocused: _isKeyboardActive && overallIndex == _focusedIndex,
          arePointsVisible: _arePointsVisible,
          onToggleVisibility: _togglePointsVisibility,
          subjectLinkedPath: widget.linkedPath, // ==> DITERUSKAN
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
      ),
    );
  }
}
