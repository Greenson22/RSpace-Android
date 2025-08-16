// lib/presentation/pages/backup_management_page/utils/backup_actions.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/backup_provider.dart';
import '../../../providers/topic_provider.dart';
import '../../1_topics_page/utils/scaffold_messenger_utils.dart';
import 'backup_dialogs.dart';

Future<void> selectBackupFolder(BuildContext context) async {
  final provider = Provider.of<BackupProvider>(context, listen: false);
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
    dialogTitle: 'Pilih Folder Tujuan Backup',
  );

  if (selectedDirectory != null) {
    await provider.setBackupPath(selectedDirectory);
    if (context.mounted) {
      showAppSnackBar(context, 'Folder tujuan backup berhasil diatur.');
    }
  } else {
    if (context.mounted) {
      showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
    }
  }
}

Future<void> selectPerpuskuDataFolder(BuildContext context) async {
  final provider = Provider.of<BackupProvider>(context, listen: false);
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
    dialogTitle: 'Pilih Folder Sumber Data PerpusKu',
  );

  if (selectedDirectory != null) {
    await provider.setPerpuskuDataPath(selectedDirectory);
    if (context.mounted) {
      showAppSnackBar(context, 'Folder sumber data PerpusKu berhasil diatur.');
    }
  } else {
    if (context.mounted) {
      showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
    }
  }
}

Future<void> backupContents(BuildContext context, String type) async {
  final provider = Provider.of<BackupProvider>(context, listen: false);
  if (provider.backupPath == null || provider.backupPath!.isEmpty) {
    showAppSnackBar(
      context,
      'Folder tujuan backup belum ditentukan.',
      isError: true,
    );
    return;
  }

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
  await importSpecificFile(context, zipFile, type);
}

Future<void> importSpecificFile(
  BuildContext context,
  File zipFile,
  String type,
) async {
  final confirmed = await showImportConfirmationDialog(context, type);
  if (!confirmed) {
    if (context.mounted) {
      showAppSnackBar(context, 'Import dibatalkan oleh pengguna.');
    }
    return;
  }

  showAppSnackBar(context, 'Memulai proses import...');
  final provider = Provider.of<BackupProvider>(context, listen: false);
  try {
    await provider.importContents(zipFile, type);
    if (context.mounted) {
      if (type == 'RSpace') {
        await Provider.of<TopicProvider>(context, listen: false).fetchTopics();
      }
      showAppSnackBar(context, 'Import $type berhasil!');
    }
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, 'Terjadi error saat import: $e', isError: true);
    }
  }
}
