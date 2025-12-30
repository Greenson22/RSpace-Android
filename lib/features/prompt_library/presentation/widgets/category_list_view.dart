import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/prompt_provider.dart';
import 'prompt_category_tile.dart';

class CategoryListView extends StatelessWidget {
  final VoidCallback onCategorySelected;

  const CategoryListView({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PromptProvider>(context);
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

        return PromptCategoryTile(
          title: displayName,
          originalName: category,
          color: isHidden ? Colors.grey : colorSeed,
          isHidden: isHidden,
          customIcon: customIcon,
          onTap: () {
            onCategorySelected();
            provider.selectCategory(category);
          },
        );
      },
    );
  }
}
