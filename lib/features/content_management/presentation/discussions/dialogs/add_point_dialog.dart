// lib/presentation/pages/3_discussions_page/dialogs/add_point_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/discussion_provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../utils/repetition_code_utils.dart';

// Nilai khusus untuk menandakan 'pilih otomatis'
const String _autoSelectCode = 'AUTO_SELECT';

Future<void> showAddPointDialog({
  required BuildContext context,
  required Discussion discussion,
  required String title,
  required String label,
  required Function(String, String) onSave,
}) async {
  // Dapatkan provider dari context pemanggil SEBELUM menampilkan dialog
  final provider = Provider.of<DiscussionProvider>(context, listen: false);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      // Gunakan ChangeNotifierProvider.value untuk menyediakan provider yang sudah ada
      // ke dalam context dialog.
      return ChangeNotifierProvider.value(
        value: provider,
        child: _AddPointDialogContent(
          discussion: discussion,
          title: title,
          label: label,
          onSave: onSave,
        ),
      );
    },
  );
}

// Pisahkan konten dialog menjadi StatefulWidget tersendiri untuk mengelola state internalnya
class _AddPointDialogContent extends StatefulWidget {
  final Discussion discussion;
  final String title;
  final String label;
  final Function(String, String) onSave;

  const _AddPointDialogContent({
    required this.discussion,
    required this.title,
    required this.label,
    required this.onSave,
  });

  @override
  State<_AddPointDialogContent> createState() => _AddPointDialogContentState();
}

class _AddPointDialogContentState extends State<_AddPointDialogContent> {
  final TextEditingController _controller = TextEditingController();
  String _selectedRepetitionCode = _autoSelectCode;
  late String _lowestPointCode;

  @override
  void initState() {
    super.initState();
    // Hitung kode terendah saat state diinisialisasi
    final activePoints = widget.discussion.points.where((p) => !p.finished);
    if (activePoints.isEmpty) {
      _lowestPointCode = widget.discussion.repetitionCode;
    } else {
      _lowestPointCode = activePoints
          .map((p) => p.repetitionCode)
          .reduce(
            (a, b) =>
                getRepetitionCodeIndex(a) < getRepetitionCodeIndex(b) ? a : b,
          );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sekarang kita bisa dengan aman memanggil provider di sini
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final repetitionCodes = provider.repetitionCodes;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(labelText: widget.label),
            ),
            const SizedBox(height: 24),
            Text(
              'Kode Repetisi Awal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('Otomatis (Ikuti kode terendah)'),
              subtitle: Text('Akan diatur ke: $_lowestPointCode'),
              value: _autoSelectCode,
              groupValue: _selectedRepetitionCode,
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedRepetitionCode = value;
                  });
                }
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedRepetitionCode == _autoSelectCode
                  ? null
                  : _selectedRepetitionCode,
              hint: const Text('Atau pilih manual...'),
              isExpanded: true,
              items: repetitionCodes.map((String code) {
                return DropdownMenuItem<String>(value: code, child: Text(code));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRepetitionCode = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              final codeToSave = _selectedRepetitionCode == _autoSelectCode
                  ? _lowestPointCode
                  : _selectedRepetitionCode;
              widget.onSave(_controller.text, codeToSave);
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
