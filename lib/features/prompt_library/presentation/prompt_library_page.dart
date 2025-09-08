// lib/features/prompt_library/presentation/prompt_library_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/prompt_provider.dart';

class PromptLibraryPage extends StatelessWidget {
  const PromptLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider kini berada di dalam direktori fitur
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
        // Tampilkan tombol kembali jika sedang melihat daftar prompt
        leading: provider.selectedCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => provider.clearCategorySelection(),
              )
            : null,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          // Tampilkan daftar kategori atau daftar prompt berdasarkan state
          : provider.selectedCategory == null
          ? _buildCategoryList(context, provider)
          : _buildPromptList(context, provider),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementasi logika untuk menambah kategori/prompt baru
        },
        tooltip: provider.selectedCategory == null
            ? 'Tambah Kategori'
            : 'Tambah Prompt',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget untuk menampilkan daftar kategori (folder)
  Widget _buildCategoryList(BuildContext context, PromptProvider provider) {
    if (provider.categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Pustaka Prompt masih kosong.\nBuat folder baru di dalam direktori "RSpace_data/data/prompt_library" untuk memulai.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
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

  // Widget untuk menampilkan daftar konsep prompt (file .json)
  Widget _buildPromptList(BuildContext context, PromptProvider provider) {
    if (provider.prompts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Tidak ada file prompt .json di dalam kategori "${provider.selectedCategory}".',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
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
