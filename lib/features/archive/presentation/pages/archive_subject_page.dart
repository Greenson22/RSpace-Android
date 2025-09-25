// lib/features/archive/presentation/pages/archive_subject_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/archive/application/archive_provider.dart';
import 'package:my_aplication/features/archive/presentation/pages/archive_discussion_page.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:provider/provider.dart';

class ArchiveSubjectPage extends StatelessWidget {
  final Topic topic;
  const ArchiveSubjectPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ArchiveProvider()..fetchArchivedSubjects(topic.name),
      child: _ArchiveSubjectView(topic: topic),
    );
  }
}

class _ArchiveSubjectView extends StatelessWidget {
  final Topic topic;
  const _ArchiveSubjectView({required this.topic});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ArchiveProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(topic.name)),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.subjects.isEmpty) {
            return const Center(
              child: Text('Tidak ada subjek di dalam arsip topik ini.'),
            );
          }
          return ListView.builder(
            itemCount: provider.subjects.length,
            itemBuilder: (context, index) {
              final subject = provider.subjects[index];
              return ListTile(
                leading: Text(
                  subject.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(subject.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArchiveDiscussionPage(subject: subject),
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
