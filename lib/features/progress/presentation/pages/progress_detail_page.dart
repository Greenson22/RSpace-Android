// lib/features/progress/presentation/pages/progress_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/progress_detail_provider.dart';
import '../../domain/models/progress_subject_model.dart';
// Import dialog dan widget baru
import '../dialogs/sub_materi_dialog.dart';
import '../widgets/progress_subject_grid_tile.dart';

class ProgressDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(context);

    int _getCrossAxisCount(double screenWidth) {
      if (screenWidth > 1200) return 5;
      if (screenWidth > 900) return 4;
      if (screenWidth > 600) return 3;
      return 2;
    }

    return Scaffold(
      appBar: AppBar(title: Text(provider.topic.topics)),
      body: provider.topic.subjects.isEmpty
          ? const Center(child: Text('Belum ada materi di dalam topik ini.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: provider.topic.subjects.length,
                  itemBuilder: (context, index) {
                    final subject = provider.topic.subjects[index];
                    return ProgressSubjectGridTile(
                      subject: subject,
                      onTap: () {
                        showSubMateriDialog(context, subject);
                      },
                      // Implementasikan onEdit dan onDelete
                      onEdit: () => _showEditSubjectDialog(context, subject),
                      onDelete: () =>
                          _showDeleteConfirmDialog(context, subject),
                    );
                  },
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

  // Dialog baru untuk mengedit nama subject
  void _showEditSubjectDialog(BuildContext context, ProgressSubject subject) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    final controller = TextEditingController(text: subject.namaMateri);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Nama Materi'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.editSubject(subject, controller.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Dialog baru untuk konfirmasi hapus subject
  void _showDeleteConfirmDialog(BuildContext context, ProgressSubject subject) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Anda yakin ingin menghapus materi "${subject.namaMateri}" beserta semua sub-materinya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              provider.deleteSubject(subject);
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
