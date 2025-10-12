// lib/features/perpusku/presentation/pages/perpusku_quiz_question_list_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:my_aplication/features/perpusku/application/perpusku_quiz_detail_provider.dart';
import '../dialogs/import_perpusku_quiz_from_json_dialog.dart';
// ==> IMPORT DIALOG BARU <==
import '../dialogs/generate_perpusku_quiz_prompt_dialog.dart';

class PerpuskuQuizQuestionListPage extends StatelessWidget {
  final String quizName;

  const PerpuskuQuizQuestionListPage({super.key, required this.quizName});

  void _showAddOptions(BuildContext context, String quizName) {
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Tambah Pertanyaan ke "$quizName"'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
              showImportPerpuskuQuizFromJsonDialog(context, quizName);
            },
            child: const ListTile(
              leading: Icon(Icons.file_upload_outlined),
              title: Text('Impor dari JSON'),
              subtitle: Text('Tempelkan konten JSON dari AI.'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              // TODO: Implement Add Manual Question Dialog
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur tambah manual belum tersedia.'),
                ),
              );
            },
            child: const ListTile(
              leading: Icon(Icons.edit_note),
              title: Text('Tambah Manual'),
              subtitle: Text('Isi pertanyaan dan jawaban satu per satu.'),
            ),
          ),
          // ==> TAMBAHKAN OPSI BARU DI SINI <==
          const Divider(),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
              showGeneratePerpuskuQuizPromptDialog(context);
            },
            child: const ListTile(
              leading: Icon(Icons.copy_all_outlined),
              title: Text('Buat Prompt dari Subject R-Space'),
              subtitle: Text('Generate prompt untuk digunakan di Gemini.'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider diharapkan sudah tersedia dari navigator (halaman sebelumnya)
    return Consumer<PerpuskuQuizDetailProvider>(
      builder: (context, provider, child) {
        QuizSet? currentQuizSet;
        if (!provider.isLoading) {
          try {
            currentQuizSet = provider.quizzes.firstWhere(
              (q) => q.name == quizName,
            );
          } catch (e) {
            // Kuis mungkin telah dihapus, jadi currentQuizSet akan tetap null
          }
        }

        return Scaffold(
          appBar: AppBar(title: Text('Edit Soal: $quizName')),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : currentQuizSet == null
              ? const Center(
                  child: Text(
                    'Kuis tidak ditemukan. Mungkin telah dihapus atau diganti nama.',
                  ),
                )
              : currentQuizSet.questions.isEmpty
              ? const Center(
                  child: Text('Belum ada pertanyaan di dalam kuis ini.'),
                )
              : ListView.builder(
                  itemCount: currentQuizSet.questions.length,
                  itemBuilder: (context, index) {
                    final question = currentQuizSet!.questions[index];
                    final correctAnswer = question.options.firstWhere(
                      (o) => o.isCorrect,
                      orElse: () =>
                          QuizOption(text: 'Tidak Ditemukan', isCorrect: true),
                    );
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: Text('${index + 1}.'),
                        title: Text(question.questionText),
                        subtitle: Text(
                          'Jawaban: ${correctAnswer.text}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOptions(context, quizName),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Soal'),
          ),
        );
      },
    );
  }
}
