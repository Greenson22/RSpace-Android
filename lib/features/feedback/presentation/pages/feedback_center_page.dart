// lib/presentation/pages/feedback_center_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/feedback_model.dart';
import '../../application/feedback_provider.dart';
import '../dialogs/feedback_dialogs.dart';
import '../widgets/feedback_card.dart';

class FeedbackCenterPage extends StatelessWidget {
  const FeedbackCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedbackProvider(),
      child: const _FeedbackCenterView(),
    );
  }
}

class _FeedbackCenterView extends StatelessWidget {
  const _FeedbackCenterView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FeedbackProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pusat Umpan Balik')),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: provider.filterType == null,
                    onSelected: (selected) => provider.setFilter(null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('💡 Ide'),
                    selected: provider.filterType == FeedbackType.idea,
                    onSelected: (selected) =>
                        provider.setFilter(FeedbackType.idea),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('🐞 Bug'),
                    selected: provider.filterType == FeedbackType.bug,
                    onSelected: (selected) =>
                        provider.setFilter(FeedbackType.bug),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('⭐ Saran'),
                    selected: provider.filterType == FeedbackType.suggestion,
                    onSelected: (selected) =>
                        provider.setFilter(FeedbackType.suggestion),
                  ),
                ],
              ),
            ),
          ),
          // Content List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.filteredItems.isEmpty
                ? const Center(child: Text('Tidak ada catatan ditemukan.'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: provider.filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = provider.filteredItems[index];
                      return FeedbackCard(item: item);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEditFeedbackDialog(context, provider: provider),
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
