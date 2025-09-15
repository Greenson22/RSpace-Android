// lib/features/progress/presentation/dialogs/sub_materi_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/progress_detail_provider.dart';
import '../../domain/models/progress_subject_model.dart';

void showSubMateriDialog(BuildContext context, ProgressSubject subject) {
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
  bool _isReorderMode = false;

  // ==> FUNGSI INI SEKARANG MENAMPILKAN DIALOG PILIHAN POSISI <==
  void _showAddSubMateriDialog(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );

    // Fungsi helper untuk menampilkan dialog input teks setelah posisi dipilih
    void showNameInputDialog(SubMateriInsertPosition position) {
      final controller = TextEditingController();
      showDialog(
        context: context,
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
                  provider.addSubMateri(
                    widget.subject,
                    controller.text,
                    position: position, // Kirim posisi yang dipilih
                  );
                  Navigator.pop(dialogContext); // Tutup dialog input
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
    }

    // Tampilkan dialog pilihan posisi terlebih dahulu
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Tambah di Posisi...'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext); // Tutup dialog pilihan
              showNameInputDialog(SubMateriInsertPosition.top);
            },
            child: const ListTile(
              leading: Icon(Icons.vertical_align_top),
              title: Text('Paling Atas'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
              showNameInputDialog(SubMateriInsertPosition.beforeFinished);
            },
            child: const ListTile(
              leading: Icon(Icons.format_indent_decrease),
              title: Text('Sebelum Tugas Selesai'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
              showNameInputDialog(SubMateriInsertPosition.bottom);
            },
            child: const ListTile(
              leading: Icon(Icons.vertical_align_bottom),
              title: Text('Paling Bawah'),
            ),
          ),
        ],
      ),
    );
  }

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

        final subjectColor = currentSubject.backgroundColor != null
            ? Color(currentSubject.backgroundColor!)
            : Theme.of(context).primaryColor;

        return AlertDialog(
          title: Container(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 16.0),
            decoration: BoxDecoration(
              color: subjectColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28.0),
                topRight: Radius.circular(28.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    currentSubject.namaMateri,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isReorderMode ? Icons.check : Icons.sort,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isReorderMode = !_isReorderMode;
                    });
                  },
                  tooltip: _isReorderMode
                      ? 'Selesai Mengurutkan'
                      : 'Urutkan Daftar',
                ),
              ],
            ),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 24.0),
          content: SizedBox(
            width: double.maxFinite,
            child: currentSubject.subMateri.isEmpty
                ? const Center(child: Text('Belum ada sub-materi.'))
                : _isReorderMode
                ? ReorderableListView.builder(
                    shrinkWrap: true,
                    itemCount: currentSubject.subMateri.length,
                    itemBuilder: (context, index) {
                      final sub = currentSubject.subMateri[index];
                      return Card(
                        key: ValueKey(sub.namaMateri),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text(sub.namaMateri),
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ),
                      );
                    },
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderSubMateri(
                        currentSubject,
                        oldIndex,
                        newIndex,
                      );
                    },
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: currentSubject.subMateri.length,
                    itemBuilder: (context, index) {
                      final sub = currentSubject.subMateri[index];
                      final progressColor = _getProgressColor(sub.progress);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.circle,
                            color: progressColor,
                            size: 12.0,
                          ),
                          title: Text(sub.namaMateri),
                          subtitle: Text(
                            sub.progress,
                            style: TextStyle(
                              color: progressColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditSubMateriDialog(context, sub);
                              } else if (value == 'delete') {
                                _showDeleteConfirmDialog(context, sub);
                              } else if (value == 'move_bottom') {
                                provider.moveSubMateriToBottom(
                                  currentSubject,
                                  sub,
                                );
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
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green,
                                      ),
                                      title: Text('Selesai'),
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'sementara',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.hourglass_bottom_outlined,
                                        color: Colors.orange,
                                      ),
                                      title: Text('Sementara'),
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'belum',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.circle_outlined,
                                        color: Colors.grey,
                                      ),
                                      title: Text('Belum'),
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('Edit Nama'),
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'move_bottom',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons
                                            .keyboard_double_arrow_down_outlined,
                                      ),
                                      title: Text('Pindahkan ke Bawah'),
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      title: Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                          ),
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
