// lib/features/content_management/presentation/discussions/dialogs/repetition_code_order_dialog.dart

import 'package:flutter/material.dart';
import '../utils/repetition_code_utils.dart';

// Fungsi diubah untuk menerima 'initialOrder' dan mengembalikan 'Future<List<String>?>'
Future<List<String>?> showRepetitionCodeOrderDialog(
  BuildContext context, {
  required List<String> initialOrder,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => RepetitionCodeOrderDialog(initialOrder: initialOrder),
  );
}

class RepetitionCodeOrderDialog extends StatefulWidget {
  final List<String> initialOrder;
  const RepetitionCodeOrderDialog({super.key, required this.initialOrder});

  @override
  State<RepetitionCodeOrderDialog> createState() =>
      _RepetitionCodeOrderDialogState();
}

class _RepetitionCodeOrderDialogState extends State<RepetitionCodeOrderDialog> {
  late List<String> _codes;

  @override
  void initState() {
    super.initState();
    // Gunakan initialOrder dari parameter widget
    _codes = widget.initialOrder.isNotEmpty
        ? List.from(widget.initialOrder)
        : List.from(kRepetitionCodes.where((c) => c != 'Finish'));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur Bobot Urutan Kode'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Geser item untuk mengatur prioritas (atas = paling prioritas).',
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
                      leading: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
            // Kembalikan list yang sudah diurutkan saat tombol Simpan ditekan
            Navigator.pop(context, _codes);
          },
          child: const Text('Simpan Urutan'),
        ),
      ],
    );
  }
}
