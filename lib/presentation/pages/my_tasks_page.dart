import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:provider/provider.dart';
import '../providers/my_task_provider.dart';
import '1_topics_page/dialogs/topic_dialogs.dart'; // Menggunakan dialog yang sudah ada

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddCategoryDialog(BuildContext context) {
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

  void _showRenameCategoryDialog(BuildContext context, TaskCategory category) {
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

  void _showDeleteCategoryDialog(BuildContext context, TaskCategory category) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
          'Anda yakin ingin menghapus kategori "${category.name}"?',
        ),
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyTaskProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('My Tasks')),
        body: Consumer<MyTaskProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.categories.isEmpty) {
              return const Center(
                child: Text('Tidak ada kategori. Tekan + untuk menambah.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return _buildCategoryCard(context, category);
              },
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () => _showAddCategoryDialog(context),
            child: const Icon(Icons.add),
            tooltip: 'Tambah Kategori',
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, TaskCategory category) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      child: ExpansionTile(
        leading: Icon(
          getIconData(category.icon),
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') {
              _showRenameCategoryDialog(context, category);
            } else if (value == 'delete') {
              _showDeleteCategoryDialog(context, category);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
        children: category.tasks.map((task) => _buildTaskTile(task)).toList(),
      ),
    );
  }

  Widget _buildTaskTile(MyTask task) {
    // ... (kode tile tugas tidak berubah)
    return ListTile(
      leading: Checkbox(
        value: task.checked,
        onChanged: (bool? value) {
          // Aksi saat checkbox diubah (belum diimplementasikan)
        },
      ),
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.checked ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text('Due: ${task.date}'),
      trailing: task.count > 0
          ? Chip(
              label: Text(task.count.toString()),
              backgroundColor: Colors.blue.shade100,
            )
          : null,
    );
  }
}
