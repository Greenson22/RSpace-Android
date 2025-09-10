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
          : provider.topic.questions.isEmpty
          ? const Center(child: Text('Belum ada pertanyaan di kuis ini.'))
          : ListView.builder(
              itemCount: provider.topic.questions.length,
              itemBuilder: (context, index) {
                final question = provider.topic.questions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(question.questionText),
                    subtitle: Text(
                      '${question.options.length} pilihan jawaban',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => provider.deleteQuestion(question.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddQuizDialog(context),
        label: const Text('Tambah Pertanyaan'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
