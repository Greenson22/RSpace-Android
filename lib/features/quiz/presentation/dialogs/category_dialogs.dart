// lib/features/quiz/presentation/dialogs/category_dialogs.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';
import 'package:provider/provider.dart';
import '../../../content_management/presentation/topics/dialogs/topic_dialogs.dart';
import '../../application/quiz_category_provider.dart';
import '../../domain/models/quiz_model.dart';

void showEditQuizCategoryDialog(BuildContext context, QuizCategory category) {
  final provider = Provider.of<QuizCategoryProvider>(context, listen: false);
  showTopicTextInputDialog(
    context: context,
    title: 'Ubah Nama Kategori',
    label: 'Nama Kategori Baru',
    initialValue: category.name,
    onSave: (name) async {
      try {
        await provider.editCategoryName(category, name);
        if (context.mounted) {
          showAppSnackBar(context, 'Kategori berhasil diubah menjadi "$name".');
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnackBar(context, 'Gagal: ${e.toString()}', isError: true);
        }
      }
    },
  );
}

void showDeleteQuizCategoryDialog(BuildContext context, QuizCategory category) {
  final provider = Provider.of<QuizCategoryProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus Kategori'),
      content: Text(
        'Anda yakin ingin menghapus kategori "${category.name}" beserta semua topik dan kuis di dalamnya?',
      ),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Hapus'),
          onPressed: () async {
            Navigator.pop(context);
            try {
              await provider.deleteCategory(category);
              if (context.mounted) {
                showAppSnackBar(
                  context,
                  'Kategori "${category.name}" berhasil dihapus.',
                );
              }
            } catch (e) {
              if (context.mounted) {
                showAppSnackBar(
                  context,
                  'Gagal menghapus: ${e.toString()}',
                  isError: true,
                );
              }
            }
          },
        ),
      ],
    ),
  );
}
