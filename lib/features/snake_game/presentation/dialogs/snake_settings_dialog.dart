// lib/features/snake_game/presentation/dialogs/snake_settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../application/snake_game_provider.dart';

void showSnakeSettingsDialog(BuildContext context) {
  final provider = Provider.of<SnakeGameProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const SnakeSettingsDialog(),
    ),
  );
}

class SnakeSettingsDialog extends StatefulWidget {
  const SnakeSettingsDialog({super.key});

  @override
  State<SnakeSettingsDialog> createState() => _SnakeSettingsDialogState();
}

class _SnakeSettingsDialogState extends State<SnakeSettingsDialog> {
  late final TextEditingController _populationController;
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SnakeGameProvider>(context, listen: false);
    _populationController = TextEditingController(
      text: provider.populationSize.toString(),
    );
    _durationController = TextEditingController(
      text: provider.trainingDuration.toString(),
    );
  }

  @override
  void dispose() {
    _populationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SnakeGameProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: const Text('Pengaturan Game Ular'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Mode Melatih AI'),
                  subtitle: const Text(
                    'Menjalankan simulasi untuk melatih ANN.',
                  ),
                  value: provider.isTrainingMode,
                  onChanged: (value) {
                    provider.setTrainingMode(value);
                  },
                ),
                const Divider(),
                // ==> WIDGET BARU UNTUK PENGATURAN KECEPATAN <==
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kecepatan Gerak',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        provider.snakeSpeed.toStringAsFixed(1) + 'x',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: provider.snakeSpeed,
                  min: 0.5,
                  max: 2.5,
                  divisions: 4,
                  label: provider.snakeSpeed.toStringAsFixed(1) + 'x',
                  onChanged: (value) {
                    provider.setSnakeSpeed(value);
                  },
                ),
                // ==> AKHIR WIDGET BARU <==
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _populationController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Model (Populasi)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onFieldSubmitted: (value) {
                      final size = int.tryParse(value) ?? 50;
                      provider.setPopulationSize(size);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Waktu Latih (Detik)',
                      helperText: 'Isi 0 untuk tanpa batas waktu.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onFieldSubmitted: (value) {
                      final duration = int.tryParse(value) ?? 0;
                      provider.setTrainingDuration(duration);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
