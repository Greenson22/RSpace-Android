// lib/features/content_management/presentation/discussions/dialogs/generate_html_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ==> IMPORT DIPERBARUI
import '../../../../settings/application/services/gemini_service_flutter_gemini.dart';
import '../../../application/discussion_provider.dart';

class GenerateHtmlDialog extends StatefulWidget {
  final String discussionName;
  final String? filePath;

  const GenerateHtmlDialog({
    super.key,
    required this.discussionName,
    required this.filePath,
  });

  @override
  State<GenerateHtmlDialog> createState() => _GenerateHtmlDialogState();
}

class _GenerateHtmlDialogState extends State<GenerateHtmlDialog> {
  // ==> INSTANCE DIPERBARUI
  final GeminiServiceFlutterGemini _geminiService =
      GeminiServiceFlutterGemini();
  late TextEditingController _textController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.discussionName);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    if (_textController.text.trim().isEmpty) {
      setState(() {
        _error = 'Pembahasan tidak boleh kosong.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ==> PEMANGGILAN DIPERBARUI
      final generatedHtml = await _geminiService.generateHtmlContent(
        _textController.text,
      );

      if (mounted) {
        final provider = Provider.of<DiscussionProvider>(
          context,
          listen: false,
        );

        await provider.writeHtmlToFile(widget.filePath!, generatedHtml);

        if (mounted) {
          Navigator.of(context).pop(true); // Kirim sinyal sukses
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
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
      title: const Text('Generate Konten AI'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan atau ubah pembahasan di bawah ini untuk dibuatkan konten HTML oleh AI:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              autofocus: true,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Pembahasan',
                border: OutlineInputBorder(),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text("Menghasilkan konten...")),
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
