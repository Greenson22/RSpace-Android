// lib/features/quiz/presentation/pages/quiz_category_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_category_provider.dart';
import '../widgets/quiz_category_grid_tile.dart';
import 'quiz_page.dart';
import '../../domain/models/quiz_model.dart';

class QuizCategoryPage extends StatelessWidget {
  const QuizCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizCategoryProvider(),
      child: const _QuizCategoryView(),
    );
  }
}

class _QuizCategoryView extends StatefulWidget {
  const _QuizCategoryView();

  @override
  State<_QuizCategoryView> createState() => _QuizCategoryViewState();
}

class _QuizCategoryViewState extends State<_QuizCategoryView> {
  // Add state for reorder mode if needed in the future

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuizCategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Kuis')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.categories.isEmpty
          ? const Center(child: Text('Belum ada kategori kuis.'))
          : GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 1.1,
              ),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return QuizCategoryGridTile(
                  key: ValueKey(category.name),
                  category: category,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizPage(category: category),
                      ),
                    );
                  },
                  onEdit: () {}, // Implement edit dialog
                  onDelete: () {}, // Implement delete dialog
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement add category dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
