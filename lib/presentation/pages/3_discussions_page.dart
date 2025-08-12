import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final Map<int, bool> _arePointsVisible = {}; // State lokal untuk UI
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- UI HANDLERS YANG MEMANGGIL PROVIDER ---

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

  void _addPoint(DiscussionProvider provider, discussion) {
    showTextInputDialog(
      context: context,
      title: 'Tambah Poin Baru',
      label: 'Teks Poin',
      onSave: (text) {
        provider.addPoint(discussion, text);
        _showSnackBar('Poin berhasil ditambahkan.');
      },
    );
  }

  void _handleShowFilterDialog(DiscussionProvider provider) {
    showFilterDialog(
      context: context,
      isFilterActive: provider.activeFilterType != null,
      onClearFilters: () {
        provider.clearFilters();
        _showSnackBar('Semua filter telah dihapus.');
      },
      onShowRepetitionCodeFilter: () =>
          _handleShowRepetitionCodeFilterDialog(provider),
      onShowDateFilter: () => _handleShowDateFilterDialog(provider),
    );
  }

  void _handleShowRepetitionCodeFilterDialog(DiscussionProvider provider) {
    showRepetitionCodeFilterDialog(
      context: context,
      repetitionCodes: provider.repetitionCodes,
      onSelectCode: (code) {
        provider.applyCodeFilter(code);
        _showSnackBar('Filter diterapkan: Kode = $code');
      },
    );
  }

  void _handleShowDateFilterDialog(DiscussionProvider provider) {
    showDateFilterDialog(
      context: context,
      initialDateRange:
          null, // Bisa di-improve untuk menyimpan state ini di provider
      onSelectRange: (range) {
        provider.applyDateFilter(range);
        final startDate = DateFormat('dd/MM/yy').format(range.start);
        final endDate = DateFormat('dd/MM/yy').format(range.end);
        _showSnackBar('Filter diterapkan: $startDate - $endDate');
      },
    );
  }

  void _handleShowSortDialog(DiscussionProvider provider) {
    showSortDialog(
      context: context,
      initialSortType: provider.sortType,
      initialSortAscending: provider.sortAscending,
      onApplySort: (sortType, sortAscending) {
        provider.applySort(sortType, sortAscending);
        _showSnackBar('Diskusi telah diurutkan.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiscussionProvider>(
      builder: (context, provider, child) {
        final discussionsToShow =
            _searchController.text.isNotEmpty ||
                provider.activeFilterType != null
            ? provider.filteredDiscussions
            : provider.allDiscussions;

        String emptyText = 'Tidak ada diskusi. Tekan + untuk menambah.';
        if ((_searchController.text.isNotEmpty ||
                provider.activeFilterType != null) &&
            discussionsToShow.isEmpty) {
          emptyText = 'Diskusi tidak ditemukan.';
        }

        return Scaffold(
          appBar: AppBar(
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
                onPressed: () => _handleShowFilterDialog(provider),
                tooltip: 'Filter Diskusi',
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () => _handleShowSortDialog(provider),
                tooltip: 'Urutkan Diskusi',
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : discussionsToShow.isEmpty
              ? Center(child: Text(emptyText))
              : ListView.builder(
                  itemCount: discussionsToShow.length,
                  itemBuilder: (context, index) {
                    final discussion = discussionsToShow[index];
                    final originalIndex = provider.allDiscussions.indexOf(
                      discussion,
                    );
                    return DiscussionCard(
                      discussion: discussion,
                      index: originalIndex,
                      arePointsVisible: _arePointsVisible,
                      onToggleVisibility: (idx) => setState(
                        () => _arePointsVisible[idx] =
                            !(_arePointsVisible[idx] ?? false),
                      ),
                      onAddPoint: () => _addPoint(provider, discussion),
                      onMarkAsFinished: () =>
                          provider.markAsFinished(discussion),
                      onRename: () {
                        /* ... implement in provider ... */
                      },
                      onDiscussionDateChange: () {
                        /* ... implement in provider ... */
                      },
                      onDiscussionCodeChange: () {
                        /* ... implement in provider ... */
                      },
                      onPointDateChange: (point) {
                        /* ... implement in provider ... */
                      },
                      onPointCodeChange: (point) {
                        /* ... implement in provider ... */
                      },
                      onPointRename: (point) {
                        /* ... implement in provider ... */
                      },
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addDiscussion(provider),
            tooltip: 'Tambah Diskusi',
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}
