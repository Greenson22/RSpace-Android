// lib/features/prompt_library/presentation/prompt_library_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
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

class _PromptLibraryView extends StatelessWidget {
  const _PromptLibraryView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PromptProvider>(context);
    final theme = Theme.of(context);

    final String pageTitle = provider.selectedCategory ?? 'Pustaka Prompt';

    return PopScope(
      canPop: provider.selectedCategory == null,
      onPopInvoked: (didPop) {
        if (!didPop && provider.selectedCategory != null) {
          provider.clearCategorySelection();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
          centerTitle: true,
          elevation: 0,
          leading: provider.selectedCategory != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => provider.clearCategorySelection(),
                )
              : null,
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
                    ? _buildCategoryGrid(context, provider)
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

  Widget _buildCategoryGrid(BuildContext context, PromptProvider provider) {
    if (provider.categories.isEmpty) {
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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        final colorSeed = Colors.primaries[index % Colors.primaries.length];

        return _PromptTopicTile(
          title: category,
          color: colorSeed,
          onTap: () => provider.selectCategory(category),
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
                'Folder "${provider.selectedCategory}" masih kosong.\nTambahkan prompt baru.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              // Search Bar
              Expanded(
                child: TextField(
                  onChanged: (value) => provider.setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: 'Cari prompt...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    suffixIcon: provider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sort Button (Fitur Baru)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<PromptSortType>(
                  icon: Icon(
                    provider.sortType == PromptSortType.titleAsc
                        ? Icons.sort_by_alpha
                        : Icons
                              .sort_by_alpha_outlined, // Atau icon lain jika ada
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Urutkan berdasarkan...',
                  onSelected: (PromptSortType result) {
                    provider.setSortType(result);
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
                                    provider.sortType == PromptSortType.titleAsc
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nama (A-Z)',
                                style: TextStyle(
                                  fontWeight:
                                      provider.sortType ==
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
                                    provider.sortType ==
                                        PromptSortType.titleDesc
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nama (Z-A)',
                                style: TextStyle(
                                  fontWeight:
                                      provider.sortType ==
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
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.filteredPrompts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ditemukan prompt dengan kata kunci\n"${provider.searchQuery}"',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.disabledColor),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(
                    16,
                  ).copyWith(top: 8, bottom: 80),
                  itemCount: provider.filteredPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = provider.filteredPrompts[index];
                    return _PromptCard(prompt: prompt, index: index);
                  },
                ),
        ),
      ],
    );
  }
}

class _PromptTopicTile extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _PromptTopicTile({
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.25)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.folder_copy_rounded, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget Card Prompt yang Diupdate
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

              // === POPUP MENU BUTTON UPDATE ===
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
                        // Untuk copy, boleh copy ke folder yang sama juga, jadi currentCategory tidak dibuang
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
