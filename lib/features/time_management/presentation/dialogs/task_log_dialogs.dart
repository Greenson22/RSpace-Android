// lib/presentation/pages/time_log_page/dialogs/task_log_dialogs.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/time_management/domain/models/log_task_preset_model.dart';
import 'package:my_aplication/features/time_management/domain/models/time_log_model.dart';
import 'package:my_aplication/features/time_management/application/providers/time_log_provider.dart';
import 'package:provider/provider.dart';

// FUNGSI BARU UNTUK KONFIRMASI PENGHAPUSAN
Future<bool?> showDeleteLogConfirmationDialog(
  BuildContext context,
  DateTime date,
) {
  final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Konfirmasi Hapus Jurnal'),
      content: Text(
        'Anda yakin ingin menghapus semua catatan aktivitas untuk tanggal $formattedDate?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Ya, Hapus'),
        ),
      ],
    ),
  );
}

// ==> FUNGSI DIPERBARUI UNTUK MENERIMA TANGGAL <==
void showAddTaskLogDialog(BuildContext context, {DateTime? date}) {
  final provider = Provider.of<TimeLogProvider>(context, listen: false);
  final controller = TextEditingController();
  String? selectedTaskName;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final presets = provider.taskPresets;
          return AlertDialog(
            title: const Text('Tambah Tugas Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (presets.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: selectedTaskName,
                      hint: const Text('Pilih dari preset'),
                      isExpanded: true,
                      items: presets
                          .map(
                            (preset) => DropdownMenuItem(
                              value: preset.name,
                              child: Text(preset.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedTaskName = value;
                          if (value != null) {
                            controller.text = value;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Atau buat baru di bawah ini:'),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: controller,
                    autofocus: presets.isEmpty,
                    decoration: const InputDecoration(labelText: 'Nama Tugas'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    // ==> Panggil provider dengan tanggal yang sesuai <==
                    provider.addTask(controller.text, date: date);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ... Sisa kode tidak berubah ...
void showEditDurationDialog(BuildContext context, LoggedTask task) {
  final provider = Provider.of<TimeLogProvider>(context, listen: false);
  final controller = TextEditingController(
    text: task.durationMinutes.toString(),
  );
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Ubah Durasi: ${task.name}'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Durasi (menit)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            final newDuration = int.tryParse(controller.text);
            if (newDuration != null) {
              provider.updateDuration(task, newDuration);
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

void showManagePresetsDialog(BuildContext context) {
  final provider = Provider.of<TimeLogProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Kelola Preset Tugas'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<TimeLogProvider>(
            builder: (context, provider, child) {
              final presets = provider.taskPresets;
              if (presets.isEmpty) {
                return const Center(child: Text('Belum ada preset.'));
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: presets.length,
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  return ListTile(
                    title: Text(preset.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _showEditPresetDialog(context, preset),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => provider.deletePreset(preset),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          if (provider.taskPresets.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showAddAllPresetsConfirmationDialog(
                  context,
                );
                if (confirmed ?? false) {
                  final count = await provider.addTasksFromPresets();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$count tugas dari preset berhasil ditambahkan ke jurnal aktif.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Tambah Semua ke Jurnal'),
            ),
          TextButton(
            onPressed: () => _showAddPresetDialog(context),
            child: const Text('Tambah Baru'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      );
    },
  );
}

Future<bool?> showAddAllPresetsConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Konfirmasi'),
      content: const Text(
        'Anda yakin ingin menambahkan semua tugas dari daftar preset ke jurnal yang sedang aktif? (Tugas yang sudah ada tidak akan ditambahkan lagi)',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Ya, Tambahkan'),
        ),
      ],
    ),
  );
}

void _showAddPresetDialog(BuildContext context) {
  final provider = Provider.of<TimeLogProvider>(context, listen: false);
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tambah Preset Baru'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nama Preset'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              provider.addPreset(controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

void _showEditPresetDialog(BuildContext context, LogTaskPreset preset) {
  final provider = Provider.of<TimeLogProvider>(context, listen: false);
  final controller = TextEditingController(text: preset.name);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ubah Nama Preset'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nama Baru'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              provider.updatePreset(preset, controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}
