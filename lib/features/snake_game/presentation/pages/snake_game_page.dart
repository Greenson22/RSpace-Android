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
              // ==> PERUBAHAN UTAMA: GUNAKAN STACK UNTUK MENUMPUK WIDGET <==
              : Stack(
                  children: [
                    SnakeGameWidget(trainingMode: provider.isTrainingMode),
                    // ==> INDIKATOR WAKTU DITAMPILKAN DI SINI <==
                    if (provider.isTrainingMode &&
                        provider.trainingDuration > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Chip(
                          backgroundColor: Colors.black54,
                          avatar: const Icon(
                            Icons.timer_outlined,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Sisa Waktu: ${provider.trainingTimeRemaining}s',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
