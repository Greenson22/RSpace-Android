// lib/features/quiz/presentation/pages/quiz_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import '../dialogs/add_questions_dialog.dart';
import '../dialogs/add_quiz_dialog.dart';
// ==> IMPORT DIALOG PENGATURAN BARU
import '../dialogs/quiz_settings_dialog.dart';

// ==> KEMBALIKAN MENJADI STATELESSWIDGET
class QuizDetailPage extends StatelessWidget {
  const QuizDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuizDetailProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Kuis: ${provider.topic.name}'),
        actions: [
          // ==> TOMBOL PENGATURAN BARU
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showQuizSettingsDialog(context),
            tooltip: 'Pengaturan Sesi Kuis',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddQuizDialog(context),
            tooltip: 'Buat Set Kuis Baru (AI)',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ==> PANEL PENGATURAN DIHAPUS DARI SINI
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
                onSelected: (value) {
                  if (value == 'add') {
                    showAddQuestionsDialog(context, quizSet);
                  } else if (value == 'delete') {
                    // TODO: Tambahkan konfirmasi dialog
                    provider.deleteQuizSet(quizSet.name);
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
