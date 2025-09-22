// lib/features/link_maintenance/presentation/pages/file_path_correction_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/file_path_correction_provider.dart';

class FilePathCorrectionPage extends StatelessWidget {
  const FilePathCorrectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FilePathCorrectionProvider(),
      child: const _FilePathCorrectionView(),
    );
  }
}

class _FilePathCorrectionView extends StatelessWidget {
  const _FilePathCorrectionView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FilePathCorrectionProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perbaiki Path File Lama')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.build_circle_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Alat ini akan memindai semua data diskusi Anda dan memperbaiki format `filePath` yang usang agar sesuai dengan struktur data terbaru. Proses ini aman untuk dijalankan beberapa kali.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (provider.isLoading)
                const CircularProgressIndicator()
              else if (provider.isFinished)
                _buildResultView(context, provider, theme)
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Mulai Pemindaian & Perbaikan'),
                  onPressed: () => provider.runCorrection(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultView(
    BuildContext context,
    FilePathCorrectionProvider provider,
    ThemeData theme,
  ) {
    if (provider.error != null) {
      return Text(
        'Terjadi error: ${provider.error}',
        style: TextStyle(color: theme.colorScheme.error),
      );
    }

    final results = provider.results;
    final filesScanned = results['filesScanned'] ?? 0;
    final filesCorrected = results['filesCorrected'] ?? 0;
    final entriesUpdated = results['entriesUpdated'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Proses Selesai!', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildResultRow('Total File Dipindai:', '$filesScanned'),
            _buildResultRow('File yang Diperbaiki:', '$filesCorrected'),
            _buildResultRow('Entri Path Diperbarui:', '$entriesUpdated'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => provider.runCorrection(),
              child: const Text('Jalankan Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
