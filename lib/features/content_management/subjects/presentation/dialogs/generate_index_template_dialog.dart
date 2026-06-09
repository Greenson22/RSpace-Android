// lib/features/content_management/presentation/subjects/dialogs/generate_index_template_dialog.dart

import 'package:flutter/material.dart';
import '../../models/subject_model.dart';

class GenerateIndexTemplateDialog extends StatefulWidget {
  final Subject subject;

  const GenerateIndexTemplateDialog({super.key, required this.subject});

  @override
  State<GenerateIndexTemplateDialog> createState() =>
      _GenerateIndexTemplateDialogState();
}

class _GenerateIndexTemplateDialogState
    extends State<GenerateIndexTemplateDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _handleGenerate() async {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _error = 'Deskripsi tema tidak boleh kosong.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (mounted) {
        Navigator.of(context).pop(true); // Kirim sinyal sukses
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Index Template'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Tema',
                hintText: 'Contoh: tema luar angkasa gelap, desain vintage...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text("Memproses template...", textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleGenerate,
          child: const Text(
            'Simpan',
          ), // Mengubah teks tombol dari 'Generate' menjadi 'Simpan'
        ),
      ],
    );
  }
}
