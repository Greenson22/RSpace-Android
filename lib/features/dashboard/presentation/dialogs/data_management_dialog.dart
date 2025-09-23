// lib/features/dashboard/presentation/dialogs/data_management_dialog.dart

import 'package:flutter/material.dart';
import '../../../link_maintenance/presentation/pages/unlinked_discussions_page.dart';
import '../../../finished_discussions/presentation/pages/finished_discussions_page.dart';
import '../../../link_maintenance/presentation/pages/orphaned_files_page.dart';
import '../../../link_maintenance/presentation/pages/broken_links_page.dart';
import '../../../link_maintenance/presentation/pages/bulk_link_page.dart';
import '../../../exported_discussions_archive/presentation/pages/exported_discussions_page.dart';
import '../../../progress/presentation/pages/progress_page.dart';
import '../../../link_maintenance/presentation/pages/file_path_correction_page.dart';
import '../../../finished_discussions/presentation/pages/finished_discussions_online_page.dart'; // IMPORT BARU

/// Menampilkan dialog terpusat untuk fitur manajemen dan perawatan data.
void showDataManagementDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const DataManagementDialog(),
  );
}

class DataManagementDialog extends StatelessWidget {
  const DataManagementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Helper untuk membuat item list di dialog
    Widget _buildDialogOption({
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return SimpleDialogOption(
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SimpleDialog(
      title: const Text('Kelola & Perawatan Data'),
      children: <Widget>[
        _buildDialogOption(
          icon: Icons.auto_fix_high_outlined,
          title: 'Tautkan Diskusi Massal',
          subtitle:
              'Tautkan diskusi ke file HTML secara cepat dengan bantuan AI.',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BulkLinkPage()),
            );
          },
        ),
        _buildDialogOption(
          icon: Icons.inventory_2_outlined,
          title: 'Lihat Arsip Ekspor',
          subtitle: 'Jelajahi konten diskusi selesai yang telah Anda ekspor.',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ExportedDiscussionsPage(),
              ),
            );
          },
        ),
        _buildDialogOption(
          icon: Icons.show_chart,
          title: 'Progress',
          subtitle: 'Lihat progress belajar Anda.',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProgressPage()),
            );
          },
        ),
        _buildDialogOption(
          icon: Icons.link_off_outlined,
          title: 'Diskusi Tanpa Link (Individual)',
          subtitle: 'Lihat daftar diskusi yang belum memiliki tautan file.',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UnlinkedDiscussionsPage(),
              ),
            );
          },
        ),
        _buildDialogOption(
          icon: Icons.archive_outlined,
          title: 'Diskusi Selesai (Aktif)',
          subtitle:
              'Lihat & ekspor diskusi selesai yang ada di aplikasi saat ini.',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FinishedDiscussionsPage(),
              ),
            );
          },
        ),
        // >> OPSI MENU BARU DITAMBAHKAN DI SINI <<
        _buildDialogOption(
          icon: Icons.cloud_upload_outlined,
          title: 'Diskusi Selesai (Online)',
          subtitle: 'Kompres diskusi selesai untuk diunggah ke server.',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FinishedDiscussionsOnlinePage(),
              ),
            );
          },
        ),
        _buildDialogOption(
          icon: Icons.cleaning_services_outlined,
          title: 'File Yatim',
          subtitle: 'Temukan file HTML yang tidak tertaut ke diskusi manapun.',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrphanedFilesPage()),
            );
          },
        ),
        _buildDialogOption(
          icon: Icons.heart_broken_outlined,
          title: 'Cek Tautan Rusak',
          subtitle: 'Temukan diskusi yang tautan filenya rusak atau hilang.',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BrokenLinksPage()),
            );
          },
        ),
        _buildDialogOption(
          icon: Icons.build_outlined,
          title: 'Perbaiki Path File Lama',
          subtitle: 'Migrasikan format filePath lama ke format yang baru.',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FilePathCorrectionPage()),
            );
          },
        ),
      ],
    );
  }
}
