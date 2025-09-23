// lib/features/snake_game/presentation/pages/snake_game_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/snake_game_provider.dart';
import '../widgets/snake_game_widget.dart';
import '../dialogs/snake_settings_dialog.dart';

class SnakeGamePage extends StatelessWidget {
  const SnakeGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sediakan provider khusus untuk halaman ini
    return ChangeNotifierProvider(
      create: (_) => SnakeGameProvider(),
      child: const _SnakeGameView(),
    );
  }
}

class _SnakeGameView extends StatelessWidget {
  const _SnakeGameView();

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk mendapatkan state terbaru dari provider
    return Consumer<SnakeGameProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Snake Game AI'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Pengaturan',
                onPressed: () => showSnakeSettingsDialog(context),
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SnakeGameWidget(trainingMode: provider.isTrainingMode),
        );
      },
    );
  }
}
