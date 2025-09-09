// lib/features/progress/presentation/pages/progress_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/progress_detail_provider.dart';
import '../../domain/models/progress_subject_model.dart';

class ProgressDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(provider.topic.topics)),
      body: provider.topic.subjects.isEmpty
          ? const Center(child: Text('Belum ada materi di dalam topik ini.'))
          : ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 80,
              ), // Tambahkan padding bawah
              itemCount: provider.topic.subjects.length,
              itemBuilder: (context, index) {
                final subject = provider.topic.subjects[index];
                return ExpansionTile(
                  title: Text(subject.namaMateri),
                  subtitle: Text('Progress: ${subject.progress}'),
                  // Tambahkan tombol untuk menambah sub-materi
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddSubMateriDialog(context, subject),
                    tooltip: 'Tambah Sub-Materi',
                  ),
                  children: subject.subMateri
                      .map(
                        (sub) => ListTile(
                          title: Text(sub.namaMateri),
                          trailing: Text(sub.progress),
                          contentPadding: const EdgeInsets.only(
                            left: 32.0,
                            right: 16.0,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubjectDialog(context),
        tooltip: 'Tambah Materi Utama',
        child: const Icon(Icons.add_circle_outline),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Materi Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Materi'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addSubject(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Materi baru berhasil ditambahkan.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Fungsi baru untuk menampilkan dialog tambah sub-materi
  void _showAddSubMateriDialog(BuildContext context, ProgressSubject subject) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Sub-Materi untuk "${subject.namaMateri}"'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Sub-Materi'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addSubMateri(subject, controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sub-materi berhasil ditambahkan.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
