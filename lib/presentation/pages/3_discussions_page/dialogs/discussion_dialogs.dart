// lib/presentation/pages/3_discussions_page/dialogs/discussion_dialogs.dart
import 'package:flutter/material.dart';
import 'html_file_picker_dialog.dart';

// Fungsi untuk menampilkan dialog input teks generik
Future<void> showTextInputDialog({
  required BuildContext context,
  required String title,
  required String label,
  String initialValue = '',
  required Function(String) onSave,
}) async {
  final controller = TextEditingController(text: initialValue);
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSave(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );
}

// FUNGSI LAMA DIGANTI DENGAN YANG DI BAWAH
// Future<void> showFilePathDialog(...) {...}

//==> FUNGSI BARU UNTUK MENAMPILKAN FILE PICKER DIALOG <==
Future<String?> showHtmlFilePicker(
  BuildContext context,
  String basePath,
) async {
  return await showDialog<String>(
    context: context,
    builder: (context) => HtmlFilePickerDialog(basePath: basePath),
  );
}

// Fungsi untuk menampilkan dialog pemilihan kode repetisi
void showRepetitionCodeDialog(
  BuildContext context,
  String currentCode,
  List<String> repetitionCodes,
  Function(String) onCodeSelected,
) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      String? tempSelectedCode = currentCode;
      return StatefulBuilder(
        builder: (context, setStateInDialog) {
          return AlertDialog(
            title: const Text('Pilih Kode Repetisi'),
            content: DropdownButton<String>(
              value: tempSelectedCode,
              isExpanded: true,
              items: repetitionCodes.map((String code) {
                return DropdownMenuItem<String>(value: code, child: Text(code));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setStateInDialog(() => tempSelectedCode = newValue);
                  onCodeSelected(newValue);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showDeleteDiscussionConfirmationDialog({
  required BuildContext context,
  required String discussionName,
  required VoidCallback onDelete,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Hapus Diskusi'),
        content: Text(
          'Anda yakin ingin menghapus diskusi "$discussionName" beserta semua isinya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );
}

//==> FUNGSI BARU UNTUK KONFIRMASI HAPUS POINT <==
Future<void> showDeletePointConfirmationDialog({
  required BuildContext context,
  required String pointText,
  required VoidCallback onDelete,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Hapus Poin'),
        content: Text('Anda yakin ingin menghapus poin "$pointText"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );
}

//==> FUNGSI BARU UNTUK KONFIRMASI HAPUS PATH FILE <==
Future<bool> showRemoveFilePathConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Hapus Path File'),
            content: const Text(
              'Anda yakin ingin menghapus tautan path file dari diskusi ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          );
        },
      ) ??
      false;
}

//==> FUNGSI BARU UNTUK KONFIRMASI UPDATE KODE REPETISI <==
Future<bool> showRepetitionCodeUpdateConfirmationDialog({
  required BuildContext context,
  required String currentCode,
  required String nextCode,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Konfirmasi Perubahan Kode'),
            content: Text(
              'Anda yakin ingin mengubah kode repetisi dari "$currentCode" menjadi "$nextCode"? Tanggal juga akan diperbarui.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Ubah'),
              ),
            ],
          );
        },
      ) ??
      false;
}

// --- DIALOGS FOR FILTER & SORT ---

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
                onSelectRange(DateTimeRange(start: DateTime(2000), end: today));
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

  showDialog(
    context: context,
    builder: (context) {
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
