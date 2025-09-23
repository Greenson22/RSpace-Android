// lib/features/snake_game/application/snake_game_provider.dart
import 'package:flutter/material.dart';
import '../infrastructure/snake_game_settings_service.dart';

class SnakeGameProvider with ChangeNotifier {
  final SnakeGameSettingsService _settingsService = SnakeGameSettingsService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isTrainingMode = false;
  bool get isTrainingMode => _isTrainingMode;

  // ==> STATE BARU DITAMBAHKAN <==
  int _populationSize = 50;
  int get populationSize => _populationSize;

  int _trainingDuration = 0; // 0 = tanpa batas
  int get trainingDuration => _trainingDuration;

  SnakeGameProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _isTrainingMode = await _settingsService.loadTrainingMode();
    // ==> MUAT PENGATURAN BARU <==
    _populationSize = await _settingsService.loadPopulationSize();
    _trainingDuration = await _settingsService.loadTrainingDuration();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setTrainingMode(bool isTraining) async {
    _isTrainingMode = isTraining;
    await _settingsService.saveTrainingMode(isTraining);
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK MENGUPDATE UKURAN POPULASI <==
  Future<void> setPopulationSize(int size) async {
    _populationSize = size;
    await _settingsService.savePopulationSize(size);
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK MENGUPDATE DURASI LATIHAN <==
  Future<void> setTrainingDuration(int duration) async {
    _trainingDuration = duration;
    await _settingsService.saveTrainingDuration(duration);
    notifyListeners();
  }
}
