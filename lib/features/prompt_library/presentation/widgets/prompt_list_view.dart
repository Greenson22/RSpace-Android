import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/prompt_provider.dart';
import 'prompt_card_item.dart';

class PromptListView extends StatelessWidget {
  const PromptListView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PromptProvider>(context);
    final theme = Theme.of(context);

    if (provider.prompts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Folder ini masih kosong.\nTambahkan prompt baru.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

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
        return PromptCardItem(prompt: prompt, index: index);
      },
    );
  }
}
