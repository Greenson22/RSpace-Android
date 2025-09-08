// lib/features/prompt_library/presentation/prompt_library_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../application/prompt_provider.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Pustaka Prompt')),
      body: const Center(child: Text('Halaman ini sedang dalam pengembangan.')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aksi untuk menambah prompt baru akan ditambahkan di sini
        },
        tooltip: 'Tambah Prompt',
        child: const Icon(Icons.add),
      ),
    );
  }
}
