// lib/features/content_management/presentation/discussions/dialogs/repetition_code_order_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/discussion_provider.dart';
import '../utils/repetition_code_utils.dart';

void showRepetitionCodeOrderDialog(BuildContext context) {
  final provider = Provider.of<DiscussionProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const RepetitionCodeOrderDialog(),
    ),
  );
}

class RepetitionCodeOrderDialog extends StatefulWidget {
  const RepetitionCodeOrderDialog({super.key});

  @override
  State<RepetitionCodeOrderDialog> createState() =>
      _RepetitionCodeOrderDialogState();
}

class _RepetitionCodeOrderDialogState extends State<RepetitionCodeOrderDialog> {
  late List<String> _codes;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    // Jika ada urutan kustom, gunakan itu. Jika tidak, gunakan daftar default.
    final currentOrder = provider.repetitionCodeOrder;
    _codes = currentOrder.isNotEmpty
        ? List.from(currentOrder)
        : List.from(kRepetitionCodes.where((c) => c != 'Finish'));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);

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
            provider.saveRepetitionCodeOrder(_codes);
            Navigator.pop(context);
          },
          child: const Text('Simpan Urutan'),
        ),
      ],
    );
  }
}
