// lib/features/quiz/presentation/dialogs/generate_quiz_from_subject_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:my_aplication/features/settings/domain/models/gemini_settings_model.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../../application/quiz_detail_provider.dart';

// Dialog untuk menampilkan dan menyalin prompt (tidak berubah)
class _PromptDisplayDialog extends StatelessWidget {
  final String prompt;
  const _PromptDisplayDialog({required this.prompt});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Salin Prompt Ini'),
      content: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(prompt),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Salin'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: prompt));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prompt disalin ke clipboard!')),
            );
          },
        ),
      ],
    );
  }
}

// ==> FUNGSI UTAMA DIPERBARUI: Menerima subjectPath dan subjectName
void showGenerateQuizFromSubjectDialog(
  BuildContext context, {
  required String quizName,
  required String subjectPath,
  required String subjectName,
}) {
  final provider = Provider.of<QuizDetailProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: GenerateQuizFromSubjectDialog(
        targetQuizName: quizName,
        relativeSubjectPath: subjectPath,
        subjectName: subjectName,
      ),
    ),
  );
}

enum _DialogState { selection, loading }

class GenerateQuizFromSubjectDialog extends StatefulWidget {
  final String targetQuizName;
  final String relativeSubjectPath;
  final String subjectName;

  const GenerateQuizFromSubjectDialog({
    super.key,
    required this.targetQuizName,
    required this.relativeSubjectPath,
    required this.subjectName,
  });

  @override
  State<GenerateQuizFromSubjectDialog> createState() =>
      _GenerateQuizFromSubjectDialogState();
}

class _GenerateQuizFromSubjectDialogState
    extends State<GenerateQuizFromSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final PathService _pathService = PathService();

  final TextEditingController _questionCountController = TextEditingController(
    text: '10',
  );
  QuizDifficulty _selectedDifficulty = QuizDifficulty.medium;
  _DialogState _currentState = _DialogState.selection;

  @override
  void dispose() {
    _questionCountController.dispose();
    super.dispose();
  }

  Future<void> _handleAction(bool directImport) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _currentState = _DialogState.loading);

    final provider = Provider.of<QuizDetailProvider>(context, listen: false);

    // ==> LOGIKA PATH DIPERBARUI: Langsung gunakan path yang diberikan
    final topicsPath = await _pathService.topicsPath;
    final subjectJsonPath = path.join(
      topicsPath,
      widget.relativeSubjectPath.replaceAll('/', path.separator) + '.json',
    );
    final questionCount = int.tryParse(_questionCountController.text) ?? 10;

    try {
      if (directImport) {
        await provider.generateAndAddQuestionsFromRspaceSubject(
          quizSetName: widget.targetQuizName,
          subjectJsonPath: subjectJsonPath,
          questionCount: questionCount,
          difficulty: _selectedDifficulty,
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$questionCount pertanyaan ditambahkan ke "${widget.targetQuizName}".',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final prompt = await provider.generatePromptFromRspaceSubject(
          subjectJsonPath: subjectJsonPath,
          questionCount: questionCount,
          difficulty: _selectedDifficulty,
        );
        if (mounted) {
          Navigator.of(context).pop();
          showDialog(
            context: context,
            builder: (context) => _PromptDisplayDialog(prompt: prompt),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _currentState = _DialogState.selection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentState == _DialogState.loading) {
      final provider = Provider.of<QuizDetailProvider>(context, listen: false);
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FutureBuilder<GeminiSettings>(
            future: provider.geminiSettings,
            builder: (context, snapshot) {
              String modelName = '...';
              if (snapshot.hasData) {
                final settings = snapshot.data!;
                final model = settings.models.firstWhere(
                  (m) => m.modelId == settings.quizModelId,
                  orElse: () => settings.models.first,
                );
                modelName = model.name;
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text("Membuat pertanyaan dengan model:\n$modelName"),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Buat Kuis dari Subject R-Space'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==> TAMPILKAN SUMBER MATERI, HAPUS DROPDOWN <==
              Text(
                'Sumber Materi:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                widget.subjectName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<QuizDifficulty>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: 'Tingkat Kesulitan',
                ),
                items: QuizDifficulty.values.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(difficulty.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDifficulty = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _questionCountController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Pertanyaan',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah tidak boleh kosong.';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return 'Masukkan angka yang valid.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        OutlinedButton(
          onPressed: () => _handleAction(false),
          child: const Text('Buat Prompt Saja'),
        ),
        ElevatedButton(
          onPressed: () => _handleAction(true),
          child: const Text('Buat & Impor'),
        ),
      ],
    );
  }
}
