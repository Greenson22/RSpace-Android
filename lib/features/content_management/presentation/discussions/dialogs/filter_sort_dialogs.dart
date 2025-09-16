// lib/features/content_management/presentation/discussions/dialogs/filter_sort_dialogs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ==> IMPORT PROVIDER <==
import '../../../application/discussion_provider.dart';
// ==> IMPORT DIALOG BARU <==
import 'repetition_code_order_dialog.dart';

Future<void> showFilterDialog({
  required BuildContext context,
  required bool isFilterActive,
  required VoidCallback onClearFilters,
  required VoidCallback onShowRepetitionCodeFilter,
  required VoidCallback onShowDateFilter,
}) async {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Filter Diskusi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Berdasarkan Kode Repetisi'),
              onTap: () {
                Navigator.pop(context);
                onShowRepetitionCodeFilter();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Berdasarkan Tanggal'),
              onTap: () {
                Navigator.pop(context);
                onShowDateFilter();
              },
            ),
          ],
        ),
        actions: [
          if (isFilterActive)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onClearFilters();
              },
              child: const Text('Hapus Filter'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      );
    },
  );
}

Future<void> showRepetitionCodeFilterDialog({
  required BuildContext context,
  required List<String> repetitionCodes,
  required Function(String) onSelectCode,
}) async {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Pilih Kode Repetisi'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: repetitionCodes.length,
            itemBuilder: (context, index) {
              final code = repetitionCodes[index];
              return ListTile(
                title: Text(code),
                onTap: () {
                  onSelectCode(code);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      );
    },
  );
}

Future<void> showDateFilterDialog({
  required BuildContext context,
  required Function(DateTimeRange) onSelectRange,
  required Function() onSelectTodayAndBefore,
  required DateTimeRange? initialDateRange,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Pilih Opsi Tanggal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Hari Ini'),
              onTap: () {
                onSelectRange(DateTimeRange(start: today, end: today));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Hari ini dan sebelumnya'),
              onTap: () {
                onSelectTodayAndBefore();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Pilih Rentang Tanggal'),
              onTap: () async {
                Navigator.pop(context);
                final pickedRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                  initialDateRange: initialDateRange,
                );
                if (pickedRange != null) {
                  onSelectRange(pickedRange);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showSortDialog({
  required BuildContext context,
  required String initialSortType,
  required bool initialSortAscending,
  required Function(String, bool) onApplySort,
}) async {
  String sortType = initialSortType;
  bool sortAscending = initialSortAscending;
  final provider = Provider.of<DiscussionProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Urutkan Diskusi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urutkan berdasarkan:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<String>(
                  title: const Text('Tanggal'),
                  value: 'date',
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
                  title: const Text('Kode Repetisi'),
                  value: 'code',
                  groupValue: sortType,
                  onChanged: (value) => setDialogState(() => sortType = value!),
                ),
                // ==> PERUBAHAN PADA PEMANGGILAN DIALOG <==
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
                          initialOrder: provider.repetitionCodeOrder,
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
                  onApplySort(sortType, sortAscending);
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
