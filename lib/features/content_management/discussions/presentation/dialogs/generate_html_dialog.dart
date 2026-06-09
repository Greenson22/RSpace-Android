// lib/features/content_management/presentation/discussions/dialogs/generate_html_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/discussion_provider.dart';

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
  // DIUBAH: Instance GeminiServiceFlutterGemini telah dihapus
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
      // DIUBAH: Logika generate AI dinonaktifkan sementara karena service telah dihapus
      // Sinyal sukses langsung dikirim atau ganti dengan service baru Anda di sini
      await Future.delayed(const Duration(seconds: 1)); // Placeholder delay

      if (mounted) {
        final provider = Provider.of<DiscussionProvider>(
          context,
          listen: false,
        );

        // Contoh konten HTML dummy sebagai fallback pengganti AI
        final dummyHtml =
            '''
<!DOCTYPE html>
<html>
<head><title>${_textController.text}</title></head>
<body><h1>${_textController.text}</h1><p>Konten siap ditulis...</p></body>
</html>
''';

        await provider.writeHtmlToFile(widget.filePath!, dummyHtml);

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
              const Center(child: Text("Mengharsipkan konten...")),
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
