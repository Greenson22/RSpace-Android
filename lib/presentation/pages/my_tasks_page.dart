import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/my_task_model.dart';
import '../providers/my_task_provider.dart';

class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

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
              return const Center(child: Text('Tidak ada tugas ditemukan.'));
            }

            return ListView.builder(
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return _buildCategoryCard(context, category);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, TaskCategory category) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        children: category.tasks.map((task) => _buildTaskTile(task)).toList(),
      ),
    );
  }

  Widget _buildTaskTile(MyTask task) {
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
