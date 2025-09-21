// lib/features/perpusku/presentation/pages/perpusku_subject_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/perpusku_provider.dart';
import '../../domain/models/perpusku_models.dart';
import 'perpusku_file_list_page.dart';

class PerpuskuSubjectPage extends StatelessWidget {
  final PerpuskuTopic topic;
  const PerpuskuSubjectPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchSubjects(topic.path),
      child: _PerpuskuSubjectView(topic: topic),
    );
  }
}

class _PerpuskuSubjectView extends StatelessWidget {
  final PerpuskuTopic topic;
  const _PerpuskuSubjectView({required this.topic});

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
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(subject.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerpuskuFileListPage(subject: subject),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
