// lib/features/progress/presentation/dialogs/sub_materi_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _showAddSubMateriDialog(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );

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
                    position: position,
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Tambah di Posisi...'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
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
          // ==> OPSI BARU DITAMBAHKAN DI SINI <==
          const Divider(),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showAddRangedSubMateriDialog(context);
            },
            child: const ListTile(
              leading: Icon(Icons.format_list_numbered),
              title: Text('Tambah Rentang'),
              subtitle: Text('Contoh: Episode 1-10'),
            ),
          ),
        ],
      ),
    );
  }

  // ==> FUNGSI BARU UNTUK MENAMPILKAN DIALOG RENTANG <==
  void _showAddRangedSubMateriDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: Provider.of<ProgressDetailProvider>(context, listen: false),
        child: _AddRangedSubMateriDialog(subject: widget.subject),
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

  void _showDeleteAllConfirmDialog(
    BuildContext context,
    ProgressSubject subject,
  ) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Semua Sub-Materi?'),
        content: Text(
          'Anda yakin ingin menghapus semua ${subject.subMateri.length} sub-materi dari "${subject.namaMateri}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              provider.deleteAllSubMateri(subject);
              Navigator.pop(dialogContext);
            },
            child: const Text('Ya, Hapus Semua'),
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
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            if (currentSubject.subMateri.isNotEmpty && !_isReorderMode)
              TextButton(
                onPressed: () =>
                    _showDeleteAllConfirmDialog(context, currentSubject),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus Semua'),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _showAddSubMateriDialog(context),
                  child: const Text('Tambah Sub-Materi'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ==> WIDGET BARU UNTUK DIALOG TAMBAH RENTANG <==
class _AddRangedSubMateriDialog extends StatefulWidget {
  final ProgressSubject subject;

  const _AddRangedSubMateriDialog({required this.subject});

  @override
  State<_AddRangedSubMateriDialog> createState() =>
      _AddRangedSubMateriDialogState();
}

class _AddRangedSubMateriDialogState extends State<_AddRangedSubMateriDialog> {
  final _formKey = GlobalKey<FormState>();
  final _prefixController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  @override
  void dispose() {
    _prefixController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    return AlertDialog(
      title: const Text('Tambah Sub-Materi Berdasarkan Rentang'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _prefixController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Teks Awalan (Prefix)',
                  hintText: 'Contoh: Naruto Episode ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Teks awalan tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Dari'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harus diisi.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Sampai'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harus diisi.';
                        }
                        final start = int.tryParse(_startController.text);
                        final end = int.tryParse(value);
                        if (start != null && end != null && end < start) {
                          return 'Tidak boleh < dari';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final prefix = _prefixController.text.trim();
              final start = int.parse(_startController.text);
              final end = int.parse(_endController.text);
              provider.addSubMateriInRange(widget.subject, prefix, start, end);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Buat'),
        ),
      ],
    );
  }
}
