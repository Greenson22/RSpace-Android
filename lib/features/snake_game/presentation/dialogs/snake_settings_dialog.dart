// lib/features/snake_game/presentation/dialogs/snake_settings_dialog.dart
import 'package:flutter/material.dart';
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

class SnakeSettingsDialog extends StatelessWidget {
  const SnakeSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SnakeGameProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: const Text('Pengaturan Game Ular'),
          content: SwitchListTile(
            title: const Text('Mode Melatih AI'),
            subtitle: const Text('Menjalankan simulasi untuk melatih ANN.'),
            value: provider.isTrainingMode,
            onChanged: (value) {
              provider.setTrainingMode(value);
            },
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
