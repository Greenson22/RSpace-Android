// lib/features/quiz/presentation/dialogs/import_quiz_from_json_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import '../../domain/models/quiz_model.dart'; // Import model

// ==> FUNGSI DIPERBARUI UNTUK MENERIMA QUIZSET OPSIONAL
void showImportQuizFromJsonDialog(
  BuildContext context, {
  QuizSet? existingQuizSet,
}) {
  final provider = Provider.of<QuizDetailProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: ImportQuizFromJsonDialog(existingQuizSet: existingQuizSet),
    ),
  );
}

class ImportQuizFromJsonDialog extends StatefulWidget {
  // ==> TAMBAHKAN PROPERTI BARU
  final QuizSet? existingQuizSet;
  const ImportQuizFromJsonDialog({super.key, this.existingQuizSet});

  @override
  State<ImportQuizFromJsonDialog> createState() =>
      _ImportQuizFromJsonDialogState();
}

class _ImportQuizFromJsonDialogState extends State<ImportQuizFromJsonDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quizSetNameController = TextEditingController();
  final TextEditingController _jsonContentController = TextEditingController();

  // ==> TENTUKAN APAKAH INI MODE TAMBAH PERTANYAAN
  bool get isAddingQuestionsMode => widget.existingQuizSet != null;

  @override
  void initState() {
    super.initState();
    // Jika dalam mode edit, isi nama set kuis secara otomatis
    if (isAddingQuestionsMode) {
      _quizSetNameController.text = widget.existingQuizSet!.name;
    }
  }

  @override
  void dispose() {
    _quizSetNameController.dispose();
    _jsonContentController.dispose();
    super.dispose();
  }

  Future<void> _handleImport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<QuizDetailProvider>(context, listen: false);
    final quizSetName = _quizSetNameController.text.trim();
    final jsonContent = _jsonContentController.text.trim();

    Navigator.of(context).pop();

    try {
      // ==> GUNAKAN LOGIKA KONDISIONAL DI SINI
      if (isAddingQuestionsMode) {
        await provider.addQuestionsToQuizSetFromJson(
          quizSetName: quizSetName,
          jsonContent: jsonContent,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pertanyaan dari JSON berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await provider.addQuizSetFromJson(
          quizSetName: quizSetName,
          jsonContent: jsonContent,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kuis dari JSON berhasil diimpor!'),
              backgroundColor: Colors.green,
            ),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ==> SESUAIKAN JUDUL DIALOG
    final dialogTitle = isAddingQuestionsMode
        ? 'Tambah Pertanyaan dari JSON'
        : 'Impor Kuis dari JSON';

    return AlertDialog(
      title: Text(dialogTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==> SEMBUNYIKAN INPUT NAMA JIKA MODE TAMBAH PERTANYAAN
              if (!isAddingQuestionsMode)
                TextFormField(
                  controller: _quizSetNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Set Kuis Baru',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama set kuis tidak boleh kosong.';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jsonContentController,
                decoration: const InputDecoration(
                  labelText: 'Konten JSON',
                  hintText: 'Tempelkan hasil JSON dari Gemini di sini...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Konten JSON tidak boleh kosong.';
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
          onPressed: _handleImport,
          // ==> SESUAIKAN TEKS TOMBOL
          child: Text(isAddingQuestionsMode ? 'Tambahkan' : 'Impor Kuis'),
        ),
      ],
    );
  }
}
