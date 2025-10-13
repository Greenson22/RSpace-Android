// lib/features/quiz/presentation/dialogs/generate_quiz_from_html_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:my_aplication/features/quiz/application/quiz_detail_provider.dart';
import 'package:my_aplication/features/content_management/application/discussion_provider.dart';

void showGenerateQuizFromHtmlDialog(
  BuildContext context, {
  required String relativeHtmlPath,
  required String discussionTitle,
  String? targetQuizName, // ==> PARAMETER BARU
}) {
  final discussionProvider = Provider.of<DiscussionProvider>(
    context,
    listen: false,
  );
  final relativeSubjectPath = discussionProvider.sourceSubjectLinkedPath;

  if (relativeSubjectPath == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subject tidak tertaut ke Perpusku.')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => QuizDetailProvider(relativeSubjectPath),
      child: GenerateQuizFromHtmlDialog(
        relativeHtmlPath: relativeHtmlPath,
        discussionTitle: discussionTitle,
        targetQuizName: targetQuizName, // ==> KIRIM PARAMETER
      ),
    ),
  );
}

enum _DialogState { selection, loading }

class GenerateQuizFromHtmlDialog extends StatefulWidget {
  final String relativeHtmlPath;
  final String discussionTitle;
  final String? targetQuizName; // ==> PROPERTI BARU

  const GenerateQuizFromHtmlDialog({
    super.key,
    required this.relativeHtmlPath,
    required this.discussionTitle,
    this.targetQuizName,
  });

  @override
  State<GenerateQuizFromHtmlDialog> createState() =>
      _GenerateQuizFromHtmlDialogState();
}

class _GenerateQuizFromHtmlDialogState
    extends State<GenerateQuizFromHtmlDialog> {
  final _formKey = GlobalKey<FormState>();
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

  Future<String?> _showQuizPicker(BuildContext context, List<QuizSet> quizzes) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Pilih Kuis Tujuan'),
        children: quizzes.isEmpty
            ? [const Center(child: Text("Tidak ada kuis di subjek ini."))]
            : quizzes
                  .map(
                    (quiz) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(dialogContext, quiz.name),
                      child: Text(quiz.name),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  Future<void> _handleAction(bool directImport) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _currentState = _DialogState.loading);

    final provider = Provider.of<QuizDetailProvider>(context, listen: false);
    final questionCount = int.tryParse(_questionCountController.text) ?? 10;

    try {
      if (directImport) {
        // ==> LOGIKA DIPERBARUI <==
        // Jika sudah ada target, gunakan. Jika tidak, tampilkan picker.
        final targetQuizName =
            widget.targetQuizName ??
            await _showQuizPicker(context, provider.quizzes);

        if (targetQuizName != null && mounted) {
          await provider.generateAndAddQuestionsFromHtmlDiscussion(
            quizSetName: targetQuizName,
            relativeHtmlPath: widget.relativeHtmlPath,
            discussionTitle: widget.discussionTitle,
            questionCount: questionCount,
            difficulty: _selectedDifficulty,
          );
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$questionCount pertanyaan ditambahkan ke "$targetQuizName".',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _currentState = _DialogState.selection);
        }
      } else {
        final prompt = await provider.generatePromptFromHtmlDiscussion(
          relativeHtmlPath: widget.relativeHtmlPath,
          discussionTitle: widget.discussionTitle,
          questionCount: questionCount,
          difficulty: _selectedDifficulty,
        );
        if (mounted) {
          await Clipboard.setData(ClipboardData(text: prompt));
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt disalin ke clipboard!')),
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
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Membuat pertanyaan..."),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Buat Kuis dari File HTML'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sumber: "${widget.discussionTitle}"'),
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
