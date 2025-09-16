// lib/features/settings/presentation/dialogs/repetition_code_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/core/services/storage_service.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';

class RepetitionCodeSettingsDialog extends StatefulWidget {
  const RepetitionCodeSettingsDialog({super.key});

  @override
  State<RepetitionCodeSettingsDialog> createState() =>
      _RepetitionCodeSettingsDialogState();
}

class _RepetitionCodeSettingsDialogState
    extends State<RepetitionCodeSettingsDialog> {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  late Map<String, int> _repetitionDays;
  late Map<String, TextEditingController> _controllers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedDays = await _prefsService.loadRepetitionCodeDays();
    setState(() {
      _repetitionDays = savedDays;
      _controllers = {
        for (var code in kRepetitionCodes.where((c) => c != 'Finish'))
          code: TextEditingController(
            text: (_repetitionDays[code] ?? getDefaultRepetitionDays(code))
                .toString(),
          ),
      };
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final newValues = <String, int>{};
    _controllers.forEach((code, controller) {
      newValues[code] = int.tryParse(controller.text) ?? 0;
    });
    await _prefsService.saveRepetitionCodeDays(newValues);
    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate a change
    }
  }

  void _resetToDefaults() {
    setState(() {
      _controllers.forEach((code, controller) {
        controller.text = getDefaultRepetitionDays(code).toString();
      });
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur Bobot Hari Repetisi'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Atur jumlah hari yang akan ditambahkan ke tanggal saat ini untuk setiap kode repetisi.',
                    ),
                    const SizedBox(height: 16),
                    ..._controllers.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: entry.value,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Jumlah Hari',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _resetToDefaults,
          child: const Text('Reset ke Default'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _saveSettings, child: const Text('Simpan')),
      ],
    );
  }
}
