// lib/presentation/pages/linux/main_view_linux/discussions_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/discussion_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../1_topics_page/utils/scaffold_messenger_utils.dart';
import '../../3_discussions_page.dart';
import '../../3_discussions_page/dialogs/discussion_dialogs.dart';

class DiscussionsPanel extends StatefulWidget {
  final DiscussionProvider? discussionProvider;
  final String? selectedSubjectName;
  final VoidCallback onAddDiscussion;
  final VoidCallback onFilterOrSortChanged;

  const DiscussionsPanel({
    super.key,
    required this.discussionProvider,
    required this.selectedSubjectName,
    required this.onAddDiscussion,
    required this.onFilterOrSortChanged,
  });

  @override
  State<DiscussionsPanel> createState() => _DiscussionsPanelState();
}

class _DiscussionsPanelState extends State<DiscussionsPanel> {
  final TextEditingController _discussionSearchController =
      TextEditingController();
  bool _isSearchingDiscussions = false;

  @override
  void dispose() {
    _discussionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.discussionProvider == null ||
        widget.selectedSubjectName == null) {
      return const Center(child: Text('Pilih sebuah subjek dari panel tengah'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ChangeNotifierProvider.value(
          value: widget.discussionProvider!,
          child: Consumer<DiscussionProvider>(
            builder: (context, discussionProvider, child) {
              return Column(
                children: [
                  _buildDiscussionsToolbar(context, discussionProvider),
                  const Divider(height: 1),
                  Expanded(
                    child: DiscussionsPage(
                      subjectName: widget.selectedSubjectName!,
                      onFilterOrSortChanged: widget.onFilterOrSortChanged,
                      isEmbedded: true,
                      panelWidth: constraints.maxWidth, // Meneruskan lebar
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDiscussionsToolbar(
    BuildContext context,
    DiscussionProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: _isSearchingDiscussions
                ? TextField(
                    controller: _discussionSearchController,
                    autofocus: true,
                    onChanged: (value) => provider.searchQuery = value,
                    decoration: const InputDecoration(
                      hintText: 'Cari diskusi...',
                      border: InputBorder.none,
                    ),
                  )
                : const Text(
                    "Discussions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
          IconButton(
            icon: Icon(_isSearchingDiscussions ? Icons.close : Icons.search),
            tooltip: 'Cari Diskusi',
            onPressed: () {
              setState(() {
                _isSearchingDiscussions = !_isSearchingDiscussions;
                if (!_isSearchingDiscussions) {
                  _discussionSearchController.clear();
                  provider.searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Diskusi',
            onPressed: () => _showLinuxFilterDialog(context, provider),
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
                widget.onFilterOrSortChanged();
                showAppSnackBar(context, 'Diskusi telah diurutkan.');
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Diskusi',
            onPressed: () => widget.onAddDiscussion(),
          ),
        ],
      ),
    );
  }

  void _showLinuxFilterDialog(
    BuildContext context,
    DiscussionProvider provider,
  ) {
    showFilterDialog(
      context: context,
      isFilterActive: provider.activeFilterType != null,
      onClearFilters: () {
        provider.clearFilters();
        widget.onFilterOrSortChanged();
        showAppSnackBar(context, 'Semua filter telah dihapus.');
      },
      onShowRepetitionCodeFilter: () => showRepetitionCodeFilterDialog(
        context: context,
        repetitionCodes: provider.repetitionCodes,
        onSelectCode: (code) {
          provider.applyCodeFilter(code);
          widget.onFilterOrSortChanged();
          showAppSnackBar(context, 'Filter diterapkan: Kode = $code');
        },
      ),
      onShowDateFilter: () => showDateFilterDialog(
        context: context,
        initialDateRange: null,
        onSelectRange: (range) {
          provider.applyDateFilter(range);
          widget.onFilterOrSortChanged();
          showAppSnackBar(context, 'Filter tanggal diterapkan.');
        },
      ),
    );
  }
}
