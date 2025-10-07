// lib/features/link_maintenance/presentation/pages/unlinked_discussions_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/providers/unlinked_discussions_provider.dart';
import '../../domain/models/unlinked_discussion_model.dart';
import 'package:my_aplication/features/content_management/application/discussion_provider.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/discussions_page.dart';
import 'package:path/path.dart' as path;

class UnlinkedDiscussionsPage extends StatelessWidget {
  const UnlinkedDiscussionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UnlinkedDiscussionsProvider(),
      child: const _UnlinkedDiscussionsView(),
    );
  }
}

class _UnlinkedDiscussionsView extends StatelessWidget {
  const _UnlinkedDiscussionsView();

  void _navigateToDiscussion(BuildContext context, UnlinkedDiscussion item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => DiscussionProvider(
            item.subjectJsonPath,
            linkedPath: item.subjectLinkedPath,
            subject: item.subject,
          ),
          child: DiscussionsPage(
            subjectName: item.subjectName,
            linkedPath: item.subjectLinkedPath,
          ),
        ),
      ),
    ).then((_) {
      // Refresh list after returning
      Provider.of<UnlinkedDiscussionsProvider>(
        context,
        listen: false,
      ).fetchAllUnlinkedDiscussions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UnlinkedDiscussionsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diskusi Tanpa Tautan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchAllUnlinkedDiscussions(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchAllUnlinkedDiscussions(),
        child: Builder(
          builder: (context) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.unlinkedDiscussions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '🎉 Semua diskusi sudah memiliki tautan file!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: provider.unlinkedDiscussions.length,
              itemBuilder: (context, index) {
                final item = provider.unlinkedDiscussions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.link_off, color: Colors.orange),
                    title: Text(item.discussion.discussion),
                    subtitle: Text('${item.topicName} > ${item.subjectName}'),
                    onTap: () => _navigateToDiscussion(context, item),
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
