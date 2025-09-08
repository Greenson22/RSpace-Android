// lib/presentation/pages/time_log_page/dialogs/link_task_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/data/models/time_log_model.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:my_aplication/presentation/providers/time_log_provider.dart';
import 'package:provider/provider.dart';

// Fungsi utama untuk menampilkan dialog
void showLinkTaskDialog(BuildContext context, LoggedTask task) {
  showDialog(
    context: context,
    builder: (_) => MultiProvider(
      providers: [
        // Sediakan provider yang dibutuhkan di dalam dialog
        ChangeNotifierProvider.value(
          value: Provider.of<TimeLogProvider>(context),
        ),
        ChangeNotifierProvider(create: (_) => MyTaskProvider()),
      ],
      child: LinkTaskDialog(task: task),
    ),
  );
}

class LinkTaskDialog extends StatefulWidget {
  final LoggedTask task;
  const LinkTaskDialog({super.key, required this.task});

  // ==> KESALAHAN ADA DI SINI & SUDAH DIPERBAIKI <==
  @override
  State<LinkTaskDialog> createState() => _LinkTaskDialogState();
}

class _LinkTaskDialogState extends State<LinkTaskDialog> {
  late Set<String> _selectedTaskIds;

  @override
  void initState() {
    super.initState();
    // Inisialisasi ID yang sudah terpilih sebelumnya
    _selectedTaskIds = Set<String>.from(widget.task.linkedTaskIds);
  }

  @override
  Widget build(BuildContext context) {
    // Dapatkan provider
    final timeLogProvider = Provider.of<TimeLogProvider>(
      context,
      listen: false,
    );
    final myTaskProvider = Provider.of<MyTaskProvider>(context);

    return AlertDialog(
      title: const Text('Hubungkan ke My Tasks'),
      content: SizedBox(
        width: double.maxFinite,
        child: myTaskProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                shrinkWrap: true,
                itemCount: myTaskProvider.categories.length,
                itemBuilder: (context, index) {
                  final category = myTaskProvider.categories[index];
                  // Jangan tampilkan kategori yang tersembunyi
                  if (category.isHidden) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text(
                          category.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ...category.tasks.map((myTask) {
                        return CheckboxListTile(
                          title: Text(myTask.name),
                          value: _selectedTaskIds.contains(myTask.id),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedTaskIds.add(myTask.id);
                              } else {
                                _selectedTaskIds.remove(myTask.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            // Panggil provider untuk menyimpan perubahan
            timeLogProvider.updateLinkedTasks(
              widget.task,
              _selectedTaskIds.toList(),
            );
            Navigator.pop(context);
          },
          child: const Text('Simpan Koneksi'),
        ),
      ],
    );
  }
}
