// lib/features/perpusku/presentation/pages/perpusku_quiz_list_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/perpusku/application/perpusku_quiz_provider.dart';
import 'package:provider/provider.dart';
import '../../domain/models/perpusku_models.dart';
// Import halaman player (akan dibuat selanjutnya)
// import 'perpusku_quiz_player_page.dart';

class PerpuskuQuizListPage extends StatelessWidget {
  final PerpuskuSubject subject;
  const PerpuskuQuizListPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    // Path relatif dari Topic/Subject
    final relativeSubjectPath =
        '${subject.path.split('/').sublist(subject.path.split('/').length - 2).join('/')}';

    return ChangeNotifierProvider(
      create: (_) => PerpuskuQuizProvider(relativeSubjectPath),
      child: _PerpuskuQuizListView(subject: subject),
    );
  }
}

class _PerpuskuQuizListView extends StatelessWidget {
  final PerpuskuSubject subject;
  const _PerpuskuQuizListView({required this.subject});

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
                    trailing: const Icon(Icons.play_circle_outline),
                    onTap: () {
                      // TODO: Navigasi ke halaman player kuis v2
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Player belum diimplementasikan.'),
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
