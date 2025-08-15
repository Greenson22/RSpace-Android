// lib/presentation/pages/linux/my_tasks_page_linux.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:my_aplication/presentation/providers/my_task_provider.dart';
import 'my_tasks_view_linux/categories_panel.dart';
import 'my_tasks_view_linux/tasks_panel.dart';

class MyTasksPageLinux extends StatelessWidget {
  const MyTasksPageLinux({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyTaskProvider(),
      child: const _MyTasksPageLinuxContent(),
    );
  }
}

class _MyTasksPageLinuxContent extends StatefulWidget {
  const _MyTasksPageLinuxContent();

  @override
  State<_MyTasksPageLinuxContent> createState() =>
      _MyTasksPageLinuxContentState();
}

class _MyTasksPageLinuxContentState extends State<_MyTasksPageLinuxContent> {
  TaskCategory? _selectedCategory;

  void _onCategorySelected(TaskCategory category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context);

    // Jika kategori yang dipilih dihapus atau disembunyikan, reset pilihan
    if (_selectedCategory != null &&
        !provider.categories.contains(_selectedCategory)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedCategory = null;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Tasks${_selectedCategory != null ? ': ${_selectedCategory!.name}' : ''}',
        ),
        actions: [
          IconButton(
            icon: Icon(
              provider.showHiddenCategories
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            tooltip: provider.showHiddenCategories
                ? 'Sembunyikan Kategori Tersembunyi'
                : 'Tampilkan Kategori Tersembunyi',
            onPressed: () => provider.toggleShowHidden(),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Hapus Semua Centang',
            onPressed: () => _showUncheckAllConfirmationDialog(context),
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 300, // Lebar panel kategori
            child: CategoriesPanel(
              onCategorySelected: _onCategorySelected,
              selectedCategory: _selectedCategory,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: TasksPanel(selectedCategory: _selectedCategory)),
        ],
      ),
    );
  }

  void _showUncheckAllConfirmationDialog(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Anda yakin ingin menghapus semua centang dari task?',
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: const Text('Ya, Hapus'),
            onPressed: () {
              provider.uncheckAllTasks();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semua centang telah dihapus.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
