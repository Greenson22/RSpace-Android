// lib/features/quiz/presentation/dialogs/add_empty_quiz_set_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';

// Fungsi untuk menampilkan dialog
void showAddEmptyQuizSetDialog(BuildContext context) {
  final provider = Provider.of<QuizDetailProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const AddEmptyQuizSetDialog(),
    ),
  );
}

class AddEmptyQuizSetDialog extends StatefulWidget {
  const AddEmptyQuizSetDialog({super.key});

  @override
  State<AddEmptyQuizSetDialog> createState() => _AddEmptyQuizSetDialogState();
}

class _AddEmptyQuizSetDialogState extends State<AddEmptyQuizSetDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quizSetNameController = TextEditingController();

  @override
  void dispose() {
    _quizSetNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<QuizDetailProvider>(context, listen: false);
    final quizSetName = _quizSetNameController.text.trim();

    Navigator.of(context).pop();

    try {
      await provider.addEmptyQuizSet(quizSetName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Set kuis "$quizSetName" berhasil dibuat.'),
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
      title: const Text('Buat Set Kuis Kosong'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _quizSetNameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Set Kuis',
            hintText: 'Contoh: Latihan Bab 1',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama set kuis tidak boleh kosong.';
            }
            return null;
          },
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
