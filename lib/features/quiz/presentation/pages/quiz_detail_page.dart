// lib/features/quiz/presentation/pages/quiz_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import '../dialogs/add_quiz_dialog.dart';
import '../dialogs/quiz_settings_dialog.dart';
import '../dialogs/generate_quiz_from_text_dialog.dart';
import '../dialogs/generate_prompt_from_subject_dialog.dart';
import '../dialogs/import_quiz_from_json_dialog.dart';
import '../../domain/models/quiz_model.dart';

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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOptions(context, null),
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

  void _showAddOptions(BuildContext context, QuizSet? quizSet) {
    final isAddingQuestions = quizSet != null;
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(
          isAddingQuestions
              ? 'Tambah Pertanyaan dari...'
              : 'Pilih Metode Pembuatan Kuis',
        ),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
              showAddQuizDialog(context, existingQuizSet: quizSet);
            },
            child: ListTile(
              leading: const Icon(Icons.topic_outlined),
              title: const Text('Dari Subject'),
              subtitle: Text(
                isAddingQuestions
                    ? 'Generate pertanyaan tambahan dari subject.'
                    : 'AI akan langsung membuat soal.',
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
              // TODO: Implement this dialog to handle both cases
            },
            child: ListTile(
              leading: const Icon(Icons.text_fields_outlined),
              title: const Text('Dari Teks Manual'),
              subtitle: Text(
                isAddingQuestions
                    ? 'Generate pertanyaan dari teks manual.'
                    : 'AI akan membuat soal dari teks Anda.',
              ),
            ),
          ),
          // ==> PERUBAHAN DI SINI: Tampilkan Impor JSON di kedua mode
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(dialogContext);
              showImportQuizFromJsonDialog(context, existingQuizSet: quizSet);
            },
            child: ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Impor Kuis dari JSON'),
              subtitle: Text(
                isAddingQuestions
                    ? 'Tambahkan pertanyaan dari format JSON.'
                    : 'Masukkan hasil JSON dari Gemini.',
              ),
            ),
          ),
          if (!isAddingQuestions)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                showGeneratePromptFromSubjectDialog(context);
              },
              child: const ListTile(
                leading: Icon(Icons.copy_all_outlined),
                title: Text('Buat Prompt dari Subject'),
                subtitle: Text('Salin prompt untuk digunakan di Gemini.'),
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
                    _showAddOptions(context, quizSet);
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
                    child: Text('Tambah Pertanyaan'),
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
