// lib/features/perpusku/presentation/dialogs/perpusku_quiz_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/features/perpusku/application/perpusku_quiz_detail_provider.dart';
import 'package:my_aplication/features/perpusku/domain/models/quiz_model.dart';
import 'package:provider/provider.dart';

void showPerpuskuQuizSettingsDialog(BuildContext context, QuizSet quizSet) {
  final provider = Provider.of<PerpuskuQuizDetailProvider>(
    context,
    listen: false,
  );

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: PerpuskuQuizSettingsDialog(quizSet: quizSet),
    ),
  );
}

class PerpuskuQuizSettingsDialog extends StatefulWidget {
  final QuizSet quizSet;
  const PerpuskuQuizSettingsDialog({super.key, required this.quizSet});

  @override
  State<PerpuskuQuizSettingsDialog> createState() =>
      _PerpuskuQuizSettingsDialogState();
}

class _PerpuskuQuizSettingsDialogState
    extends State<PerpuskuQuizSettingsDialog> {
  late final TextEditingController _limitController;
  late final TextEditingController _delayController;
  late final TextEditingController _timerDurationController;
  late final TextEditingController _overallTimerDurationController;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.quizSet.questionLimit > 0
          ? widget.quizSet.questionLimit.toString()
          : '',
    );
    _delayController = TextEditingController(
      text: widget.quizSet.autoAdvanceDelay.toString(),
    );
    _timerDurationController = TextEditingController(
      text: widget.quizSet.timerDuration.toString(),
    );
    _overallTimerDurationController = TextEditingController(
      text: widget.quizSet.overallTimerDuration.toString(),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    _delayController.dispose();
    _timerDurationController.dispose();
    _overallTimerDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer agar UI terupdate saat provider berubah
    return Consumer<PerpuskuQuizDetailProvider>(
      builder: (context, provider, child) {
        // Ambil instance terbaru dari quizSet
        final currentQuizSet = provider.quizzes.firstWhere(
          (q) => q.name == widget.quizSet.name,
          orElse: () => widget.quizSet,
        );

        return AlertDialog(
          title: const Text('Pengaturan Sesi Kuis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  dense: true,
                  title: const Text('Acak Pertanyaan'),
                  value: currentQuizSet.shuffleQuestions,
                  onChanged: (value) => provider.updateQuizSetSettings(
                    currentQuizSet,
                    shuffleQuestions: value,
                  ),
                ),
                SwitchListTile(
                  dense: true,
                  title: const Text('Tampilkan Jawaban Benar'),
                  subtitle: const Text(
                    'Langsung perlihatkan hasil setelah menjawab.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: currentQuizSet.showCorrectAnswer,
                  onChanged: (value) => provider.updateQuizSetSettings(
                    currentQuizSet,
                    showCorrectAnswer: value,
                  ),
                ),
                SwitchListTile(
                  dense: true,
                  title: const Text('Auto Lanjut Pertanyaan'),
                  subtitle: const Text(
                    'Pindah otomatis setelah menjawab.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: currentQuizSet.autoAdvanceNextQuestion,
                  onChanged: (value) => provider.updateQuizSetSettings(
                    currentQuizSet,
                    autoAdvanceNextQuestion: value,
                  ),
                ),
                if (currentQuizSet.autoAdvanceNextQuestion)
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
                              provider.updateQuizSetSettings(
                                currentQuizSet,
                                autoAdvanceDelay: delay,
                              );
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
                  value: currentQuizSet.isTimerEnabled,
                  onChanged: (value) => provider.updateQuizSetSettings(
                    currentQuizSet,
                    isTimerEnabled: value,
                  ),
                ),
                if (currentQuizSet.isTimerEnabled)
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
                              provider.updateQuizSetSettings(
                                currentQuizSet,
                                timerDuration: duration,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                SwitchListTile(
                  dense: true,
                  title: const Text('Aktifkan Timer Kuis'),
                  subtitle: const Text(
                    'Kuis akan berakhir jika waktu habis.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: currentQuizSet.isOverallTimerEnabled,
                  onChanged: (value) => provider.updateQuizSetSettings(
                    currentQuizSet,
                    isOverallTimerEnabled: value,
                  ),
                ),
                if (currentQuizSet.isOverallTimerEnabled)
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
                              provider.updateQuizSetSettings(
                                currentQuizSet,
                                overallTimerDuration: duration,
                              );
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
                            provider.updateQuizSetSettings(
                              currentQuizSet,
                              questionLimit: limit,
                            );
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
