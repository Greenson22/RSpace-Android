// lib/features/quiz/presentation/pages/quiz_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import '../dialogs/add_quiz_dialog.dart';

class QuizDetailPage extends StatelessWidget {
  const QuizDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuizDetailProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(provider.topic.name)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.quizSets.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada kuis di dalam topik ini.\nTekan tombol + untuk membuat kuis baru.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: provider.quizSets.length,
              itemBuilder: (context, index) {
                final quizSet = provider.quizSets[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.quiz_outlined),
                    title: Text(quizSet.name.replaceAll('_', ' ')),
                    subtitle: Text('${quizSet.questions.length} pertanyaan'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        // Tambahkan konfirmasi sebelum menghapus
                        provider.deleteQuizSet(quizSet.name);
                      },
                    ),
                    onTap: () {
                      // TODO: Navigasi ke halaman untuk memulai kuis
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddQuizDialog(context),
        label: const Text('Buat Kuis Baru (AI)'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
