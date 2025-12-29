// lib/features/prompt_library/presentation/prompt_library_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk Clipboard
import 'package:flutter_markdown/flutter_markdown.dart'; // Import Markdown
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

    // Menentukan judul halaman berdasarkan state
    final String pageTitle = provider.selectedCategory ?? 'Pustaka Prompt';

    // Handle back button behavior manually to clear category selection
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

  // TAMPILAN GRID KATEGORI
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

  // TAMPILAN LIST PROMPT
  Widget _buildPromptList(BuildContext context, PromptProvider provider) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      itemCount: provider.prompts.length,
      itemBuilder: (context, index) {
        final prompt = provider.prompts[index];
        return _PromptCard(prompt: prompt);
      },
    );
  }
}

// =============================================================================
// WIDGETS TAMBAHAN
// =============================================================================

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

// Widget Card Prompt Baru (Versi Ringkas: Hanya Judul)
class _PromptCard extends StatelessWidget {
  final PromptConcept prompt;

  const _PromptCard({required this.prompt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<PromptProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 8), // Margin sedikit diperkecil
      elevation: 1, // Elevasi sedikit dikurangi agar lebih flat
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
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              // Icon Kiri
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.article_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Judul Prompt (Hanya Judul)
              Expanded(
                child: Text(
                  prompt.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Tombol Hapus (Tanpa Edit)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.grey, // Warna lebih subtle sampai ditekan
                ),
                // Gunakan style tombol agar merah saat dihover/tekan jika diinginkan
                style: IconButton.styleFrom(
                  hoverColor: theme.colorScheme.error.withOpacity(0.1),
                  highlightColor: theme.colorScheme.error.withOpacity(0.2),
                ),
                onPressed: () => _showDeleteConfirmation(context, provider),
                tooltip: 'Hapus Prompt',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk konfirmasi hapus
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
              Navigator.pop(ctx); // Tutup dialog

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

  // Helper untuk melihat detail prompt
  void _showDetailDialog(BuildContext context, PromptConcept prompt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(prompt.title)),
            // Tombol Edit tetap ada di dalam detail view
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
                // Deskripsi muncul di sini
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
