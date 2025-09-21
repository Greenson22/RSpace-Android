// lib/features/quiz/presentation/dialogs/edit_question_dialog.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/quiz/application/quiz_detail_provider.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:provider/provider.dart';

class EditQuestionDialog extends StatefulWidget {
  final QuizSet quizSet;
  final QuizQuestion? question; // Null jika menambah pertanyaan baru

  const EditQuestionDialog({super.key, required this.quizSet, this.question});

  @override
  State<EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<EditQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  int _correctAnswerIndex = 0;
  bool get _isEditing => widget.question != null;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.question?.questionText ?? '',
    );
    _optionControllers = List.generate(4, (index) {
      if (widget.question != null && index < widget.question!.options.length) {
        return TextEditingController(
          text: widget.question!.options[index].text,
        );
      }
      return TextEditingController();
    });

    if (_isEditing) {
      _correctAnswerIndex = widget.question!.options.indexWhere(
        (o) => o.isCorrect,
      );
      if (_correctAnswerIndex == -1) _correctAnswerIndex = 0;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<QuizDetailProvider>(context, listen: false);
      final questionText = _questionController.text.trim();
      final options = List.generate(4, (index) {
        return QuizOption(
          text: _optionControllers[index].text.trim(),
          isCorrect: index == _correctAnswerIndex,
        );
      });

      if (_isEditing) {
        provider.updateQuestion(
          widget.quizSet,
          widget.question!,
          questionText,
          options,
        );
      } else {
        provider.addQuestion(widget.quizSet, questionText, options);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Pertanyaan' : 'Tambah Pertanyaan Baru'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Teks Pertanyaan'),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              const Text('Pilihan Jawaban (tandai yang benar):'),
              ...List.generate(4, (index) {
                return Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _correctAnswerIndex,
                      onChanged: (value) =>
                          setState(() => _correctAnswerIndex = value!),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Pilihan ${index + 1}',
                        ),
                        validator: (value) =>
                            value!.trim().isEmpty ? 'Tidak boleh kosong' : null,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _handleSave, child: const Text('Simpan')),
      ],
    );
  }
}
