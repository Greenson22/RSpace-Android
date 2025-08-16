// lib/presentation/pages/my_tasks_page/dialogs/category_dialogs.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:my_aplication/presentation/providers/my_task_provider.dart';
import 'package:provider/provider.dart';
import '../../1_topics_page/dialogs/topic_dialogs.dart';

void showAddCategoryDialog(BuildContext context) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showTopicTextInputDialog(
    context: context,
    title: 'Tambah Kategori Baru',
    label: 'Nama Kategori',
    onSave: (name) {
      provider.addCategory(name);
      _showSnackBar(context, 'Kategori "$name" berhasil ditambahkan.');
    },
  );
}

void showRenameCategoryDialog(BuildContext context, TaskCategory category) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showTopicTextInputDialog(
    context: context,
    title: 'Ubah Nama Kategori',
    label: 'Nama Baru',
    initialValue: category.name,
    onSave: (newName) {
      provider.renameCategory(category, newName);
      _showSnackBar(context, 'Kategori diubah menjadi "$newName".');
    },
  );
}

void showDeleteCategoryDialog(BuildContext context, TaskCategory category) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus Kategori'),
      content: Text('Anda yakin ingin menghapus kategori "${category.name}"?'),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: const Text('Hapus'),
          onPressed: () {
            provider.deleteCategory(category);
            Navigator.pop(context);
            _showSnackBar(
              context,
              'Kategori "${category.name}" berhasil dihapus.',
            );
          },
        ),
      ],
    ),
  );
}

void showIconPickerDialog(BuildContext context, TaskCategory category) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  final List<String> icons = ['📝', '💼', '🏠', '🛒', '🎉', '💡', '❤️', '⭐'];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Pilih Ikon Baru'),
      content: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: icons.map((iconSymbol) {
          return InkWell(
            onTap: () {
              provider.updateCategoryIcon(category, iconSymbol);
              Navigator.pop(context);
              _showSnackBar(
                context,
                'Ikon untuk "${category.name}" berhasil diubah.',
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(iconSymbol, style: const TextStyle(fontSize: 32)),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

void _showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
    ),
  );
}
