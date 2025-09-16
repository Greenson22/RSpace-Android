// lib/features/content_management/presentation/subjects/dialogs/subject_sort_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/subject_provider.dart';
// ==> IMPORT DIALOG YANG SUDAH DIREFAKTOR <==
import '../../discussions/dialogs/repetition_code_order_dialog.dart';

Future<void> showSubjectSortDialog({required BuildContext context}) async {
  final provider = Provider.of<SubjectProvider>(context, listen: false);

  String sortType = provider.sortType;
  bool sortAscending = provider.sortAscending;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Urutkan Subject'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urutkan berdasarkan:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<String>(
                  title: const Text('Posisi Manual'),
                  value: 'position',
                  groupValue: sortType,
                  onChanged: (value) => setDialogState(() => sortType = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Nama'),
                  value: 'name',
                  groupValue: sortType,
                  onChanged: (value) => setDialogState(() => sortType = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Tanggal'),
                  value: 'date',
                  groupValue: sortType,
                  onChanged: (value) => setDialogState(() => sortType = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Kode Repetisi'),
                  value: 'code',
                  groupValue: sortType,
                  onChanged: (value) => setDialogState(() => sortType = value!),
                ),
                // ==> PERBAIKAN DAN PEMANGGILAN DIALOG BARU <==
                if (sortType == 'code')
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.sort_by_alpha),
                      label: const Text('Atur Bobot Urutan Kode'),
                      onPressed: () async {
                        Navigator.pop(dialogContext); // Tutup dialog sort
                        final newOrder = await showRepetitionCodeOrderDialog(
                          context,
                          initialOrder: provider.repetitionCodeSortOrder,
                        );
                        // Jika pengguna menyimpan, panggil provider untuk update
                        if (newOrder != null) {
                          provider.saveRepetitionCodeOrder(newOrder);
                        }
                      },
                    ),
                  ),
                const Divider(),
                const Text(
                  'Urutan:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<bool>(
                  title: const Text('Menaik (Ascending)'),
                  value: true,
                  groupValue: sortAscending,
                  onChanged: (value) =>
                      setDialogState(() => sortAscending = value!),
                ),
                RadioListTile<bool>(
                  title: const Text('Menurun (Descending)'),
                  value: false,
                  groupValue: sortAscending,
                  onChanged: (value) =>
                      setDialogState(() => sortAscending = value!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  provider.applySort(sortType, sortAscending);
                  Navigator.pop(context);
                },
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
      );
    },
  );
}
