// lib/presentation/pages/bulk_link_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        bottom: provider.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const Center(child: Text('Memuat diskusi tanpa tautan...'));
          }

          if (provider.isFinished) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '🎉 Semua diskusi telah diproses!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }

          return BulkLinkCard(
            discussion: provider.currentDiscussion!,
            suggestions: provider.currentSuggestions,
            onSkip: () => provider.nextDiscussion(),
            onLink: (relativePath) =>
                provider.linkCurrentDiscussion(relativePath),
            onSearch: (query) => provider.searchFiles(query),
          );
        },
      ),
    );
  }
}
