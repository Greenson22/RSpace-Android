// lib/features/quiz/presentation/pages/quiz_list_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/quiz/application/quiz_provider.dart';
import 'package:provider/provider.dart';
import '../../../perpusku/domain/models/perpusku_models.dart';
import 'quiz_question_list_page.dart';
import 'package:my_aplication/features/quiz/application/quiz_detail_provider.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:my_aplication/features/quiz/presentation/pages/quiz_player_page.dart';

class QuizListPage extends StatelessWidget {
  final PerpuskuSubject subject;
  const QuizListPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    // Dapatkan path relatif dari path absolut, misal: "Topik A/Subjek B"
    final pathParts = subject.path.split('/');
    final relativeSubjectPath = pathParts
        .sublist(pathParts.length - 2)
        .join('/');

    return ChangeNotifierProvider(
      create: (_) => QuizProvider(relativeSubjectPath),
      child: _QuizListView(
        subject: subject,
        relativeSubjectPath: relativeSubjectPath,
      ),
    );
  }
}

class _QuizListView extends StatelessWidget {
  final PerpuskuSubject subject;
  final String relativeSubjectPath;
  const _QuizListView({
    required this.subject,
    required this.relativeSubjectPath,
  });

  void _showAddQuizDialog(BuildContext context) {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buat Kuis Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Kuis'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await provider.addQuiz(controller.text);
                  Navigator.pop(dialogContext);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuizProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Kuis: ${subject.name}')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.quizzes.isEmpty
          ? const Center(child: Text('Belum ada kuis di subjek ini.'))
          : ListView.builder(
              itemCount: provider.quizzes.length,
              itemBuilder: (context, index) {
                final quiz = provider.quizzes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    // ==> PERUBAHAN 1: Ganti ikon utama
                    leading: Icon(
                      Icons.play_circle_outline,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    title: Text(quiz.name),
                    subtitle: Text('${quiz.questions.length} pertanyaan'),
                    // ==> PERUBAHAN 2: Pindahkan logika navigasi edit ke tombol trailing
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_note),
                      tooltip: 'Edit Soal',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider(
                              create: (_) =>
                                  QuizDetailProvider(relativeSubjectPath),
                              child: QuizQuestionListPage(quizName: quiz.name),
                            ),
                          ),
                        ).then((_) {
                          // Muat ulang daftar kuis saat kembali, untuk update jumlah pertanyaan
                          provider.loadQuizzes();
                        });
                      },
                    ),
                    // ==> PERUBAHAN 3: Aksi onTap utama sekarang adalah memulai kuis
                    onTap: () {
                      if (quiz.questions.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Kuis ini belum memiliki pertanyaan. Tambahkan soal terlebih dahulu.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final quizTopic = quiz.toQuizTopic(subject.name);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizPlayerPage(
                            topic: quizTopic,
                            questions: quiz.questions,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddQuizDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Buat Kuis Baru',
      ),
    );
  }
}
