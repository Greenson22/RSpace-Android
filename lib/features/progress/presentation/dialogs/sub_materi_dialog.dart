// lib/features/progress/presentation/dialogs/sub_materi_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  // ==> STATE BARU UNTUK SELEKSI <==
  bool _isSelectionMode = false;
  final Set<SubMateri> _selectedSubMateri = {};

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

  void _showAddRangedSubMateriDialog(BuildContext context) {
    showDialog<SubMateriInsertPosition>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Tambah Rentang di Posisi...'),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(dialogContext, SubMateriInsertPosition.top),
            child: const ListTile(
              leading: Icon(Icons.vertical_align_top),
              title: Text('Paling Atas'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(
              dialogContext,
              SubMateriInsertPosition.beforeFinished,
            ),
            child: const ListTile(
              leading: Icon(Icons.format_indent_decrease),
              title: Text('Sebelum Tugas Selesai'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(dialogContext, SubMateriInsertPosition.bottom),
            child: const ListTile(
              leading: Icon(Icons.vertical_align_bottom),
              title: Text('Paling Bawah'),
            ),
          ),
        ],
      ),
    ).then((selectedPosition) {
      if (selectedPosition != null) {
        showDialog(
          context: context,
          builder: (_) => ChangeNotifierProvider.value(
            value: Provider.of<ProgressDetailProvider>(context, listen: false),
            child: _AddRangedSubMateriDialog(
              subject: widget.subject,
              position: selectedPosition,
            ),
          ),
        );
      }
    });
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

  // ==> FUNGSI BARU UNTUK HAPUS ITEM TERPILIH <==
  void _deleteSelectedItems(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Anda yakin ingin menghapus ${_selectedSubMateri.length} sub-materi yang dipilih?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await provider.deleteSelectedSubMateri(
                widget.subject,
                _selectedSubMateri,
              );
              setState(() {
                _selectedSubMateri.clear();
                _isSelectionMode = false;
              });
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

        final bool areAllSelected =
            _selectedSubMateri.length == currentSubject.subMateri.length &&
            currentSubject.subMateri.isNotEmpty;

        return AlertDialog(
          // ==> KONTEN TITLE DIPERBARUI DENGAN APPBAR <==
          title: _isSelectionMode
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedSubMateri.clear();
                      });
                    },
                  ),
                  title: Text('${_selectedSubMateri.length} dipilih'),
                  backgroundColor: Theme.of(context).primaryColorDark,
                  actions: [
                    IconButton(
                      icon: Icon(
                        areAllSelected ? Icons.deselect : Icons.select_all,
                      ),
                      onPressed: () {
                        setState(() {
                          if (areAllSelected) {
                            _selectedSubMateri.clear();
                          } else {
                            _selectedSubMateri.addAll(currentSubject.subMateri);
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _selectedSubMateri.isNotEmpty
                          ? () => _deleteSelectedItems(context)
                          : null,
                    ),
                  ],
                )
              : Container(
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
                        key: ValueKey(sub.hashCode),
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
                      final isSelected = _selectedSubMateri.contains(sub);
                      final progressColor = _getProgressColor(sub.progress);

                      final List<InlineSpan> subtitleSpans = [
                        TextSpan(
                          text: sub.progress,
                          style: TextStyle(
                            color: progressColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ];

                      if (sub.progress == 'selesai' &&
                          sub.finishedDate != null) {
                        try {
                          final finishedDateTime = DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).parse(sub.finishedDate!);
                          final formattedFinishedDate = DateFormat(
                            'EEEE, d MMM yyyy HH:mm',
                            'id_ID',
                          ).format(finishedDateTime);
                          subtitleSpans.add(
                            TextSpan(
                              text: ' • $formattedFinishedDate',
                              style: TextStyle(
                                color: Colors.blueGrey[400],
                                fontWeight: FontWeight.normal,
                                fontSize: 11,
                              ),
                            ),
                          );
                        } catch (e) {
                          subtitleSpans.add(
                            TextSpan(
                              text: ' • ${sub.finishedDate}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        elevation: 2.0,
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.2)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedSubMateri.remove(sub);
                                } else {
                                  _selectedSubMateri.add(sub);
                                }
                              });
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedSubMateri.add(sub);
                            });
                          },
                          leading: _isSelectionMode
                              ? Icon(
                                  isSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: Theme.of(context).primaryColor,
                                )
                              : Icon(
                                  Icons.circle,
                                  color: progressColor,
                                  size: 12.0,
                                ),
                          title: Text(sub.namaMateri),
                          subtitle: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12),
                              children: subtitleSpans,
                            ),
                          ),
                          trailing: _isSelectionMode
                              ? null
                              : PopupMenuButton<String>(
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
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
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
            if (currentSubject.subMateri.isNotEmpty &&
                !_isReorderMode &&
                !_isSelectionMode)
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

class _AddRangedSubMateriDialog extends StatefulWidget {
  final ProgressSubject subject;
  final SubMateriInsertPosition position;

  const _AddRangedSubMateriDialog({
    required this.subject,
    required this.position,
  });

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
                  if (value == null || value.isEmpty) {
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
              final prefix = _prefixController.text;
              final start = int.parse(_startController.text);
              final end = int.parse(_endController.text);
              provider.addSubMateriInRange(
                widget.subject,
                prefix,
                start,
                end,
                position: widget.position,
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Buat'),
        ),
      ],
    );
  }
}
