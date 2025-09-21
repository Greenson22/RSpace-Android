// lib/features/quiz/presentation/pages/quiz_category_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_category_provider.dart';
import '../../domain/models/quiz_model.dart';
import '../widgets/quiz_category_grid_tile.dart';
import 'quiz_page.dart';
import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
import '../dialogs/add_category_dialog.dart';
// ==> IMPORT DIALOGS BARU
import '../dialogs/category_dialogs.dart';

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
  void _showEditIconDialog(BuildContext context, QuizCategory category) {
    final provider = Provider.of<QuizCategoryProvider>(context, listen: false);
    showIconPickerDialog(
      context: context,
      name: category.name,
      onIconSelected: (newIcon) {
        provider.editCategoryIcon(category, newIcon);
      },
    );
  }

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
                    ).then((_) {
                      // Muat ulang data saat kembali dari halaman detail
                      provider.fetchCategories();
                    });
                  },
                  // >> SAMBUNGKAN FUNGSI KE CALLBACK <<
                  onEdit: () => showEditQuizCategoryDialog(context, category),
                  onDelete: () =>
                      showDeleteQuizCategoryDialog(context, category),
                  onIconChange: () => _showEditIconDialog(context, category),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddQuizCategoryDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
