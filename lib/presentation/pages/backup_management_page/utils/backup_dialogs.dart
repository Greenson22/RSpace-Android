// lib/presentation/pages/backup_management_page/utils/backup_dialogs.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ==> IMPORT DITAMBAHKAN <==
import '../../../providers/backup_provider.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';

// ... (sisa kode tidak berubah)
Future<bool> showImportConfirmationDialog(
  BuildContext context,
  String type,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Konfirmasi Import $type'),
          content: const Text(
            'PERINGATAN: Tindakan ini akan menghapus semua data saat ini dan menggantinya dengan data dari file backup. Anda yakin ingin melanjutkan?',
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Lanjutkan'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ??
      false;
}

Future<bool> _showDeleteConfirmationDialog(
  BuildContext context,
  String message,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> showSortDialog(BuildContext context) async {
  final provider = Provider.of<BackupProvider>(context, listen: false);
  String sortType = provider.sortType;
  bool sortAscending = provider.sortAscending;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Urutkan File Backup'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urutkan berdasarkan:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<String>(
                  title: const Text('Tanggal Modifikasi'),
                  value: 'date',
                  groupValue: sortType,
                  onChanged: (value) => setDialogState(() => sortType = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Nama File'),
                  value: 'name',
                  groupValue: sortType,
                  onChanged: (value) => setDialogState(() => sortType = value!),
                ),
                const Divider(),
                const Text(
                  'Urutan:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<bool>(
                  title: const Text('Menurun (Descending)'),
                  value: false,
                  groupValue: sortAscending,
                  onChanged: (value) =>
                      setDialogState(() => sortAscending = value!),
                ),
                RadioListTile<bool>(
                  title: const Text('Menaik (Ascending)'),
                  value: true,
                  groupValue: sortAscending,
                  onChanged: (value) =>
                      setDialogState(() => sortAscending = value!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  provider.applySort(sortType, sortAscending);
                  Navigator.pop(context);
                },
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> deleteSelectedFiles(BuildContext context, List<File> files) async {
  final provider = Provider.of<BackupProvider>(context, listen: false);
  final count = files.isNotEmpty ? files.length : provider.selectedFiles.length;
  final confirmed = await _showDeleteConfirmationDialog(
    context,
    'Anda yakin ingin menghapus $count file yang dipilih?',
  );

  if (confirmed) {
    try {
      if (files.isNotEmpty) {
        for (var file in files) {
          await file.delete();
        }
        await provider.listBackupFiles();
      } else {
        await provider.deleteSelectedFiles();
      }
      if (context.mounted) {
        showAppSnackBar(context, '$count file backup berhasil dihapus.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Gagal menghapus file: $e', isError: true);
      }
    }
  }
}
