// lib/features/progress/presentation/pages/progress_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/progress_detail_provider.dart';
import '../../domain/models/progress_subject_model.dart';

class ProgressDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(provider.topic.topics)),
      body: ListView.builder(
        itemCount: provider.topic.subjects.length,
        itemBuilder: (context, index) {
          final subject = provider.topic.subjects[index];
          return ExpansionTile(
            title: Text(subject.namaMateri),
            subtitle: Text('Progress: ${subject.progress}'),
            children: subject.subMateri
                .map(
                  (sub) => ListTile(
                    title: Text(sub.namaMateri),
                    trailing: Text(sub.progress),
                  ),
                )
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementasi tambah materi
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
