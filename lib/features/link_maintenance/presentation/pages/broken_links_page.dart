// lib/features/link_maintenance/presentation/pages/broken_links_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/broken_link_provider.dart';

class BrokenLinksPage extends StatelessWidget {
  const BrokenLinksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BrokenLinkProvider(),
      child: const _BrokenLinksView(),
    );
  }
}

class _BrokenLinksView extends StatelessWidget {
  const _BrokenLinksView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BrokenLinkProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Tautan Rusak'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchBrokenLinks(),
            tooltip: 'Pindai Ulang',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchBrokenLinks(),
        child: Builder(
          builder: (context) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            if (provider.brokenLinks.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '🎉 Hebat! Tidak ada tautan file yang rusak ditemukan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: provider.brokenLinks.length,
              itemBuilder: (context, index) {
                final item = provider.brokenLinks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.heart_broken_outlined,
                      color: Colors.red,
                    ),
                    title: Text(item.discussion.discussion),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.topic.name} > ${item.subject.name}'),
                        Text(
                          'Path Rusak: ${item.invalidPath}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
