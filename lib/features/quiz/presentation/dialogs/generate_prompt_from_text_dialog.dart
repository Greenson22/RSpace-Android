// lib/features/quiz/presentation/dialogs/generate_prompt_from_text_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';

// Fungsi untuk menampilkan dialog
void showGeneratePromptFromTextDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const GeneratePromptFromTextDialog(),
  );
}

// Enum untuk state dialog
enum _PromptDialogState { selection, prompt }

class GeneratePromptFromTextDialog extends StatefulWidget {
  const GeneratePromptFromTextDialog({super.key});

  @override
  State<GeneratePromptFromTextDialog> createState() =>
      _GeneratePromptFromTextDialogState();
}

class _GeneratePromptFromTextDialogState
    extends State<GeneratePromptFromTextDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionCountController = TextEditingController(
    text: '10',
  );
  final TextEditingController _textMaterialController = TextEditingController();
  QuizDifficulty _selectedDifficulty = QuizDifficulty.medium;

  _PromptDialogState _currentState = _PromptDialogState.selection;
  String _generatedPrompt = '';

  @override
  void dispose() {
    _questionCountController.dispose();
    _textMaterialController.dispose();
    super.dispose();
  }

  void _handleGeneratePrompt() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final questionCount = int.tryParse(_questionCountController.text) ?? 10;
    final material = _textMaterialController.text;

    final prompt =
        '''
    Anda adalah AI pembuat kuis. Berdasarkan materi berikut:
    ---
    $material
    ---
    
    Buatkan $questionCount pertanyaan kuis pilihan ganda yang relevan dengan tingkat kesulitan: ${_selectedDifficulty.displayName}.
    Untuk tingkat kesulitan "HOTS", buatlah pertanyaan yang membutuhkan analisis atau penerapan konsep, bukan hanya ingatan.
    
    Aturan Jawaban:
    1.  HANYA kembalikan dalam format array JSON yang valid.
    2.  Setiap objek dalam array mewakili satu pertanyaan dan HARUS memiliki kunci: "questionText", "options", dan "correctAnswerIndex".
    3.  "questionText" harus berupa string.
    4.  "options" harus berupa array berisi 4 string pilihan jawaban.
    5.  "correctAnswerIndex" harus berupa integer (0-3) yang menunjuk ke jawaban yang benar.
    6.  Jangan sertakan penjelasan atau teks lain di luar array JSON.

    Contoh Jawaban:
    [
      {
        "questionText": "Apa itu widget dalam Flutter?",
        "options": ["Blok bangunan UI", "Tipe variabel", "Fungsi database", "Permintaan jaringan"],
        "correctAnswerIndex": 0
      }
    ]
    ''';

    setState(() {
      _generatedPrompt = prompt;
      _currentState = _PromptDialogState.prompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _currentState == _PromptDialogState.selection
            ? 'Buat Prompt dari Teks'
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
            TextFormField(
              controller: _textMaterialController,
              decoration: const InputDecoration(
                labelText: 'Materi Kuis',
                hintText: 'Ketik atau tempel materi di sini...',
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
