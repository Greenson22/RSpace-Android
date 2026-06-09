import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExportBulkSubjectsDialog extends StatefulWidget {
  final int count;
  final String topicName;
  final bool hasAnyLinkedPath;

  const ExportBulkSubjectsDialog({
    super.key,
    required this.count,
    required this.topicName,
    required this.hasAnyLinkedPath,
  });

  @override
  State<ExportBulkSubjectsDialog> createState() =>
      _ExportBulkSubjectsDialogState();
}

class _ExportBulkSubjectsDialogState extends State<ExportBulkSubjectsDialog> {
  late TextEditingController _nameController;
  bool _includePerpus = true;

  @override
  void initState() {
    super.initState();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    // Nama default: Subjects_TopicName_Timestamp
    final safeTopic = widget.topicName.replaceAll(RegExp(r'[^\w\s\-]'), '');
    _nameController = TextEditingController(
      text: 'Subjects_${safeTopic}_$timestamp',
    );

    // Default false jika tidak ada satupun subject yang punya link
    if (!widget.hasAnyLinkedPath) {
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
    return AlertDialog(
      title: Text('Export ${widget.count} Subject ke Zip'),
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
            subtitle: widget.hasAnyLinkedPath
                ? const Text(
                    'Sertakan folder data untuk subject yang memiliki tautan.',
                    style: TextStyle(fontSize: 12),
                  )
                : const Text(
                    'Tidak ada subject terpilih yang memiliki tautan.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
            value: _includePerpus,
            onChanged: widget.hasAnyLinkedPath
                ? (val) {
                    setState(() => _includePerpus = val ?? false);
                  }
                : null,
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
