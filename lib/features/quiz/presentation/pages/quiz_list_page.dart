// lib/features/perpusku/presentation/pages/perpusku_quiz_list_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/quiz/application/quiz_provider.dart';
import 'package:provider/provider.dart';
import '../../../perpusku/domain/models/perpusku_models.dart';
import 'quiz_question_list_page.dart';
import 'package:my_aplication/features/quiz/application/quiz_detail_provider.dart';

class PerpuskuQuizListPage extends StatelessWidget {
  final PerpuskuSubject subject;
  const PerpuskuQuizListPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    // Dapatkan path relatif dari path absolut, misal: "Topik A/Subjek B"
    final pathParts = subject.path.split('/');
    final relativeSubjectPath = pathParts
        .sublist(pathParts.length - 2)
        .join('/');

    return ChangeNotifierProvider(
      create: (_) => PerpuskuQuizProvider(relativeSubjectPath),
      child: _PerpuskuQuizListView(
        subject: subject,
        relativeSubjectPath: relativeSubjectPath,
      ),
    );
  }
}

class _PerpuskuQuizListView extends StatelessWidget {
  final PerpuskuSubject subject;
  final String relativeSubjectPath;
  const _PerpuskuQuizListView({
    required this.subject,
    required this.relativeSubjectPath,
  });

  void _showAddQuizDialog(BuildContext context) {
    final provider = Provider.of<PerpuskuQuizProvider>(context, listen: false);
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
    final provider = Provider.of<PerpuskuQuizProvider>(context);

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
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(quiz.name),
                    subtitle: Text('${quiz.questions.length} pertanyaan'),
                    trailing: const Icon(Icons.edit_note),
                    onTap: () {
                      // ==> NAVIGASI KE HALAMAN DETAIL PERTANYAAN <==
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) =>
                                PerpuskuQuizDetailProvider(relativeSubjectPath),
                            child: PerpuskuQuizQuestionListPage(
                              quizName: quiz.name,
                            ),
                          ),
                        ),
                      ).then((_) {
                        // Muat ulang daftar kuis saat kembali, untuk update jumlah pertanyaan
                        provider.loadQuizzes();
                      });
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
