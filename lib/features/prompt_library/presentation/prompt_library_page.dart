import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/prompt_provider.dart';
import 'widgets/prompt_dialogs.dart';
import 'widgets/category_list_view.dart';
import 'widgets/prompt_list_view.dart';

class PromptLibraryPage extends StatelessWidget {
  const PromptLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PromptProvider(),
      child: const _PromptLibraryView(),
    );
  }
}

class _PromptLibraryView extends StatefulWidget {
  const _PromptLibraryView();

  @override
  State<_PromptLibraryView> createState() => _PromptLibraryViewState();
}

class _PromptLibraryViewState extends State<_PromptLibraryView> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch(PromptProvider provider) {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      // Reset query berdasarkan halaman aktif
      if (provider.selectedCategory != null) {
        provider.setSearchQuery('');
      } else {
        provider.setCategorySearchQuery('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PromptProvider>(context);
    final theme = Theme.of(context);

    String pageTitle = provider.selectedCategory ?? 'Pustaka Prompt';
    if (provider.selectedCategory != null &&
        provider.selectedCategory!.startsWith('.')) {
      pageTitle = provider.selectedCategory!.substring(1);
    }

    // Tentukan apakah back dibolehkan (untuk menutup search dulu)
    final canPop = provider.selectedCategory == null && !_isSearching;

    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) {
        if (didPop) return;

        // Skenario 1: Sedang Searching
        if (_isSearching) {
          _clearSearch(provider);
          return;
        }

        // Skenario 2: Sedang di dalam folder kategori
        if (provider.selectedCategory != null) {
          provider.clearCategorySelection();
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: provider.selectedCategory == null
                        ? 'Cari topik...'
                        : 'Cari prompt...',
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  onChanged: (value) {
                    if (provider.selectedCategory == null) {
                      provider.setCategorySearchQuery(value);
                    } else {
                      provider.setSearchQuery(value);
                    }
                  },
                )
              : Text(pageTitle),
          centerTitle: true,
          elevation: 0,
          leading: _buildLeading(provider),
          actions: _buildActions(context, provider, theme),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.scaffoldBackgroundColor,
                      theme.colorScheme.surface.withOpacity(0.5),
                    ],
                  ),
                ),
                child: provider.selectedCategory == null
                    ? CategoryListView(
                        onCategorySelected: () {
                          // Jika user memilih kategori saat searching, matikan mode search
                          if (_isSearching) {
                            _clearSearch(provider);
                          }
                        },
                      )
                    : const PromptListView(),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (provider.selectedCategory == null) {
              showAddCategoryDialog(context);
            } else {
              showAddPromptDialog(context);
            }
          },
          icon: const Icon(Icons.add),
          label: Text(
            provider.selectedCategory == null ? 'Topik Baru' : 'Prompt Baru',
          ),
        ),
      ),
    );
  }

  Widget? _buildLeading(PromptProvider provider) {
    if (_isSearching) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _clearSearch(provider),
      );
    }

    if (provider.selectedCategory != null) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => provider.clearCategorySelection(),
      );
    }

    return null;
  }

  List<Widget> _buildActions(
    BuildContext context,
    PromptProvider provider,
    ThemeData theme,
  ) {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _clearSearch(provider),
        ),
      ];
    }

    // ACTIONS SAAT DI HALAMAN LIST TOPIK (CATEGORY)
    if (provider.selectedCategory == null) {
      return [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Cari Topik',
          onPressed: () => setState(() => _isSearching = true),
        ),
        PopupMenuButton<PromptSortType>(
          icon: const Icon(Icons.sort_by_alpha),
          tooltip: 'Urutkan Topik',
          onSelected: (PromptSortType result) {
            provider.setCategorySortType(result);
          },
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<PromptSortType>>[
                PopupMenuItem<PromptSortType>(
                  value: PromptSortType.titleAsc,
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color:
                            provider.categorySortType == PromptSortType.titleAsc
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nama (A-Z)',
                        style: TextStyle(
                          fontWeight:
                              provider.categorySortType ==
                                  PromptSortType.titleAsc
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<PromptSortType>(
                  value: PromptSortType.titleDesc,
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        size: 18,
                        color:
                            provider.categorySortType ==
                                PromptSortType.titleDesc
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nama (Z-A)',
                        style: TextStyle(
                          fontWeight:
                              provider.categorySortType ==
                                  PromptSortType.titleDesc
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'toggle_hidden') {
              provider.toggleShowHidden();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_hidden',
              child: Row(
                children: [
                  Icon(
                    provider.showHidden
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.showHidden
                        ? 'Sembunyikan Hidden'
                        : 'Tampilkan Hidden',
                  ),
                ],
              ),
            ),
          ],
        ),
      ];
    }

    // ACTIONS SAAT DI HALAMAN LIST PROMPT
    return [
      IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Cari Prompt',
        onPressed: () => setState(() => _isSearching = true),
      ),
      PopupMenuButton<PromptSortType>(
        icon: const Icon(Icons.sort_by_alpha),
        tooltip: 'Urutkan Prompt',
        onSelected: (PromptSortType result) {
          provider.setSortType(result);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<PromptSortType>>[
          PopupMenuItem<PromptSortType>(
            value: PromptSortType.titleAsc,
            child: Row(
              children: [
                Icon(
                  Icons.arrow_upward,
                  size: 18,
                  color: provider.sortType == PromptSortType.titleAsc
                      ? theme.colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nama (A-Z)',
                  style: TextStyle(
                    fontWeight: provider.sortType == PromptSortType.titleAsc
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<PromptSortType>(
            value: PromptSortType.titleDesc,
            child: Row(
              children: [
                Icon(
                  Icons.arrow_downward,
                  size: 18,
                  color: provider.sortType == PromptSortType.titleDesc
                      ? theme.colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nama (Z-A)',
                  style: TextStyle(
                    fontWeight: provider.sortType == PromptSortType.titleDesc
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }
}
