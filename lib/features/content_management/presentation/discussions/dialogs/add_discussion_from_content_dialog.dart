import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/discussion_provider.dart';

// Fungsi utama untuk menampilkan dialog
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
    // Atur agar dialog tidak bisa ditutup dengan klik di luar
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

// Enum untuk mengelola state tampilan di dalam dialog
enum _DialogState { input, loading, suggestion }

class AddDiscussionFromContentDialog extends StatefulWidget {
  final String subjectLinkedPath;
  const AddDiscussionFromContentDialog({required this.subjectLinkedPath});

  @override
  State<AddDiscussionFromContentDialog> createState() =>
      _AddDiscussionFromContentDialogState();
}

class _AddDiscussionFromContentDialogState
    extends State<AddDiscussionFromContentDialog> {
  final TextEditingController _contentController = TextEditingController();

  _DialogState _currentState = _DialogState.input;
  List<String> _suggestedTitles = [];
  String? _selectedTitle;
  String? _error;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchTitles() async {
    if (_contentController.text.trim().isEmpty) {
      setState(() => _error = 'Konten HTML tidak boleh kosong.');
      return;
    }
    setState(() {
      _currentState = _DialogState.loading;
      _error = null;
    });

    try {
      final provider = Provider.of<DiscussionProvider>(context, listen: false);
      final titles = await provider.getTitlesFromContent(
        _contentController.text,
      );
      if (mounted) {
        setState(() {
          _suggestedTitles = titles;
          _selectedTitle = titles.isNotEmpty ? titles.first : null;
          _currentState = _DialogState.suggestion;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _currentState = _DialogState.input;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_selectedTitle == null) return;

    setState(() => _currentState = _DialogState.loading);

    try {
      final provider = Provider.of<DiscussionProvider>(context, listen: false);
      await provider.addDiscussionWithPredefinedTitle(
        title: _selectedTitle!,
        htmlContent: _contentController.text,
        subjectLinkedPath: widget.subjectLinkedPath,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diskusi "$_selectedTitle" berhasil dibuat.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _currentState = _DialogState.suggestion;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _currentState == _DialogState.input
            ? 'Tambah Diskusi dari Konten'
            : 'Pilih Judul Diskusi',
      ),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    switch (_currentState) {
      case _DialogState.input:
        return _buildInputView();
      case _DialogState.loading:
        return const SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Menganalisis konten..."),
              ],
            ),
          ),
        );
      case _DialogState.suggestion:
        return _buildSuggestionView();
    }
  }

  List<Widget> _buildActions() {
    switch (_currentState) {
      case _DialogState.input:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _fetchTitles,
            child: const Text('Generate Judul'),
          ),
        ];
      case _DialogState.loading:
        return [];
      case _DialogState.suggestion:
        return [
          TextButton(
            onPressed: () => setState(() => _currentState = _DialogState.input),
            child: const Text('Kembali'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTitles,
            tooltip: 'Minta saran baru',
          ),
          ElevatedButton(
            onPressed: _selectedTitle != null ? _handleSave : null,
            child: const Text('Simpan'),
          ),
        ];
    }
  }

  Widget _buildInputView() {
    return SingleChildScrollView(
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
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionView() {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI menyarankan judul berikut. Pilih salah satu:'),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: _suggestedTitles.map((title) {
                return RadioListTile<String>(
                  title: Text(title),
                  value: title,
                  groupValue: _selectedTitle,
                  onChanged: (value) {
                    setState(() {
                      _selectedTitle = value;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
