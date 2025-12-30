// lib/features/prompt_library/presentation/prompt_library_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/icon_picker_dialog.dart';
import '../application/prompt_provider.dart';
import '../domain/models/prompt_concept_model.dart';
import 'widgets/prompt_dialogs.dart';

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
    // Back dibolehkan jika TIDAK sedang search DAN TIDAK sedang membuka kategori
    final canPop = provider.selectedCategory == null && !_isSearching;

    return PopScope(
      canPop: canPop,
      onPopInvoked: (didPop) {
        if (didPop) return;

        // Skenario 1: Sedang Searching (baik di halaman utama atau dalam kategori)
        if (_isSearching) {
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
          return;
        }

        // Skenario 2: Sedang di dalam folder kategori (bukan searching)
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
                    ? _buildCategoryList(context, provider)
                    : _buildPromptList(context, provider),
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
    // Case 1: Sedang search (di manapun) -> Tombol Back menutup Search
    if (_isSearching) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            if (provider.selectedCategory == null) {
              provider.setCategorySearchQuery('');
            } else {
              provider.setSearchQuery('');
            }
          });
        },
      );
    }

    // Case 2: Sedang di dalam kategori (tidak search) -> Tombol Back kembali ke list kategori
    if (provider.selectedCategory != null) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => provider.clearCategorySelection(),
      );
    }

    // Case 3: Halaman utama biasa
    return null;
  }

  List<Widget> _buildActions(
    BuildContext context,
    PromptProvider provider,
    ThemeData theme,
  ) {
    // Jika sedang mode search, tampilkan tombol close (X)
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _searchController.clear();
            if (provider.selectedCategory == null) {
              provider.setCategorySearchQuery('');
            } else {
              provider.setSearchQuery('');
            }
          },
        ),
      ];
    }

    // --- ACTIONS SAAT DI HALAMAN LIST TOPIK (CATEGORY) ---
    if (provider.selectedCategory == null) {
      return [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Cari Topik',
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
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
        // Menu Lanjutan (Hidden)
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

    // --- ACTIONS SAAT DI HALAMAN LIST PROMPT ---
    return [
      IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Cari Prompt',
        onPressed: () {
          setState(() {
            _isSearching = true;
          });
        },
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

  Widget _buildCategoryList(BuildContext context, PromptProvider provider) {
    // Gunakan filteredCategories bukan categories mentah
    final categories = provider.filteredCategories;

    if (categories.isEmpty) {
      if (provider.categorySearchQuery.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ditemukan topik dengan nama\n"${provider.categorySearchQuery}"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada Topik Prompt.\nBuat topik baru untuk memulai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isHidden = category.startsWith('.');
        final displayName = isHidden ? category.substring(1) : category;
        final colorSeed =
            Colors.primaries[category.hashCode % Colors.primaries.length];

        final customIcon = provider.getCategoryIcon(category);

        return _PromptTopicListTile(
          title: displayName,
          originalName: category,
          color: isHidden ? Colors.grey : colorSeed,
          isHidden: isHidden,
          customIcon: customIcon,
          onTap: () {
            // Tutup search jika user memilih kategori
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                provider.setCategorySearchQuery('');
              });
            }
            provider.selectCategory(category);
          },
        );
      },
    );
  }

  Widget _buildPromptList(BuildContext context, PromptProvider provider) {
    final theme = Theme.of(context);

    if (provider.prompts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Folder ini masih kosong.\nTambahkan prompt baru.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // UBAH: Menghapus Widget Column wrapper yang sebelumnya berisi TextField search & Sort
    // Sekarang langsung return ListView atau Pesan Kosong (jika hasil filter kosong)

    if (provider.filteredPrompts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              'Tidak ditemukan prompt dengan kata kunci\n"${provider.searchQuery}"',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.disabledColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      itemCount: provider.filteredPrompts.length,
      itemBuilder: (context, index) {
        final prompt = provider.filteredPrompts[index];
        return _PromptCard(prompt: prompt, index: index);
      },
    );
  }
}

class _PromptTopicListTile extends StatelessWidget {
  final String title;
  final String originalName;
  final Color color;
  final bool isHidden;
  final String? customIcon;
  final VoidCallback onTap;

