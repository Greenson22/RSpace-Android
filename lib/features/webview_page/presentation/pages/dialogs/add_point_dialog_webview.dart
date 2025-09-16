// lib/features/webview_page/presentation/pages/dialogs/add_point_dialog_webview.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/content_management/application/discussion_provider.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';
// ==> IMPORT DIALOG MANAJEMEN PRESET <==
import 'package:my_aplication/features/content_management/presentation/discussions/dialogs/manage_point_presets_dialog.dart';

// Nilai khusus untuk menandakan 'pilih otomatis'
const String _autoSelectCode = 'AUTO_SELECT';

// Fungsi untuk menampilkan dialog ini
Future<void> showAddPointDialogFromWebView({
  required BuildContext context,
  required Discussion discussion,
  required Function() onPointAdded, // Callback untuk refresh UI sebelumnya
}) async {
  final provider = Provider.of<DiscussionProvider>(context, listen: false);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      // Sediakan provider ke dalam dialog baru
      return ChangeNotifierProvider.value(
        value: provider,
        child: _AddPointDialogContent(
          discussion: discussion,
          onPointAdded: onPointAdded,
        ),
      );
    },
  );
}

// Widget internal dialog
class _AddPointDialogContent extends StatefulWidget {
  final Discussion discussion;
  final Function() onPointAdded;

  const _AddPointDialogContent({
    required this.discussion,
    required this.onPointAdded,
  });

  @override
  State<_AddPointDialogContent> createState() => _AddPointDialogContentState();
}

class _AddPointDialogContentState extends State<_AddPointDialogContent> {
  final TextEditingController _controller = TextEditingController();
  String _selectedRepetitionCode = _autoSelectCode;
  late String _lowestPointCode;
  // ==> STATE BARU UNTUK PRESET <==
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    final activePoints = widget.discussion.points.where((p) => !p.finished);
    if (activePoints.isEmpty) {
      _lowestPointCode = widget.discussion.repetitionCode;
    } else {
      _lowestPointCode = activePoints
          .map((p) => p.repetitionCode)
          .reduce(
            (a, b) =>
                getRepetitionCodeIndex(a) < getRepetitionCodeIndex(b) ? a : b,
          );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ==> Gunakan Consumer agar UI terupdate saat preset berubah <==
    return Consumer<DiscussionProvider>(
      builder: (context, provider, child) {
        final repetitionCodes = provider.repetitionCodes;
        final presets = provider.pointPresets;

        return AlertDialog(
          title: const Text('Tambah Poin Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==> BLOK UI BARU UNTUK PRESET <==
                if (presets.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedPreset,
                    hint: const Text('Pilih dari preset...'),
                    isExpanded: true,
                    items: presets
                        .map(
                          (preset) => DropdownMenuItem(
                            value: preset.name,
                            child: Text(preset.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPreset = value;
                        if (value != null) {
                          _controller.text = value;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Atau tulis manual di bawah ini:'),
                  const SizedBox(height: 16),
                ],
                // --- AKHIR BLOK UI BARU ---
                TextField(
                  controller: _controller,
                  autofocus: presets.isEmpty,
                  decoration: const InputDecoration(labelText: 'Teks Poin'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Kode Repetisi Awal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Otomatis (Ikuti kode terendah)'),
                  subtitle: Text('Akan diatur ke: $_lowestPointCode'),
                  value: _autoSelectCode,
                  groupValue: _selectedRepetitionCode,
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedRepetitionCode = value;
                      });
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedRepetitionCode == _autoSelectCode
                      ? null
                      : _selectedRepetitionCode,
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
                      setState(() {
                        _selectedRepetitionCode = newValue;
                      });
                    }
                  },
                ),
                // ==> TOMBOL BARU UNTUK MENGELOLA PRESET <==
                TextButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Kelola Preset Poin'),
                  onPressed: () {
                    showManagePointPresetsDialog(context);
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
                if (_controller.text.isNotEmpty) {
                  final codeToSave = _selectedRepetitionCode == _autoSelectCode
                      ? _lowestPointCode
                      : _selectedRepetitionCode;
                  provider.addPoint(
                    widget.discussion,
                    _controller.text,
                    repetitionCode: codeToSave,
                  );
                  widget.onPointAdded(); // Panggil callback untuk refresh
                  Navigator.pop(context); // Tutup dialog ini
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
