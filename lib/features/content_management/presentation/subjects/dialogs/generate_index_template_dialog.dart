// lib/features/content_management/presentation/subjects/dialogs/generate_index_template_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/subject_provider.dart';
import '../../../domain/models/subject_model.dart';
// ==> IMPORT BARU
import '../../../../settings/application/gemini_settings_service.dart';
import '../../../../settings/domain/models/gemini_settings_model.dart';

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
  final GeminiSettingsService _settingsService = GeminiSettingsService();
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
      final provider = Provider.of<SubjectProvider>(context, listen: false);
      await provider.generateIndexFileWithAI(widget.subject, _controller.text);

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Template dengan AI'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deskripsikan tampilan template yang Anda inginkan untuk Subject "${widget.subject.name}". AI akan membuat file index.html baru.',
            ),
            const SizedBox(height: 16),
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
              // ==> PERUBAHAN DI SINI
              FutureBuilder<GeminiSettings>(
                future: _settingsService.loadSettings(),
                builder: (context, snapshot) {
                  String modelName = '...';
                  if (snapshot.hasData) {
                    final settings = snapshot.data!;
                    final model = settings.models.firstWhere(
                      (m) => m.modelId == settings.contentModelId,
                      orElse: () => settings.models.first,
                    );
                    modelName = model.name;
                  }
                  return Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          "Membuat template dengan:\n$modelName",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
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
          child: const Text('Generate'),
        ),
      ],
    );
  }
}
