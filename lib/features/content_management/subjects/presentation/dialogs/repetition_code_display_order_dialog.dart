// lib/features/content_management/presentation/subjects/dialogs/repetition_code_display_order_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/subject_provider.dart';

void showRepetitionCodeDisplayOrderDialog(BuildContext context) {
  final provider = Provider.of<SubjectProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const RepetitionCodeDisplayOrderDialog(),
    ),
  );
}

class RepetitionCodeDisplayOrderDialog extends StatefulWidget {
  const RepetitionCodeDisplayOrderDialog({super.key});

  @override
  State<RepetitionCodeDisplayOrderDialog> createState() =>
      _RepetitionCodeDisplayOrderDialogState();
}

class _RepetitionCodeDisplayOrderDialogState
    extends State<RepetitionCodeDisplayOrderDialog> {
  late List<String> _codes;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    _codes = List.from(provider.repetitionCodeDisplayOrder);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Atur Urutan Tampilan Kode'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Geser item untuk mengatur urutan tampilannya di kartu Subject.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _codes.length,
                itemBuilder: (context, index) {
                  final code = _codes[index];
                  return Card(
                    key: ValueKey(code),
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(code),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _codes.removeAt(oldIndex);
                    _codes.insert(newIndex, item);
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            provider.saveRepetitionCodeDisplayOrder(_codes);
            Navigator.pop(context);
          },
          child: const Text('Simpan Urutan'),
        ),
      ],
    );
  }
}
