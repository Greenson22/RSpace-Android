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

    // Fungsi untuk menentukan jumlah kolom berdasarkan lebar layar
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
          // Ganti ListView.builder dengan GridView.builder
          : LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio:
                        1.2, // Sesuaikan rasio agar kartu tidak terlalu tinggi
                  ),
                  itemCount: provider.topic.subjects.length,
                  itemBuilder: (context, index) {
                    final subject = provider.topic.subjects[index];
                    return ProgressSubjectGridTile(
                      subject: subject,
                      onTap: () {
                        showSubMateriDialog(context, subject);
                      },
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
}
