import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';

class ExportSubjectDialog extends StatefulWidget {
  final Subject subject;

  const ExportSubjectDialog({super.key, required this.subject});

  @override
  State<ExportSubjectDialog> createState() => _ExportSubjectDialogState();
}

class _ExportSubjectDialogState extends State<ExportSubjectDialog> {
  late TextEditingController _nameController;
  bool _includePerpus = true;

  @override
  void initState() {
    super.initState();
    // Format default: NamaSubject_YYYYMMDD_HHMM sesuai permintaan
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final safeName = widget.subject.name.replaceAll(RegExp(r'[^\w\s\-]'), '');
    _nameController = TextEditingController(text: '${safeName}_$timestamp');

    // Matikan checkbox jika subject tidak memiliki tautan PerpusKu
    if (widget.subject.linkedPath == null ||
        widget.subject.linkedPath!.isEmpty) {
      _includePerpus = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLinkedPath =
        widget.subject.linkedPath != null &&
        widget.subject.linkedPath!.isNotEmpty;

    return AlertDialog(
      title: const Text('Export Subject ke Zip'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama File (tanpa .zip)',
              suffixText: '.zip',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sertakan Data PerpusKu'),
            subtitle: hasLinkedPath
                ? Text(
                    'Folder: ${widget.subject.linkedPath!.split('/').last}',
                    style: const TextStyle(fontSize: 12),
                  )
                : const Text(
                    'Tidak ada tautan folder.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
            value: _includePerpus,
            onChanged: hasLinkedPath
                ? (val) {
                    setState(() => _includePerpus = val ?? false);
                  }
                : null, // Disable jika tidak ada path
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            // Kembalikan Map berisi nama file dan flag perpusku
            Navigator.pop(context, {
              'fileName': _nameController.text.trim(),
              'includePerpus': _includePerpus,
            });
          },
          icon: const Icon(Icons.archive),
          label: const Text('Export Zip'),
        ),
      ],
    );
  }
}
