// lib/features/perpusku/presentation/pages/perpusku_quiz_subject_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../perpusku/application/perpusku_provider.dart';
import '../../../perpusku/domain/models/perpusku_models.dart';
import 'quiz_list_page.dart';

class PerpuskuQuizSubjectPage extends StatelessWidget {
  final PerpuskuTopic topic;
  const PerpuskuQuizSubjectPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchSubjects(topic.path),
      child: _PerpuskuQuizSubjectView(topic: topic),
    );
  }
}

class _PerpuskuQuizSubjectView extends StatelessWidget {
  final PerpuskuTopic topic;
  const _PerpuskuQuizSubjectView({required this.topic});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PerpuskuProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(topic.name)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.subjects.isEmpty
          ? const Center(child: Text('Tidak ada subjek di dalam topik ini.'))
          : ListView.builder(
              itemCount: provider.subjects.length,
              itemBuilder: (context, index) {
                final subject = provider.subjects[index];
                return ListTile(
                  leading: Text(
                    subject.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(subject.name),
                  // ==> PERUBAHAN DI SINI <==
                  subtitle: Text('${subject.totalQuestions} pertanyaan'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerpuskuQuizListPage(subject: subject),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
