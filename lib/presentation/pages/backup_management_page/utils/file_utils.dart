// lib/presentation/pages/backup_management_page/utils/file_utils.dart
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';

String formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

Future<void> shareFile(BuildContext context, File file) async {
  try {
    final result = await Share.shareXFiles([
      XFile(file.path),
    ], text: 'File backup dari aplikasi saya.');

    if (result.status == ShareResultStatus.unavailable) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Fitur berbagi tidak tersedia, alihkan ke mode salin file.',
        );
        await copyBackupFile(context, file);
      }
    } else if (result.status == ShareResultStatus.success && context.mounted) {
      showAppSnackBar(context, 'File berhasil dibagikan.');
    }
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(
        context,
        'Gagal memulai fitur berbagi. Beralih ke mode salin file.',
        isError: true,
      );
      await copyBackupFile(context, file);
    }
  }
}

Future<void> copyBackupFile(BuildContext context, File sourceFile) async {
  try {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Lokasi untuk Menyimpan Salinan',
    );

    if (selectedDirectory != null) {
      final fileName = path.basename(sourceFile.path);
      final destinationPath = path.join(selectedDirectory, fileName);

      await sourceFile.copy(destinationPath);

      if (context.mounted) {
        showAppSnackBar(context, 'File berhasil disalin ke tujuan.');
      }
    } else {
      if (context.mounted) {
        showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
      }
    }
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, 'Gagal menyalin file: $e', isError: true);
    }
  }
}
