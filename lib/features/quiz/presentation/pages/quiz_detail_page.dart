// lib/features/quiz/presentation/pages/quiz_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import '../dialogs/add_questions_dialog.dart';
import '../dialogs/add_quiz_dialog.dart';
import '../dialogs/quiz_settings_dialog.dart';
// ==> IMPORT DIALOG BARU
import '../dialogs/generate_quiz_from_text_dialog.dart';

class QuizDetailPage extends StatelessWidget {
  const QuizDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuizDetailProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Kuis: ${provider.topic.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showQuizSettingsDialog(context),
            tooltip: 'Pengaturan Sesi Kuis',
          ),
          // ==> PERBARUI TOMBOL TAMBAH UNTUK MEMBERI PILIHAN <==
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOptions(context),
            tooltip: 'Buat Set Kuis Baru',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: provider.quizSets.isEmpty
                      ? const Center(
                          child: Text('Belum ada set kuis di dalam topik ini.'),
                        )
                      : _buildQuizSetList(context, provider),
                ),
              ],
            ),
    );
  }

  // ==> FUNGSI BARU UNTUK MENAMPILKAN DIALOG PILIHAN <==
  void _showAddOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Pilih Sumber Materi'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
              showAddQuizDialog(context);
            },
            child: const ListTile(
              leading: Icon(Icons.topic_outlined),
              title: Text('Dari Subject yang Ada'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
              showGenerateQuizFromTextDialog(context);
            },
            child: const ListTile(
              leading: Icon(Icons.text_fields_outlined),
              title: Text('Dari Teks Manual'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizSetList(BuildContext context, QuizDetailProvider provider) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Pilih Set Kuis untuk Dimainkan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...provider.quizSets.map((quizSet) {
          final isIncluded = provider.topic.includedQuizSets.contains(
            quizSet.name,
          );
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Checkbox(
                value: isIncluded,
                onChanged: (bool? value) {
                  if (value != null) {
                    provider.toggleQuizSetInclusion(quizSet.name, value);
                  }
                },
              ),
              title: Text(quizSet.name.replaceAll('_', ' ')),
              subtitle: Text('${quizSet.questions.length} pertanyaan'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'add') {
                    showAddQuestionsDialog(context, quizSet);
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Konfirmasi Hapus'),
                        content: Text(
                          'Anda yakin ingin menghapus set kuis "${quizSet.name}" secara permanen?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      provider.deleteQuizSet(quizSet.name);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add',
                    child: Text('Tambah Pertanyaan (AI)'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Hapus Set Kuis',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
