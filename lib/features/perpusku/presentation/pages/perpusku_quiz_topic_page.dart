// lib/features/perpusku/presentation/pages/perpusku_quiz_topic_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/perpusku_provider.dart';
import 'perpusku_quiz_subject_page.dart';

class PerpuskuQuizTopicPage extends StatelessWidget {
  const PerpuskuQuizTopicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchTopics(),
      child: const _PerpuskuQuizTopicView(),
    );
  }
}

class _PerpuskuQuizTopicView extends StatelessWidget {
  const _PerpuskuQuizTopicView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PerpuskuProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kuis Perpusku - Pilih Topik')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.topics.isEmpty
          ? const Center(child: Text('Tidak ada topik ditemukan di Perpusku.'))
          : ListView.builder(
              itemCount: provider.topics.length,
              itemBuilder: (context, index) {
                final topic = provider.topics[index];
                return ListTile(
                  leading: Text(
                    topic.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(topic.name),
                  // ==> PERUBAHAN DI SINI <==
                  subtitle: Text('${topic.subjectCount} subjek'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerpuskuQuizSubjectPage(topic: topic),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
