// lib/presentation/pages/3_discussions_page/dialogs/add_point_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/discussion_provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../utils/repetition_code_utils.dart'; // Pastikan utilitas diimpor

// Nilai khusus untuk menandakan 'pilih otomatis'
const String _autoSelectCode = 'AUTO_SELECT';

Future<void> showAddPointDialog({
  required BuildContext context,
  required Discussion discussion, // Tambahkan discussion sebagai parameter
  required String title,
  required String label,
  required Function(String, String) onSave, // Diubah untuk mengirim kode
}) async {
  final controller = TextEditingController();
  // State untuk menyimpan kode yang dipilih
  String selectedRepetitionCode = _autoSelectCode;

  return showDialog<void>(
    context: context,
    builder: (context) {
      // Dapatkan provider di dalam builder
      final provider = Provider.of<DiscussionProvider>(context, listen: false);
      final repetitionCodes = provider.repetitionCodes;
      // Dapatkan kode terendah dari point yang ada
      final activePoints = discussion.points.where((p) => !p.finished);
      final String lowestPointCode;

      if (activePoints.isEmpty) {
        // Jika tidak ada point, gunakan kode dari diskusi induk
        lowestPointCode = discussion.repetitionCode;
      } else {
        // Jika ada point, cari yang kodenya terendah
        lowestPointCode = activePoints
            .map((p) => p.repetitionCode)
            .reduce(
              (a, b) =>
                  // PANGGILAN LANGSUNG, TANPA "provider."
                  getRepetitionCodeIndex(a) < getRepetitionCodeIndex(b) ? a : b,
            );
      }

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(labelText: label),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Kode Repetisi Awal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  // Radio button untuk pilihan otomatis
                  RadioListTile<String>(
                    title: const Text('Otomatis (Ikuti kode terendah)'),
                    subtitle: Text('Akan diatur ke: $lowestPointCode'),
                    value: _autoSelectCode,
                    groupValue: selectedRepetitionCode,
                    onChanged: (String? value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRepetitionCode = value;
                        });
                      }
                    },
                  ),
                  // Dropdown untuk pilihan manual
                  DropdownButtonFormField<String>(
                    value: selectedRepetitionCode == _autoSelectCode
                        ? null
                        : selectedRepetitionCode,
                    hint: const Text('Atau pilih manual...'),
                    isExpanded: true,
                    items: repetitionCodes.map((String code) {
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(code),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedRepetitionCode = newValue;
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
                  if (controller.text.isNotEmpty) {
                    final codeToSave = selectedRepetitionCode == _autoSelectCode
                        ? lowestPointCode
                        : selectedRepetitionCode;
                    onSave(controller.text, codeToSave);
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
