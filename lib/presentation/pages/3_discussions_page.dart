// lib/presentation/pages/3_discussions_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/discussion_provider.dart';
import '3_discussions_page/dialogs/discussion_dialogs.dart';
import '3_discussions_page/widgets/discussion_card.dart';
import '3_discussions_page/widgets/discussion_stats_header.dart';

class DiscussionsPage extends StatefulWidget {
  final String subjectName;
  final VoidCallback? onFilterOrSortChanged;

  const DiscussionsPage({
    super.key,
    required this.subjectName,
    this.onFilterOrSortChanged,
  });

  @override
  State<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<int, bool> _arePointsVisible = {};
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<DiscussionProvider>(context, listen: false).searchQuery =
          _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: _buildAppBar(provider),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDiscussion(provider),
        tooltip: 'Tambah Diskusi',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
              widget.onFilterOrSortChanged?.call();
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
                  arePointsVisible: _arePointsVisible,
                  onToggleVisibility: (idx) => setState(
                    () => _arePointsVisible[idx] =
                        !(_arePointsVisible[idx] ?? false),
                  ),
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
                  Expanded(child: _buildColumnListView(provider, firstHalf)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildColumnListView(provider, secondHalf)),
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
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: discussionList.length,
      itemBuilder: (context, index) {
        final discussion = discussionList[index];
        final originalIndex = provider.allDiscussions.indexOf(discussion);
        return DiscussionCard(
          key: ValueKey(discussion.hashCode),
          discussion: discussion,
          index: originalIndex,
          arePointsVisible: _arePointsVisible,
          onToggleVisibility: (idx) => setState(
            () => _arePointsVisible[idx] = !(_arePointsVisible[idx] ?? false),
          ),
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
        widget.onFilterOrSortChanged?.call();
        _showSnackBar('Semua filter telah dihapus.');
      },
      onShowRepetitionCodeFilter: () => showRepetitionCodeFilterDialog(
        context: context,
        repetitionCodes: provider.repetitionCodes,
        onSelectCode: (code) {
          provider.applyCodeFilter(code);
          widget.onFilterOrSortChanged?.call();
          _showSnackBar('Filter diterapkan: Kode = $code');
        },
      ),
      onShowDateFilter: () => showDateFilterDialog(
        context: context,
        initialDateRange: null,
        onSelectRange: (range) {
          provider.applyDateFilter(range);
          widget.onFilterOrSortChanged?.call();
          _showSnackBar('Filter tanggal diterapkan.');
        },
      ),
    );
  }
}
