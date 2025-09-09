// lib/features/progress/presentation/dialogs/sub_materi_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/progress_detail_provider.dart';
import '../../domain/models/progress_subject_model.dart';

// Fungsi untuk menampilkan dialog
void showSubMateriDialog(BuildContext context, ProgressSubject subject) {
  // Gunakan Provider.value untuk meneruskan provider yang sudah ada ke dialog
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: Provider.of<ProgressDetailProvider>(context, listen: false),
      child: SubMateriDialog(subject: subject),
    ),
  );
}

class SubMateriDialog extends StatefulWidget {
  final ProgressSubject subject;

  const SubMateriDialog({super.key, required this.subject});

  @override
  State<SubMateriDialog> createState() => _SubMateriDialogState();
}

class _SubMateriDialogState extends State<SubMateriDialog> {
  void _showAddSubMateriDialog(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    final controller = TextEditingController();
    showDialog(
      context: context,
      // Penting: Gunakan context dari builder agar tidak konflik
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Sub-Materi Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Sub-Materi'),
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
                // Panggil provider untuk menambahkan, lalu tutup dialog input
                provider.addSubMateri(widget.subject, controller.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Dialog baru untuk mengedit nama
  void _showEditSubMateriDialog(BuildContext context, SubMateri subMateri) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    final controller = TextEditingController(text: subMateri.namaMateri);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Nama Sub-Materi'),
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
                provider.editSubMateri(subMateri, controller.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Dialog baru untuk konfirmasi hapus
  void _showDeleteConfirmDialog(BuildContext context, SubMateri subMateri) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Anda yakin ingin menghapus sub-materi "${subMateri.namaMateri}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              provider.deleteSubMateri(widget.subject, subMateri);
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(String progress) {
    switch (progress) {
      case 'selesai':
        return Colors.green;
      case 'sementara':
        return Colors.orange;
      case 'belum':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressDetailProvider>(
      builder: (context, provider, child) {
        final currentSubject = provider.topic.subjects.firstWhere(
          (s) => s.namaMateri == widget.subject.namaMateri,
          orElse: () => widget.subject,
        );

        return AlertDialog(
          title: Text(currentSubject.namaMateri),
          content: SizedBox(
            width: double.maxFinite,
            child: currentSubject.subMateri.isEmpty
                ? const Center(child: Text('Belum ada sub-materi.'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: currentSubject.subMateri.length,
                    itemBuilder: (context, index) {
                      final sub = currentSubject.subMateri[index];
                      return ListTile(
                        title: Text(sub.namaMateri),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                sub.progress,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: _getProgressColor(sub.progress),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditSubMateriDialog(context, sub);
                                } else if (value == 'delete') {
                                  _showDeleteConfirmDialog(context, sub);
                                } else {
                                  provider.updateSubMateriProgress(
                                    currentSubject,
                                    sub,
                                    value,
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'selesai',
                                      child: Text('Ubah ke Selesai'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'sementara',
                                      child: Text('Ubah ke Sementara'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'belum',
                                      child: Text('Ubah ke Belum'),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Text('Edit Nama'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => _showAddSubMateriDialog(context),
              child: const Text('Tambah Sub-Materi'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
