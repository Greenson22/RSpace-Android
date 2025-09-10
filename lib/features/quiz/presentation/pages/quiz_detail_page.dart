// lib/features/quiz/presentation/pages/quiz_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import '../dialogs/add_quiz_dialog.dart';

class QuizDetailPage extends StatelessWidget {
  const QuizDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuizDetailProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Kelola Kuis: ${provider.topic.name}')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSettingsPanel(context, provider),
                const Divider(height: 1),
                Expanded(
                  child: provider.quizSets.isEmpty
                      ? const Center(
                          child: Text('Belum ada set kuis di dalam topik ini.'),
                        )
                      // ==> DIPERBAIKI: Kirim 'context' ke dalam fungsi
                      : _buildQuizSetList(context, provider),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddQuizDialog(context),
        label: const Text('Buat Set Kuis Baru (AI)'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSettingsPanel(
    BuildContext context,
    QuizDetailProvider provider,
  ) {
    final limitController = TextEditingController(
      text: provider.topic.questionLimit > 0
          ? provider.topic.questionLimit.toString()
          : '',
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan Sesi Kuis',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Acak Pertanyaan'),
            value: provider.topic.shuffleQuestions,
            onChanged: (value) {
              provider.updateShuffle(value);
            },
          ),
          ListTile(
            title: const Text('Batas Pertanyaan'),
            subtitle: const Text('Isi 0 atau kosongkan untuk tanpa batas'),
            trailing: SizedBox(
              width: 80,
              child: TextFormField(
                controller: limitController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onFieldSubmitted: (value) {
                  final limit = int.tryParse(value) ?? 0;
                  provider.updateQuestionLimit(limit);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==> DIPERBAIKI: Tambahkan parameter BuildContext
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
          return CheckboxListTile(
            title: Text(quizSet.name.replaceAll('_', ' ')),
            subtitle: Text('${quizSet.questions.length} pertanyaan'),
            value: isIncluded,
            onChanged: (bool? value) {
              if (value != null) {
                provider.toggleQuizSetInclusion(quizSet.name, value);
              }
            },
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                // Tambahkan konfirmasi sebelum menghapus
                provider.deleteQuizSet(quizSet.name);
              },
            ),
          );
        }).toList(),
      ],
    );
  }
}
