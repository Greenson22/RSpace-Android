import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/discussion_provider.dart';

Future<void> showAddDiscussionFromContentDialog({
  required BuildContext context,
  required String? subjectLinkedPath,
}) async {
  if (subjectLinkedPath == null || subjectLinkedPath.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fitur ini memerlukan Subject yang tertaut ke folder PerpusKu.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      // Sediakan provider ke dalam dialog
      return ChangeNotifierProvider.value(
        value: Provider.of<DiscussionProvider>(context, listen: false),
        child: _AddDiscussionFromContentDialog(
          subjectLinkedPath: subjectLinkedPath,
        ),
      );
    },
  );
}

class _AddDiscussionFromContentDialog extends StatefulWidget {
  final String subjectLinkedPath;
  const _AddDiscussionFromContentDialog({required this.subjectLinkedPath});

  @override
  State<_AddDiscussionFromContentDialog> createState() =>
      _AddDiscussionFromContentDialogState();
}

class _AddDiscussionFromContentDialogState
    extends State<_AddDiscussionFromContentDialog> {
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _handleGenerateAndSave() async {
    if (_contentController.text.trim().isEmpty) {
      setState(() => _error = 'Konten HTML tidak boleh kosong.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = Provider.of<DiscussionProvider>(context, listen: false);
      final generatedTitle = await provider.addDiscussionFromContent(
        _contentController.text,
        widget.subjectLinkedPath,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diskusi "$generatedTitle" berhasil dibuat.'),
            backgroundColor: Colors.green,
          ),
        );
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
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Diskusi dari Konten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tempelkan konten HTML di bawah ini. AI akan membuatkan judul secara otomatis.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Konten HTML',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text("Membuat judul dan menyimpan...")),
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
          onPressed: _isLoading ? null : _handleGenerateAndSave,
          child: const Text('Generate Judul & Simpan'),
        ),
      ],
    );
  }
}
