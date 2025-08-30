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
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmAndDelete(context),
                ),
              ],
            )
          : AppBar(
              title: const Text('Semua Diskusi Selesai'),
              actions: [
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
