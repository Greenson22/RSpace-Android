// lib/features/quiz/presentation/dialogs/quiz_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';

void showQuizSettingsDialog(BuildContext context) {
  final provider = Provider.of<QuizDetailProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const QuizSettingsDialog(),
    ),
  );
}

class QuizSettingsDialog extends StatefulWidget {
  const QuizSettingsDialog({super.key});

  @override
  State<QuizSettingsDialog> createState() => _QuizSettingsDialogState();
}

class _QuizSettingsDialogState extends State<QuizSettingsDialog> {
  late final TextEditingController _limitController;
  late final TextEditingController _delayController;
  late final TextEditingController _timerDurationController;
  // ==> CONTROLLER BARU UNTUK TIMER KESELURUHAN
  late final TextEditingController _overallTimerDurationController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<QuizDetailProvider>(context, listen: false);
    _limitController = TextEditingController(
      text: provider.topic.questionLimit > 0
          ? provider.topic.questionLimit.toString()
          : '',
    );
    _delayController = TextEditingController(
      text: provider.topic.autoAdvanceDelay.toString(),
    );
    _timerDurationController = TextEditingController(
      text: provider.topic.timerDuration.toString(),
    );
    // ==> INISIALISASI CONTROLLER BARU
    _overallTimerDurationController = TextEditingController(
      text: provider.topic.overallTimerDuration.toString(),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    _delayController.dispose();
    _timerDurationController.dispose();
    _overallTimerDurationController.dispose(); // ==> JANGAN LUPA DISPOSE
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizDetailProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: const Text('Pengaturan Sesi Kuis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  dense: true,
                  title: const Text('Acak Pertanyaan'),
                  value: provider.topic.shuffleQuestions,
                  onChanged: (value) => provider.updateShuffle(value),
                ),
                SwitchListTile(
                  dense: true,
                  title: const Text('Tampilkan Jawaban Benar'),
                  subtitle: const Text(
                    'Langsung perlihatkan hasil setelah menjawab.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: provider.topic.showCorrectAnswer,
                  onChanged: (value) => provider.updateShowCorrectAnswer(value),
                ),
                SwitchListTile(
                  dense: true,
                  title: const Text('Auto Lanjut Pertanyaan'),
                  subtitle: const Text(
                    'Pindah otomatis setelah menjawab.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: provider.topic.autoAdvanceNextQuestion,
                  onChanged: (value) => provider.updateAutoAdvance(value),
                ),
                if (provider.topic.autoAdvanceNextQuestion)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Tunda Auto Lanjut')),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _delayController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixText: 'dtk',
                            ),
                            onFieldSubmitted: (value) {
                              final delay = int.tryParse(value) ?? 2;
                              provider.updateAutoAdvanceDelay(delay);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                SwitchListTile(
                  dense: true,
                  title: const Text('Aktifkan Timer per Pertanyaan'),
                  value: provider.topic.isTimerEnabled,
                  onChanged: (value) => provider.updateTimerEnabled(value),
                ),
                if (provider.topic.isTimerEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Durasi Timer')),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _timerDurationController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixText: 'dtk',
                            ),
                            onFieldSubmitted: (value) {
                              final duration = int.tryParse(value) ?? 30;
                              provider.updateTimerDuration(duration);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                // ==> KONTROL BARU UNTUK TIMER KESELURUHAN
                const Divider(),
                SwitchListTile(
                  dense: true,
                  title: const Text('Aktifkan Timer Kuis'),
                  subtitle: const Text(
                    'Kuis akan berakhir jika waktu habis.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: provider.topic.isOverallTimerEnabled,
                  onChanged: (value) =>
                      provider.updateOverallTimerEnabled(value),
                ),
                if (provider.topic.isOverallTimerEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Durasi Total Kuis')),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _overallTimerDurationController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixText: 'mnt',
                            ),
                            onFieldSubmitted: (value) {
                              final duration = int.tryParse(value) ?? 10;
                              provider.updateOverallTimerDuration(duration);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Batas Pertanyaan\n(Isi 0 untuk tanpa batas)',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _limitController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
