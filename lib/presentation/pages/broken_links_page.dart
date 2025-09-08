// lib/presentation/pages/broken_links_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/broken_link_provider.dart';
import '../../features/content_management/application/discussion_provider.dart';
import '../../features/content_management/application/subject_provider.dart';
import '../../features/content_management/application/topic_provider.dart';
import '../../features/content_management/presentation/subjects/subjects_page.dart';
import '../../features/content_management/presentation/discussions/discussions_page.dart';
import 'package:path/path.dart' as path;

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
                    '✅ Mantap! Semua tautan file valid.',
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
                return ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text(item.discussion.discussion),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lokasi: ${item.topic.name} > ${item.subject.name}'),
                      Text(
                        'Path Rusak: ${item.invalidPath}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    // Navigasi ke halaman diskusi yang relevan
                    final topicsPath = await Provider.of<TopicProvider>(
                      context,
                      listen: false,
                    ).getTopicsPath();
                    final topicPath = path.join(topicsPath, item.topic.name);
                    final subjectPath = path.join(
                      topicPath,
                      '${item.subject.name}.json',
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider(
                          create: (_) => SubjectProvider(topicPath),
                          child: SubjectsPage(topicName: item.topic.name),
                        ),
                      ),
                    ).then(
                      (value) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider(
                            create: (_) => DiscussionProvider(subjectPath),
                            child: DiscussionsPage(
                              subjectName: item.subject.name,
                              linkedPath: item.subject.linkedPath,
                            ),
                          ),
                        ),
                      ),
                    );
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