  const _PromptTopicListTile({
    required this.title,
    required this.originalName,
    required this.color,
    required this.isHidden,
    required this.customIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<PromptProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: customIcon != null
              ? Text(customIcon!, style: const TextStyle(fontSize: 24))
              : Icon(
                  isHidden ? Icons.visibility_off : Icons.folder_copy_rounded,
                  color: color,
                  size: 24,
                ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHidden ? Colors.grey : theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onSelected: (value) async {
            if (value == 'edit') {
              showRenameCategoryDialog(context, originalName);
            } else if (value == 'change_icon') {
              await showIconPickerDialog(
                context: context,
                name: title,
                onIconSelected: (newIcon) {
                  provider.updateCategoryIcon(originalName, newIcon);
                },
              );
            } else if (value == 'delete') {
              _showDeleteDialog(context, provider);
            } else if (value == 'hide') {
              provider.hideCategory(originalName);
            } else if (value == 'unhide') {
              provider.unhideCategory(originalName);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Ubah Nama'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'change_icon',
              child: Row(
                children: [
                  Icon(Icons.emoji_emotions_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Ubah Ikon'),
                ],
              ),
            ),
            PopupMenuItem(
              value: isHidden ? 'unhide' : 'hide',
              child: Row(
                children: [
                  Icon(
                    isHidden ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(isHidden ? 'Tampilkan' : 'Sembunyikan'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, PromptProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Topik'),
        content: Text(
          'Hapus topik "$title" dan SEMUA prompt di dalamnya?\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteCategory(originalName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Topik berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal hapus: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final PromptConcept prompt;
  final int index;

  const _PromptCard({required this.prompt, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<PromptProvider>(context, listen: false);
    final color = Colors.primaries[index % Colors.primaries.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showDetailDialog(context, prompt);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.article_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  final currentCategory = provider.selectedCategory;
                  if (currentCategory == null) return;

                  switch (value) {
                    case 'duplicate':
                      try {
                        await provider.duplicatePrompt(currentCategory, prompt);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Prompt berhasil diduplikasi.'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal duplikasi: $e')),
                          );
                        }
                      }
                      break;

                    case 'move':
                      final target = await showSelectTopicDialog(
                        context,
                        provider.categories,
                        currentCategory: currentCategory,
                        title: 'Pindah ke Topik...',
                      );
                      if (target != null && context.mounted) {
                        try {
                          await provider.movePrompt(
                            currentCategory,
                            target,
                            prompt,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Prompt dipindahkan ke "$target"',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal memindahkan: $e')),
                            );
                          }
                        }
                      }
                      break;

                    case 'copy':
                      final target = await showSelectTopicDialog(
                        context,
                        provider.categories,
                        title: 'Salin ke Topik...',
                      );
                      if (target != null && context.mounted) {
                        try {
                          await provider.copyPromptToCategory(target, prompt);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Prompt disalin ke "$target"'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal menyalin: $e')),
                            );
                          }
                        }
                      }
                      break;

                    case 'delete':
                      _showDeleteConfirmation(context, provider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20, color: Colors.grey),
                        SizedBox(width: 12),
                        Text('Duplikat'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'move',
                    child: Row(
                      children: [
                        Icon(
                          Icons.drive_file_move_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 12),
                        Text('Pindah ke...'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_copy_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 12),
                        Text('Salin ke...'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PromptProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Prompt'),
        content: Text(
          'Apakah Anda yakin ingin menghapus prompt "${prompt.title}"?\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final currentCategory = provider.selectedCategory;
              if (currentCategory != null) {
                try {
                  await provider.deletePrompt(currentCategory, prompt);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prompt berhasil dihapus.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, PromptConcept prompt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(prompt.title)),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pop(ctx);
                showEditPromptDialog(context, prompt);
              },
              tooltip: 'Edit Prompt',
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt.description,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Isi Prompt:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: MarkdownBody(
                    data: prompt.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: prompt.content));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Isi prompt disalin!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin'),
          ),
        ],
      ),
    );
  }
}
