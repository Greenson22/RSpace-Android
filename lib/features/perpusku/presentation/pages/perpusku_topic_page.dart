// lib/features/perpusku/presentation/pages/perpusku_topic_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/perpusku_provider.dart';
import 'perpusku_subject_page.dart';

class PerpuskuTopicPage extends StatelessWidget {
  const PerpuskuTopicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchTopics(),
      child: const _PerpuskuTopicView(),
    );
  }
}

class _PerpuskuTopicView extends StatelessWidget {
  const _PerpuskuTopicView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PerpuskuProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perpusku - Topik')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.topics.isEmpty
          ? const Center(child: Text('Tidak ada topik ditemukan di Perpusku.'))
          : ListView.builder(
              itemCount: provider.topics.length,
              itemBuilder: (context, index) {
                final topic = provider.topics[index];
                return ListTile(
                  // >> PERUBAHAN DI SINI: Gunakan Text widget untuk menampilkan emoji ikon <<
                  leading: Text(
                    topic.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(topic.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerpuskuSubjectPage(topic: topic),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
