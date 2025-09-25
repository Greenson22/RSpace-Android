// lib/features/archive/presentation/pages/archive_topic_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/archive/application/archive_provider.dart';
import 'package:my_aplication/features/archive/presentation/pages/archive_subject_page.dart';
import 'package:provider/provider.dart';

class ArchiveTopicPage extends StatelessWidget {
  const ArchiveTopicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ArchiveProvider()..fetchArchivedTopics(),
      child: const _ArchiveTopicView(),
    );
  }
}

class _ArchiveTopicView extends StatelessWidget {
  const _ArchiveTopicView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ArchiveProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Topik Arsip')),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.topics.isEmpty) {
            return const Center(
              child: Text('Folder arsip kosong atau tidak ditemukan.'),
            );
          }
          return ListView.builder(
            itemCount: provider.topics.length,
            itemBuilder: (context, index) {
              final topic = provider.topics[index];
              return ListTile(
                leading: Text(topic.icon, style: const TextStyle(fontSize: 24)),
                title: Text(topic.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArchiveSubjectPage(topic: topic),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
