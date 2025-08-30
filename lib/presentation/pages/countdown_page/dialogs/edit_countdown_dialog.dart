// lib/presentation/pages/countdown_page/dialogs/edit_countdown_dialog.dart
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/countdown_model.dart';
import '../../../providers/countdown_provider.dart';

void showEditCountdownDialog(BuildContext context, CountdownItem timer) {
  showDialog(
    context: context,
    builder: (context) => EditCountdownDialog(timer: timer),
  );
}

class EditCountdownDialog extends StatefulWidget {
  final CountdownItem timer;
  const EditCountdownDialog({super.key, required this.timer});

  @override
  State<EditCountdownDialog> createState() => _EditCountdownDialogState();
}

class _EditCountdownDialogState extends State<EditCountdownDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _hours;
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.timer.name);
    final duration = widget.timer.originalDuration;
    _hours = duration.inHours;
    _minutes = duration.inMinutes.remainder(60);
    _seconds = duration.inSeconds.remainder(60);
  }

  Future<void> _saveChanges() async {
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
      await provider.updateTimer(
        widget.timer.id,
        _nameController.text,
        totalDuration,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Hitung Mundur'),
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
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Simpan Perubahan'),
        ),
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
