// lib/presentation/pages/bulk_link_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/topic_model.dart';
import '../providers/bulk_link_provider.dart';
import 'bulk_link_page/widgets/bulk_link_card.dart';

class BulkLinkPage extends StatelessWidget {
  const BulkLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BulkLinkProvider(),
      child: const _BulkLinkView(),
    );
  }
}

class _BulkLinkView extends StatelessWidget {
  const _BulkLinkView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BulkLinkProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tautkan Diskusi Massal'),
        bottom: provider.currentState == BulkLinkState.loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: _buildContent(context, provider),
    );
  }

  Widget _buildContent(BuildContext context, BulkLinkProvider provider) {
    switch (provider.currentState) {
      case BulkLinkState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: 16),
              Text('Memuat data...'),
            ],
          ),
        );

      case BulkLinkState.selectingTopic:
        return _TopicSelectionView(
          topics: provider.topics,
          unlinkedCounts: provider.unlinkedCounts,
          totalUnlinkedCount: provider.totalUnlinkedCount,
          onTopicSelected: (topicName) {
            provider.startLinking(topicName: topicName);
          },
        );

      case BulkLinkState.linking:
        return BulkLinkCard(
          discussion: provider.currentDiscussion!,
          suggestions: provider.currentSuggestions,
          onSkip: () => provider.nextDiscussion(),
          onLink: (relativePath) =>
              provider.linkCurrentDiscussion(relativePath),
          onSearch: (query) => provider.searchFiles(query),
          currentDiscussionNumber: provider.currentDiscussionNumber,
          totalDiscussions: provider.totalDiscussionsToProcess,
          // >> BARU: Sambungkan callback ke provider
          onCreateNew: () async {
            try {
              await provider.createAndLinkDiscussion();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );

      case BulkLinkState.finished:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.done_all, color: Colors.green, size: 60),
                SizedBox(height: 16),
                Text(
                  '🎉 Selesai!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Semua diskusi yang relevan telah diproses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _TopicSelectionView extends StatelessWidget {
  final List<Topic> topics;
  final Map<String, int> unlinkedCounts;
  final int totalUnlinkedCount;
  final Function(String?) onTopicSelected;

  const _TopicSelectionView({
    required this.topics,
    required this.unlinkedCounts,
    required this.totalUnlinkedCount,
    required this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('Pilih Cakupan', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Pilih topik spesifik untuk ditautkan, atau proses semua topik sekaligus.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text(
              'Semua Topik',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Chip(label: Text('$totalUnlinkedCount Diskusi')),
            onTap: () => onTopicSelected(null),
            enabled: totalUnlinkedCount > 0,
          ),
        ),
        const Divider(height: 24),
        ...topics.where((t) => !t.isHidden).map((topic) {
          final count = unlinkedCounts[topic.name] ?? 0;
          return Card(
            child: ListTile(
              leading: Text(topic.icon, style: const TextStyle(fontSize: 24)),
              title: Text(topic.name),
              trailing: Chip(label: Text('$count Diskusi')),
              onTap: () => onTopicSelected(topic.name),
              enabled: count > 0,
            ),
          );
        }).toList(),
      ],
    );
  }
}
