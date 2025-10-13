// lib/features/perpusku/presentation/dialogs/import_perpusku_quiz_from_json_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/quiz/application/quiz_detail_provider.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';

void showImportPerpuskuQuizFromJsonDialog(
  BuildContext context,
  String quizName,
) {
  final provider = Provider.of<PerpuskuQuizDetailProvider>(
    context,
    listen: false,
  );

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: ImportPerpuskuQuizFromJsonDialog(quizName: quizName),
    ),
  );
}

class ImportPerpuskuQuizFromJsonDialog extends StatefulWidget {
  final String quizName;
  const ImportPerpuskuQuizFromJsonDialog({super.key, required this.quizName});

  @override
  State<ImportPerpuskuQuizFromJsonDialog> createState() =>
      _ImportPerpuskuQuizFromJsonDialogState();
}

class _ImportPerpuskuQuizFromJsonDialogState
    extends State<ImportPerpuskuQuizFromJsonDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jsonContentController = TextEditingController();
  bool _isImporting = false;

  Future<void> _handleImport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isImporting = true);

    final provider = Provider.of<PerpuskuQuizDetailProvider>(
      context,
      listen: false,
    );
    final jsonContent = _jsonContentController.text.trim();

    try {
      await provider.addQuestionsFromJson(
        quizSetName: widget.quizName,
        jsonContent: jsonContent,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Tutup dialog ini
        showAppSnackBar(context, 'Pertanyaan dari JSON berhasil ditambahkan!');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  void dispose() {
    _jsonContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah Soal ke "${widget.quizName}"'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _jsonContentController,
                decoration: const InputDecoration(
                  labelText: 'Konten JSON',
                  hintText: 'Tempelkan hasil JSON dari Gemini di sini...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Konten JSON tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              if (_isImporting) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isImporting ? null : _handleImport,
          child: const Text('Tambahkan'),
        ),
      ],
    );
  }
}
