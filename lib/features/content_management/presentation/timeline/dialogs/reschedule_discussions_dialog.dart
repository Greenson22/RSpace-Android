// lib/features/content_management/presentation/timeline/dialogs/reschedule_discussions_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Enum untuk merepresentasikan pilihan algoritma
enum RescheduleAlgorithm { balance, spread }

// Class untuk menampung hasil dari dialog
class RescheduleDialogResult {
  final RescheduleAlgorithm algorithm;
  final int maxMoveDays; // Hanya relevan untuk mode 'balance'

  RescheduleDialogResult({required this.algorithm, this.maxMoveDays = 14});
}

Future<RescheduleDialogResult?> showRescheduleDiscussionsDialog(
  BuildContext context,
) async {
  return await showDialog<RescheduleDialogResult>(
    context: context,
    builder: (context) => const RescheduleDiscussionsDialog(),
  );
}

class RescheduleDiscussionsDialog extends StatefulWidget {
  const RescheduleDiscussionsDialog({super.key});

  @override
  State<RescheduleDiscussionsDialog> createState() =>
      _RescheduleDiscussionsDialogState();
}

class _RescheduleDiscussionsDialogState
    extends State<RescheduleDiscussionsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController(text: '14');
  RescheduleAlgorithm _selectedAlgorithm = RescheduleAlgorithm.balance;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur Ulang Jadwal Diskusi'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih metode penjadwalan ulang untuk diskusi yang akan datang:',
              ),
              const SizedBox(height: 16),
              SegmentedButton<RescheduleAlgorithm>(
                segments: const [
                  ButtonSegment(
                    value: RescheduleAlgorithm.balance,
                    label: Text('Seimbangkan'),
                    icon: Icon(Icons.tune),
                  ),
                  ButtonSegment(
                    value: RescheduleAlgorithm.spread,
                    label: Text('Ratakan'),
                    icon: Icon(Icons.linear_scale),
                  ),
                ],
                selected: {_selectedAlgorithm},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedAlgorithm = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Penjelasan dan input akan berubah berdasarkan pilihan
              if (_selectedAlgorithm == RescheduleAlgorithm.balance) ...[
                const Text(
                  'Menyebar jadwal dengan tetap mempertimbangkan tanggal asli. Diskusi tidak akan digeser lebih jauh dari batas yang Anda tentukan.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Batas Maksimal Pergeseran (Hari)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nilai tidak boleh kosong.';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Masukkan angka yang valid.';
                    }
                    return null;
                  },
                ),
              ] else ...[
                const Text(
                  'Menyebar jadwal secara merata antara hari ini dan tanggal diskusi terjauh, mengabaikan tanggal asli.',
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                RescheduleDialogResult(
                  algorithm: _selectedAlgorithm,
                  maxMoveDays: int.tryParse(_controller.text) ?? 14,
                ),
              );
            }
          },
          child: const Text('Jalankan'),
        ),
      ],
    );
  }
}
