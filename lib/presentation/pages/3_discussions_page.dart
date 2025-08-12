import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/discussion_provider.dart';
import '3_discussions_page/dialogs/discussion_dialogs.dart';
import '3_discussions_page/widgets/discussion_card.dart';

class DiscussionsPage extends StatefulWidget {
  final String subjectName;

  const DiscussionsPage({super.key, required this.subjectName});

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
              ),
            )
          : Text(widget.subjectName),
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

    final discussionsToShow = provider.filteredDiscussions;

    if (discussionsToShow.isEmpty) {
      final bool isFiltering =
          _searchController.text.isNotEmpty ||
          provider.activeFilterType != null;
      return Center(
        child: Text(
          isFiltering
              ? 'Diskusi tidak ditemukan.'
              : 'Tidak ada diskusi. Tekan + untuk menambah.',
        ),
      );
    }

    return ListView.builder(
      itemCount: discussionsToShow.length,
      itemBuilder: (context, index) {
        final discussion = discussionsToShow[index];
        final originalIndex = provider.allDiscussions.indexOf(discussion);
        return DiscussionCard(
          key: ValueKey(
            discussion.hashCode,
          ), // Important for stateful widgets in a list
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
        initialDateRange:
            null, // You can enhance this by storing range in provider
        onSelectRange: (range) {
          provider.applyDateFilter(range);
          _showSnackBar('Filter tanggal diterapkan.');
        },
      ),
    );
  }
}
