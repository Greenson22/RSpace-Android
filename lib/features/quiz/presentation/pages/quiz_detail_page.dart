// lib/features/quiz/presentation/pages/quiz_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import '../dialogs/add_questions_dialog.dart';
import '../dialogs/add_quiz_dialog.dart';

class QuizDetailPage extends StatelessWidget {
  const QuizDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuizDetailProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Kuis: ${provider.topic.name}'),
        // ==> PERUBAHAN DI SINI: Tombol ditambahkan di actions <==
        actions: [
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
                _buildSettingsPanel(context, provider),
                const Divider(height: 1),
                Expanded(
                  child: provider.quizSets.isEmpty
                      ? const Center(
                          child: Text('Belum ada set kuis di dalam topik ini.'),
                        )
                      : _buildQuizSetList(context, provider),
                ),
              ],
            ),
      // ==> PERUBAHAN DI SINI: FloatingActionButton dihapus <==
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
    // ==> CONTROLLER BARU UNTUK DELAY
    final delayController = TextEditingController(
      text: provider.topic.autoAdvanceDelay.toString(),
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
          SwitchListTile(
            title: const Text('Tampilkan Jawaban Benar'),
            subtitle: const Text(
              'Langsung perlihatkan hasil setelah menjawab.',
            ),
            value: provider.topic.showCorrectAnswer,
            onChanged: (value) {
              provider.updateShowCorrectAnswer(value);
            },
          ),
          // ==> TAMBAHKAN PENGATURAN BARU DI SINI
          SwitchListTile(
            title: const Text('Auto Lanjut Pertanyaan'),
            subtitle: const Text('Pindah otomatis setelah menjawab.'),
            value: provider.topic.autoAdvanceNextQuestion,
            onChanged: (value) {
              provider.updateAutoAdvance(value);
            },
          ),
          // Tampilkan input delay hanya jika auto-lanjut aktif
          if (provider.topic.autoAdvanceNextQuestion)
            ListTile(
              title: const Text('Tunda Auto Lanjut'),
              trailing: SizedBox(
                width: 80,
                child: TextFormField(
                  controller: delayController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'detik',
                  ),
                  onFieldSubmitted: (value) {
                    final delay = int.tryParse(value) ?? 2;
                    provider.updateAutoAdvanceDelay(delay);
                  },
                ),
              ),
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

  // ==> UI LIST DIPERBARUI SECARA SIGNIFIKAN <==
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
