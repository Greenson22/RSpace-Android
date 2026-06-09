import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/discussion_provider.dart';

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
    barrierDismissible: false,
    builder: (dialogContext) {
      return ChangeNotifierProvider.value(
        value: Provider.of<DiscussionProvider>(context, listen: false),
        child: AddDiscussionFromContentDialog(
          subjectLinkedPath: subjectLinkedPath,
        ),
      );
    },
  );
}

class AddDiscussionFromContentDialog extends StatefulWidget {
  final String subjectLinkedPath;
  const AddDiscussionFromContentDialog({required this.subjectLinkedPath});

  @override
  State<AddDiscussionFromContentDialog> createState() =>
      _AddDiscussionFromContentDialogState();
}

class _AddDiscussionFromContentDialogState
    extends State<AddDiscussionFromContentDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Judul tidak boleh kosong.');
      return;
    }
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

      // Menggunakan fungsi addDiscussionWithPredefinedTitle yang sudah ada di provider Anda
      await provider.addDiscussionWithPredefinedTitle(
        title: _titleController.text.trim(),
        htmlContent: _contentController.text,
        subjectLinkedPath: widget.subjectLinkedPath,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Diskusi "${_titleController.text}" berhasil dibuat.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Diskusi dari Konten'),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Menyimpan diskusi..."),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Diskusi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Konten HTML',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 8,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
      actions: _isLoading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Simpan'),
              ),
            ],
    );
  }
}
