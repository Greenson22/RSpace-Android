// lib/presentation/pages/3_discussions_page/dialogs/discussion_dialogs.dart
import 'package:flutter/material.dart';
import 'html_file_picker_dialog.dart';
import 'move_discussion_dialog.dart'; // ==> IMPORT DIALOG BARU

// ==> FUNGSI BARU UNTUK MENAMPILKAN DIALOG PEMINDAHAN <==
Future<Map<String, String?>?> showMoveDiscussionDialog(
  BuildContext context,
) async {
  return await showDialog<Map<String, String?>?>(
    context: context,
    builder: (context) => const MoveDiscussionDialog(),
  );
}

Future<void> showAddDiscussionDialog({
  required BuildContext context,
  required String title,
  required String label,
  required Function(String, bool) onSave,
  required String? subjectLinkedPath,
}) async {
  final controller = TextEditingController();
  bool createHtmlFile = false;

  return showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(labelText: label),
                ),
                if (subjectLinkedPath != null && subjectLinkedPath.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: CheckboxListTile(
                      title: const Text("Buat file HTML tertaut"),
                      subtitle: Text(
                        "Akan membuat file .html baru di dalam folder:\n$subjectLinkedPath",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: createHtmlFile,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          createHtmlFile = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
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
                  if (controller.text.isNotEmpty) {
                    onSave(controller.text, createHtmlFile);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ==> DIALOG BARU UNTUK MENAMBAHKAN POINT <==
Future<void> showAddPointDialog({
  required BuildContext context,
  required String title,
  required String label,
  required Function(String, bool) onSave,
}) async {
  final controller = TextEditingController();
  bool inheritRepetitionCode = false; // Defaultnya tidak dicentang

  return showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(labelText: label),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text("Ikuti kode repetisi dari diskusi induk"),
                  value: inheritRepetitionCode,
                  onChanged: (bool? value) {
                    setDialogState(() {
                      inheritRepetitionCode = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
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
                  if (controller.text.isNotEmpty) {
                    onSave(controller.text, inheritRepetitionCode);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}

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

Future<String?> showHtmlFilePicker(
  BuildContext context,
  String basePath, {
  String? initialPath,
}) async {
  return await showDialog<String>(
    context: context,
    builder: (context) =>
        HtmlFilePickerDialog(basePath: basePath, initialPath: initialPath),
  );
}

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
  // ==> TAMBAHKAN PARAMETER BARU <==
  bool hasLinkedFile = false,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Hapus Diskusi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin menghapus diskusi "$discussionName" beserta semua isinya?',
            ),
            // ==> TAMPILKAN PERINGATAN JIKA ADA FILE TERTAUT <==
            if (hasLinkedFile) ...[
              const SizedBox(height: 16),
              const Text(
                'PERINGATAN: File HTML yang tertaut dengan diskusi ini juga akan dihapus secara permanen.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ],
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
