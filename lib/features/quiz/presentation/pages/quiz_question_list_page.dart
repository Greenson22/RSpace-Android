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
    final provider = Provider.of<QuizDetailProvider>(context);

    return Scaffold(
      // ==> GUNAKAN APPBAR KONDISIONAL
      appBar: provider.isQuestionSelectionMode
          ? _buildSelectionAppBar(context, provider, quizSet)
          : AppBar(title: Text('Edit Soal: ${quizSet.name}')),
      body: WillPopScope(
        // ==> TANGANI TOMBOL KEMBALI SAAT MODE SELEKSI
        onWillPop: () async {
          if (provider.isQuestionSelectionMode) {
            provider.clearQuestionSelection();
            return false;
          }
          return true;
        },
        child: ReorderableListView.builder(
          itemCount: quizSet.questions.length,
          itemBuilder: (context, index) {
            final question = quizSet.questions[index];
            final isSelected = provider.selectedQuestionIds.contains(
              question.id,
            );
            final correctAnswer = question.options.firstWhere(
              (o) => o.isCorrect,
              orElse: () =>
                  QuizOption(text: 'Tidak Ditemukan', isCorrect: true),
            );

            return Card(
              key: ValueKey(question.id),
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              // ==> UBAH WARNA BERDASARKAN STATUS SELEKSI
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : null,
              child: ListTile(
                // ==> TAMBAHKAN ONTAP DAN ONLONGPRESS UNTUK SELEKSI
                onTap: () {
                  if (provider.isQuestionSelectionMode) {
                    provider.toggleQuestionSelection(question.id);
                  }
                },
                onLongPress: () {
                  provider.toggleQuestionSelection(question.id);
                },
                leading: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                      )
                    : Text('${index + 1}.'),
                title: Text(question.questionText),
                subtitle: Text(
                  'Jawaban: ${correctAnswer.text}',
                  style: const TextStyle(color: Colors.green),
                ),
                // ==> SEMBUNYIKAN AKSI SAAT MODE SELEKSI
                trailing: provider.isQuestionSelectionMode
                    ? null
                    : Row(
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
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
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
      ),
      floatingActionButton: provider.isQuestionSelectionMode
          ? null // Sembunyikan FAB saat mode seleksi
          : FloatingActionButton.extended(
              onPressed: () =>
                  _showEditQuestionDialog(context, provider, quizSet, null),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Soal'),
            ),
    );
  }

  // ==> WIDGET BARU UNTUK APPBAR SELEKSI
  AppBar _buildSelectionAppBar(
    BuildContext context,
    QuizDetailProvider provider,
    QuizSet quizSet,
  ) {
    final selectedCount = provider.selectedQuestionIds.length;
    return AppBar(
      title: Text('$selectedCount Soal Dipilih'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => provider.clearQuestionSelection(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () => provider.selectAllQuestions(quizSet),
          tooltip: 'Pilih Semua',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _confirmDeleteSelected(context, provider, quizSet),
          tooltip: 'Hapus Pilihan',
        ),
      ],
    );
  }

  // ==> FUNGSI BARU UNTUK KONFIRMASI HAPUS BEBERAPA
  Future<void> _confirmDeleteSelected(
    BuildContext context,
    QuizDetailProvider provider,
    QuizSet quizSet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Soal Terpilih?'),
        content: Text(
          'Anda yakin ingin menghapus ${provider.selectedQuestionIds.length} soal yang dipilih secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteSelectedQuestions(quizSet);
    }
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
