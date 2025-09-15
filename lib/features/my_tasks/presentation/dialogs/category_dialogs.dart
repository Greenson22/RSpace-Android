// lib/features/my_tasks/presentation/dialogs/category_dialogs.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:provider/provider.dart';
import '../../../content_management/presentation/topics/dialogs/topic_dialogs.dart';
// Tambahkan impor dengan alias untuk menghindari konflik nama
import '../../../../core/widgets/icon_picker_dialog.dart' as core_dialogs;

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
  // Panggil dialog ikon yang lebih canggih menggunakan alias
  core_dialogs.showIconPickerDialog(
    context: context,
    name: category.name, // Mengirim nama kategori untuk rekomendasi AI
    onIconSelected: (newIcon) {
      provider.updateCategoryIcon(category, newIcon);
      _showSnackBar(context, 'Ikon untuk "${category.name}" berhasil diubah.');
    },
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
