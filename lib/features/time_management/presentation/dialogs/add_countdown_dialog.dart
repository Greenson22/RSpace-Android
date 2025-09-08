// lib/presentation/pages/countdown_page/dialogs/add_countdown_dialog.dart
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';
import '../../application/providers/countdown_provider.dart';

void showAddCountdownDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const AddCountdownDialog(),
  );
}

class AddCountdownDialog extends StatefulWidget {
  const AddCountdownDialog({super.key});

  @override
  State<AddCountdownDialog> createState() => _AddCountdownDialogState();
}

class _AddCountdownDialogState extends State<AddCountdownDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _hours = 0;
  int _minutes = 5;
  int _seconds = 0;

  void _saveTimer() async {
    if (_formKey.currentState!.validate()) {
      final totalDuration = Duration(
        hours: _hours,
        minutes: _minutes,
        seconds: _seconds,
      );
      if (totalDuration.inSeconds == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Durasi tidak boleh nol.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final provider = Provider.of<CountdownProvider>(context, listen: false);
      // Cukup panggil addTimer, provider akan menangani sisanya
      await provider.addTimer(_nameController.text, totalDuration);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Hitung Mundur'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Timer'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPicker(
                    'Jam',
                    _hours,
                    23,
                    (val) => setState(() => _hours = val),
                  ),
                  _buildPicker(
                    'Menit',
                    _minutes,
                    59,
                    (val) => setState(() => _minutes = val),
                  ),
                  _buildPicker(
                    'Detik',
                    _seconds,
                    59,
                    (val) => setState(() => _seconds = val),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _saveTimer, child: const Text('Simpan')),
      ],
    );
  }

  Widget _buildPicker(
    String title,
    int value,
    int maxValue,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      children: [
        Text(title),
        NumberPicker(
          value: value,
          minValue: 0,
          maxValue: maxValue,
          onChanged: onChanged,
          itemHeight: 40,
          itemWidth: 60,
          axis: Axis.vertical,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
