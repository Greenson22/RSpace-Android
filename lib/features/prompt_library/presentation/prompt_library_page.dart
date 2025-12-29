// lib/features/prompt_library/presentation/prompt_library_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/prompt_provider.dart';
import '../domain/models/prompt_concept_model.dart'; // Pastikan import ini ada untuk akses model
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

    // Handle back button behavior manually if needed,
    // but usually AppBar handles leading automatically well.
    // Here we strictly control it to clear category selection.

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
              : null, // Default back button logic for main page
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

  // TAMPILAN GRID KATEGORI (Seperti Halaman Progress)
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
        crossAxisCount: 2, // 2 Kolom
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1, // Rasio aspek kartu
      ),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        // Generate warna pastel unik berdasarkan index/nama
        final colorSeed = Colors.primaries[index % Colors.primaries.length];

        return _PromptTopicTile(
          title: category,
          color: colorSeed,
          onTap: () => provider.selectCategory(category),
        );
      },
    );
  }

  // TAMPILAN LIST PROMPT (Card yang lebih rapi)
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
// WIDGETS TAMBAHAN (Bisa dipisah ke file widget sendiri jika ingin lebih rapi)
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

class _PromptCard extends StatelessWidget {
  final PromptConcept prompt;

  const _PromptCard({required this.prompt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variationCount = prompt.variasiPrompt.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Navigasi ke detail prompt / variasi
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Membuka ${prompt.judulUtama}...")),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tips_and_updates,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prompt.judulUtama,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prompt.deskripsiUtama,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.copy_all_rounded,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$variationCount Variasi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
