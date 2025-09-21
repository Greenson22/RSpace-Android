// lib/features/quiz/presentation/pages/quiz_question_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import '../../domain/models/quiz_model.dart';
import '../dialogs/edit_question_dialog.dart';

class QuizQuestionListPage extends StatelessWidget {
  final QuizSet quizSet;

  const QuizQuestionListPage({super.key, required this.quizSet});

  @override
  Widget build(BuildContext context) {
    // Provider sudah tersedia dari halaman sebelumnya (QuizDetailPage)
    final provider = Provider.of<QuizDetailProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Edit Soal: ${quizSet.name}')),
      body: ReorderableListView.builder(
        itemCount: quizSet.questions.length,
        itemBuilder: (context, index) {
          final question = quizSet.questions[index];
          final correctAnswer = question.options.firstWhere(
            (o) => o.isCorrect,
            orElse: () => QuizOption(text: 'Tidak Ditemukan', isCorrect: true),
          );

          return Card(
            key: ValueKey(question.id),
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: Text('${index + 1}.'),
              title: Text(question.questionText),
              subtitle: Text(
                'Jawaban: ${correctAnswer.text}',
                style: const TextStyle(color: Colors.green),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showEditQuestionDialog(
                      context,
                      provider,
                      quizSet,
                      question,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDeleteQuestion(
                      context,
                      provider,
                      quizSet,
                      question,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          provider.reorderQuestions(quizSet, oldIndex, newIndex);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showEditQuestionDialog(context, provider, quizSet, null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Soal'),
      ),
    );
  }

  void _showEditQuestionDialog(
    BuildContext context,
    QuizDetailProvider provider,
    QuizSet quizSet,
    QuizQuestion? question,
  ) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: EditQuestionDialog(quizSet: quizSet, question: question),
      ),
    );
  }

  Future<void> _confirmDeleteQuestion(
    BuildContext context,
    QuizDetailProvider provider,
    QuizSet quizSet,
    QuizQuestion question,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pertanyaan?'),
        content: Text(
          'Anda yakin ingin menghapus pertanyaan ini secara permanen?\n\n"${question.questionText}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.deleteQuestion(quizSet, question);
    }
  }
}
