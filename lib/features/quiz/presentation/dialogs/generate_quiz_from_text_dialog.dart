// lib/features/quiz/presentation/dialogs/generate_quiz_from_text_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';

// Fungsi untuk menampilkan dialog
void showGenerateQuizFromTextDialog(BuildContext context) {
  final provider = Provider.of<QuizDetailProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const GenerateQuizFromTextDialog(),
    ),
  );
}

class GenerateQuizFromTextDialog extends StatefulWidget {
  const GenerateQuizFromTextDialog({super.key});

  @override
  State<GenerateQuizFromTextDialog> createState() =>
      _GenerateQuizFromTextDialogState();
}

class _GenerateQuizFromTextDialogState
    extends State<GenerateQuizFromTextDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quizSetNameController = TextEditingController();
  final TextEditingController _topicTextController = TextEditingController();
  final TextEditingController _questionCountController = TextEditingController(
    text: '10',
  );
  QuizDifficulty _selectedDifficulty = QuizDifficulty.medium;

  @override
  void dispose() {
    _quizSetNameController.dispose();
    _topicTextController.dispose();
    _questionCountController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<QuizDetailProvider>(context, listen: false);
    final quizSetName = _quizSetNameController.text.trim();
    final customTopic = _topicTextController.text.trim();
    final questionCount = int.tryParse(_questionCountController.text) ?? 10;

    Navigator.of(context).pop();

    try {
      await provider.addQuizSetFromText(
        quizSetName: quizSetName,
        customTopic: customTopic,
        questionCount: questionCount,
        difficulty: _selectedDifficulty,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kuis baru dari teks berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buat Kuis dari Teks'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tulis atau tempel materi di bawah untuk dibuatkan soal kuis secara otomatis oleh AI.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _quizSetNameController,
                decoration: const InputDecoration(labelText: 'Nama Set Kuis'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama set kuis tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _topicTextController,
                decoration: const InputDecoration(
                  labelText: 'Materi Kuis',
                  hintText: 'Tulis atau tempel materi di sini...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Materi tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
        ElevatedButton(
          onPressed: _handleGenerate,
          child: const Text('Buat Pertanyaan'),
        ),
      ],
    );
  }
}
