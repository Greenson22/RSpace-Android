import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/my_task_model.dart';
import 'package:provider/provider.dart';
import '../providers/my_task_provider.dart';
import '1_topics_page/dialogs/topic_dialogs.dart';

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

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

  // --- Dialog untuk Kategori ---
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

  // --- Dialog untuk Task ---
  void _showAddTaskDialog(BuildContext context, TaskCategory category) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showTopicTextInputDialog(
      context: context,
      title: 'Tambah Task Baru',
      label: 'Nama Task',
      onSave: (name) {
        provider.addTask(category, name);
        _showSnackBar(context, 'Task "$name" berhasil ditambahkan.');
      },
    );
  }

  void _showRenameTaskDialog(
    BuildContext context,
    TaskCategory category,
    MyTask task,
  ) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showTopicTextInputDialog(
      context: context,
      title: 'Ubah Nama Task',
      label: 'Nama Baru',
      initialValue: task.name,
      onSave: (newName) {
        provider.renameTask(category, task, newName);
        _showSnackBar(context, 'Task diubah menjadi "$newName".');
      },
    );
  }

  void _showDeleteTaskDialog(
    BuildContext context,
    TaskCategory category,
    MyTask task,
  ) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Task'),
        content: Text('Anda yakin ingin menghapus task "${task.name}"?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Hapus'),
            onPressed: () {
              provider.deleteTask(category, task);
              Navigator.pop(context);
              _showSnackBar(context, 'Task "${task.name}" berhasil dihapus.');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateDateDialog(
    BuildContext context,
    TaskCategory category,
    MyTask task,
  ) async {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    final initialDate = DateTime.tryParse(task.date) ?? DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (newDate != null) {
      provider.updateTaskDate(category, task, newDate);
      _showSnackBar(context, 'Tanggal task berhasil diubah.');
    }
  }

  void _showUpdateCountDialog(
    BuildContext context,
    TaskCategory category,
    MyTask task,
  ) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    showTopicTextInputDialog(
      context: context,
      title: 'Ubah Jumlah (Count)',
      label: 'Jumlah Baru',
      initialValue: task.count.toString(),
      keyboardType: TextInputType.number,
      onSave: (newValue) {
        final newCount = int.tryParse(newValue);
        if (newCount != null) {
          provider.updateTaskCount(category, task, newCount);
          _showSnackBar(context, 'Jumlah task berhasil diubah.');
        } else {
          _showSnackBar(
            context,
            'Input tidak valid. Harap masukkan angka.',
            isError: true,
          );
        }
      },
    );
  }

  // ==> DIALOG KONFIRMASI BARU <==
  Future<bool?> _showToggleConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penyelesaian'),
        content: const Text(
          'Update tanggal ke hari ini dan tambah jumlah (count) sebanyak 1?',
        ),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Ya, Update'),
            onPressed: () => Navigator.of(context).pop(true),
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
                return _buildCategoryCard(context, provider, category);
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
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
  ) {
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
            } else if (value == 'add_task') {
              _showAddTaskDialog(context, category);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'add_task', child: Text('Tambah Task')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
        children: category.tasks
            .map((task) => _buildTaskTile(context, provider, category, task))
            .toList(),
      ),
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    MyTaskProvider provider,
    TaskCategory category,
    MyTask task,
  ) {
    return ListTile(
      // ==> LOGIKA CHECKBOX DIPERBARUI <==
      leading: Checkbox(
        value: task.checked,
        onChanged: (bool? value) async {
          if (value == true) {
            // Jika akan mencentang
            final shouldUpdate = await _showToggleConfirmationDialog(context);
            if (shouldUpdate == true) {
              provider.toggleTaskChecked(category, task, confirmUpdate: true);
            }
          } else {
            // Jika akan menghilangkan centang
            provider.toggleTaskChecked(category, task, confirmUpdate: false);
          }
        },
      ),
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.checked ? TextDecoration.lineThrough : null,
          color: task.checked ? Colors.grey : null,
        ),
      ),
      subtitle: Text('Due: ${task.date} | Count: ${task.count}'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'rename') {
            _showRenameTaskDialog(context, category, task);
          } else if (value == 'edit_date') {
            _showUpdateDateDialog(context, category, task);
          } else if (value == 'edit_count') {
            _showUpdateCountDialog(context, category, task);
          } else if (value == 'delete') {
            _showDeleteTaskDialog(context, category, task);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
          const PopupMenuItem(value: 'edit_date', child: Text('Ubah Tanggal')),
          const PopupMenuItem(value: 'edit_count', child: Text('Ubah Jumlah')),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
