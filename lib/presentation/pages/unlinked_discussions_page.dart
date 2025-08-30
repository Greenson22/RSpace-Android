// lib/presentation/pages/unlinked_discussions_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/discussion_provider.dart';
import '../providers/unlinked_discussions_provider.dart';
import '3_discussions_page.dart';

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

class _UnlinkedDiscussionsView extends StatefulWidget {
  const _UnlinkedDiscussionsView();

  @override
  State<_UnlinkedDiscussionsView> createState() =>
      _UnlinkedDiscussionsViewState();
}

class _UnlinkedDiscussionsViewState extends State<_UnlinkedDiscussionsView> {
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
            tooltip: 'Perbarui Daftar',
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
                    'Luar biasa! Semua diskusi sudah memiliki tautan file.',
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
                return ListTile(
                  leading: const Icon(Icons.link_off, color: Colors.orange),
                  title: Text(item.discussion.discussion),
                  subtitle: Text('${item.topicName} > ${item.subjectName}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (_) =>
                              DiscussionProvider(item.subjectJsonPath),
                          child: DiscussionsPage(
                            subjectName: item.subjectName,
                            linkedPath: item.subjectLinkedPath,
                          ),
                        ),
                      ),
                    ).then((_) {
                      // Setelah kembali dari halaman diskusi, muat ulang daftar
                      provider.fetchAllUnlinkedDiscussions();
                    });
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
