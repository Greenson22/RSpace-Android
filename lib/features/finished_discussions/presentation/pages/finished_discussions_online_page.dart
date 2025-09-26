// lib/features/finished_discussions/presentation/pages/finished_discussions_online_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/finished_discussions/application/finished_discussions_online_provider.dart';

class FinishedDiscussionsOnlinePage extends StatelessWidget {
  const FinishedDiscussionsOnlinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinishedDiscussionsOnlineProvider(),
      child: const _FinishedDiscussionsOnlineView(),
    );
  }
}

class _FinishedDiscussionsOnlineView extends StatelessWidget {
  const _FinishedDiscussionsOnlineView();

  Future<void> _handleArchive(BuildContext context) async {
    final provider = Provider.of<FinishedDiscussionsOnlineProvider>(
      context,
      listen: false,
    );
    if (provider.isExporting) return;

    final discussionsToArchive = provider.isSelectionMode
        ? provider.selectedDiscussions.length
        : provider.finishedDiscussions.length;

    if (discussionsToArchive == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada diskusi untuk diarsipkan.')),
      );
      return;
    }

    try {
      final message = await provider.archiveSelectedDiscussions();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        // Clear selection and refresh list after archiving
        provider.clearSelection();
        provider.fetchFinishedDiscussions();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengarsipkan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinishedDiscussionsOnlineProvider>(context);

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
                  tooltip: 'Pilih Semua',
                ),
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () => _handleArchive(context),
                  tooltip: 'Arsipkan Pilihan',
                ),
              ],
            )
          : AppBar(
              title: const Text('Arsipkan Diskusi Selesai'),
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
                    onPressed: () => _handleArchive(context),
                    tooltip: 'Arsipkan Semua',
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
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Semua diskusi aktif.\nTidak ada yang bisa diarsipkan saat ini.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
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
