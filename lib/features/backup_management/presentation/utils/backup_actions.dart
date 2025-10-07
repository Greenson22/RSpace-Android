// lib/features/backup_management/presentation/utils/backup_actions.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../../application/backup_provider.dart';
import '../../../content_management/application/topic_provider.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';
import 'backup_dialogs.dart';

Future<void> backupContents(BuildContext context, String type) async {
  final provider = Provider.of<BackupProvider>(context, listen: false);
  showAppSnackBar(context, 'Memulai proses backup $type...');
  try {
    String message;
    if (type == 'RSpace') {
      message = await provider.backupRspaceContents();
    } else {
      message = await provider.backupPerpuskuContents();
    }
    if (context.mounted) showAppSnackBar(context, message);
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, 'Terjadi error saat backup: $e', isError: true);
    }
  }
}

Future<void> importContents(BuildContext context, String type) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['zip'],
  );
  if (result == null || result.files.single.path == null) {
    if (context.mounted) showAppSnackBar(context, 'Import dibatalkan.');
    return;
  }

  final zipFile = File(result.files.single.path!);
  // ==> PERBAIKAN DI SINI: Tambahkan parameter showConfirmation <==
  await importSpecificFile(context, zipFile, type, showConfirmation: true);
}

// ==> PERBAIKAN DI SINI: Tambahkan parameter showConfirmation pada definisi fungsi <==
Future<void> importSpecificFile(
  BuildContext context,
  File zipFile,
  String type, {
  required bool showConfirmation,
}) async {
  bool confirmed = true;
  if (showConfirmation) {
    confirmed = await showImportConfirmationDialog(context, type);
  }

  if (!confirmed) {
    if (context.mounted) {
      showAppSnackBar(context, 'Import dibatalkan oleh pengguna.');
    }
    return;
  }

  // Gunakan provider baru untuk operasi ini agar tidak mengganggu state provider utama
  final importOperationProvider = BackupProvider();
  showAppSnackBar(context, 'Memulai proses import...');
  try {
    await importOperationProvider.importContents(zipFile, type);
    if (context.mounted) {
      if (type == 'RSpace') {
        // Refresh data di provider yang relevan
        await Provider.of<TopicProvider>(context, listen: false).fetchTopics();
      }
      // Refresh daftar file backup di provider backup utama
      await Provider.of<BackupProvider>(
        context,
        listen: false,
      ).listBackupFiles();
      showAppSnackBar(context, 'Import $type berhasil!');
    }
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, 'Terjadi error saat import: $e', isError: true);
    }
  }
}

Future<void> uploadBackupFile(
  BuildContext context,
  File file,
  String type,
) async {
  final provider = Provider.of<BackupProvider>(context, listen: false);
  showAppSnackBar(context, 'Mengunggah file ${path.basename(file.path)}...');
  try {
    final message = await provider.uploadBackupFile(file, type);
    if (context.mounted) {
      showAppSnackBar(context, message);
    }
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, 'Gagal mengunggah file: $e', isError: true);
    }
  }
}
