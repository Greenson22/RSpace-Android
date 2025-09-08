// lib/features/prompt_library/presentation/prompt_library_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/prompt_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.selectedCategory ?? 'Pustaka Prompt'),
        leading: provider.selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => provider.clearCategorySelection(),
              )
            : null,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.selectedCategory == null
          ? _buildCategoryList(context, provider)
          : _buildPromptList(context, provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (provider.selectedCategory == null) {
            showAddCategoryDialog(context);
          } else {
            showAddPromptDialog(context);
          }
        },
        tooltip: provider.selectedCategory == null
            ? 'Tambah Kategori'
            : 'Tambah Prompt',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, PromptProvider provider) {
    if (provider.categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Pustaka Prompt masih kosong.\nTekan tombol + untuk membuat kategori baru.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return ListTile(
          leading: const Icon(Icons.folder_open_outlined),
          title: Text(category),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => provider.selectCategory(category),
        );
      },
    );
  }

  Widget _buildPromptList(BuildContext context, PromptProvider provider) {
    if (provider.prompts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Tidak ada file prompt .json di dalam kategori "${provider.selectedCategory}".\nTekan tombol + untuk menambahkan prompt baru.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: provider.prompts.length,
      itemBuilder: (context, index) {
        final prompt = provider.prompts[index];
        return ListTile(
          leading: const Icon(Icons.article_outlined),
          title: Text(prompt.judulUtama),
          subtitle: Text(
            prompt.deskripsiUtama,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            // TODO: Navigasi ke halaman detail untuk melihat variasi prompt
          },
        );
      },
    );
  }
}
