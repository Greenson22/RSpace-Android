// lib/features/perpusku/presentation/dialogs/generate_prompt_from_html_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:my_aplication/features/quiz/application/quiz_detail_provider.dart';
import 'package:my_aplication/features/content_management/application/discussion_provider.dart';

void showGeneratePromptFromHtmlDialog(
  BuildContext context, {
  required String relativeHtmlPath,
  required String discussionTitle,
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
      create: (_) => PerpuskuQuizDetailProvider(relativeSubjectPath),
      child: GeneratePromptFromHtmlDialog(
        relativeHtmlPath: relativeHtmlPath,
        discussionTitle: discussionTitle,
      ),
    ),
  );
}

enum _PromptDialogState { selection, prompt, loading }

class GeneratePromptFromHtmlDialog extends StatefulWidget {
  // ==> PERBAIKAN: Terima path dan judul, bukan objek Discussion <==
  final String relativeHtmlPath;
  final String discussionTitle;
  const GeneratePromptFromHtmlDialog({
    super.key,
    required this.relativeHtmlPath,
    required this.discussionTitle,
  });

  @override
  State<GeneratePromptFromHtmlDialog> createState() =>
      _GeneratePromptFromHtmlDialogState();
}

class _GeneratePromptFromHtmlDialogState
    extends State<GeneratePromptFromHtmlDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionCountController = TextEditingController(
    text: '10',
  );
  QuizDifficulty _selectedDifficulty = QuizDifficulty.medium;

  _PromptDialogState _currentState = _PromptDialogState.selection;
  String _generatedPrompt = '';

  @override
  void dispose() {
    _questionCountController.dispose();
    super.dispose();
  }

  Future<void> _handleGeneratePrompt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _currentState = _PromptDialogState.loading);

    final provider = Provider.of<PerpuskuQuizDetailProvider>(
      context,
      listen: false,
    );
    final questionCount = int.tryParse(_questionCountController.text) ?? 10;

    try {
      // ==> PERBAIKAN: Panggil metode yang sudah diperbarui <==
      final prompt = await provider.generatePromptFromHtmlDiscussion(
        relativeHtmlPath: widget.relativeHtmlPath,
        discussionTitle: widget.discussionTitle,
        questionCount: questionCount,
        difficulty: _selectedDifficulty,
      );
      if (mounted) {
        setState(() {
          _generatedPrompt = prompt;
          _currentState = _PromptDialogState.prompt;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _currentState = _PromptDialogState.selection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _currentState == _PromptDialogState.selection
            ? 'Buat Prompt dari File HTML'
            : 'Salin Prompt Ini',
      ),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    switch (_currentState) {
      case _PromptDialogState.selection:
        return _buildSelectionForm();
      case _PromptDialogState.loading:
        return const Center(child: CircularProgressIndicator());
      case _PromptDialogState.prompt:
        return _buildPromptDisplay();
    }
  }

  List<Widget> _buildActions() {
    switch (_currentState) {
      case _PromptDialogState.selection:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _handleGeneratePrompt,
            child: const Text('Buat Prompt'),
          ),
        ];
      case _PromptDialogState.loading:
        return [];
      case _PromptDialogState.prompt:
        return [
          TextButton(
            onPressed: () =>
                setState(() => _currentState = _PromptDialogState.selection),
            child: const Text('Kembali'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Salin'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _generatedPrompt));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prompt disalin ke clipboard!')),
              );
            },
          ),
        ];
    }
  }

  Widget _buildSelectionForm() {
    return Form(
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
              decoration: const InputDecoration(labelText: 'Tingkat Kesulitan'),
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
              decoration: const InputDecoration(labelText: 'Jumlah Pertanyaan'),
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
    );
  }

  Widget _buildPromptDisplay() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(_generatedPrompt),
      ),
    );
  }
}
