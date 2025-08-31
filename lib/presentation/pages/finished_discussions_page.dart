// lib/presentation/pages/finished_discussions_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/finished_discussions_provider.dart';

class FinishedDiscussionsPage extends StatelessWidget {
  const FinishedDiscussionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinishedDiscussionsProvider(),
      child: const _FinishedDiscussionsView(),
    );
  }
}

class _FinishedDiscussionsView extends StatelessWidget {
  const _FinishedDiscussionsView();

  Future<void> _confirmAndDelete(BuildContext context) async {
    final provider = Provider.of<FinishedDiscussionsProvider>(
      context,
      listen: false,
    );
    final count = provider.selectedDiscussions.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Anda yakin ingin menghapus $count diskusi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.deleteSelected();
    }
  }

  // >> FUNGSI INI DIPERBARUI TOTAL
  Future<void> _handleExport(BuildContext context) async {
    final provider = Provider.of<FinishedDiscussionsProvider>(
      context,
      listen: false,
    );
    if (provider.isExporting) return;

    final discussionsToExport = provider.isSelectionMode
        ? provider.selectedDiscussions.length
        : provider.finishedDiscussions.length;

    if (discussionsToExport == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada diskusi untuk diekspor.')),
      );
      return;
    }

    // Tampilkan dialog konfirmasi
    final result = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Ekspor'),
        content: Text(
          'Anda akan mengekspor $discussionsToExport diskusi. Setelah diekspor, apakah Anda ingin menghapus diskusi ini dari aplikasi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null), // Batal
            child: const Text('Batal'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false), // Ekspor Saja
            child: const Text('Ekspor Saja'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Ekspor & Hapus
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Ekspor & Hapus'),
          ),
        ],
      ),
    );

    // Jika pengguna tidak membatalkan
    if (result != null && context.mounted) {
      try {
        final message = await provider.exportFinishedDiscussions(
          deleteAfterExport: result,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengekspor: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinishedDiscussionsProvider>(context);

    return Scaffold(
      appBar: provider.isSelectionMode
          ? AppBar(
              title: Text('${provider.selectedDiscussions.length} dipilih'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => provider.clearSelection(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () => provider.selectAll(),
                ),
                // >> BARU: Tombol Ekspor di mode seleksi
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () => _handleExport(context),
                  tooltip: 'Ekspor Pilihan',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmAndDelete(context),
                ),
              ],
            )
          : AppBar(
              title: const Text('Semua Diskusi Selesai'),
              actions: [
                if (provider.isExporting)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () => _handleExport(context),
                    tooltip: 'Ekspor Semua',
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.fetchFinishedDiscussions(),
                ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchFinishedDiscussions(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.finishedDiscussions.isEmpty
            ? const Center(child: Text('Tidak ada diskusi yang selesai.'))
            : ListView.builder(
                itemCount: provider.finishedDiscussions.length,
                itemBuilder: (context, index) {
                  final item = provider.finishedDiscussions[index];
                  final isSelected = provider.selectedDiscussions.contains(
                    item,
                  );
                  return ListTile(
                    onTap: () => provider.toggleSelection(item),
                    onLongPress: () => provider.toggleSelection(item),
                    leading: isSelected
                        ? const Icon(Icons.check_circle)
                        : const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                    title: Text(item.discussion.discussion),
                    subtitle: Text(
                      '${item.topicName} > ${item.subjectName}\nSelesai pada: ${item.discussion.finish_date != null ? DateFormat('d MMM yyyy').format(DateTime.parse(item.discussion.finish_date!)) : 'N/A'}',
                    ),
                    tileColor: isSelected ? Colors.blue.withOpacity(0.2) : null,
                  );
                },
              ),
      ),
    );
  }
}
