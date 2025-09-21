// lib/features/quiz/presentation/dialogs/add_category_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../content_management/presentation/topics/dialogs/topic_dialogs.dart';
import '../../application/quiz_category_provider.dart';

void showAddQuizCategoryDialog(BuildContext context) {
  final provider = Provider.of<QuizCategoryProvider>(context, listen: false);
  showTopicTextInputDialog(
    context: context,
    title: 'Tambah Kategori Kuis Baru',
    label: 'Nama Kategori',
    onSave: (name) {
      try {
        provider.addCategory(name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kategori "$name" berhasil ditambahkan.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
  );
}
