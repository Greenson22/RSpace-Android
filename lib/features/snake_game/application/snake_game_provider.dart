// lib/features/snake_game/application/snake_game_provider.dart
import 'package:flutter/material.dart';
import '../infrastructure/snake_game_settings_service.dart';

class SnakeGameProvider with ChangeNotifier {
  final SnakeGameSettingsService _settingsService = SnakeGameSettingsService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isTrainingMode = false;
  bool get isTrainingMode => _isTrainingMode;

  SnakeGameProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _isTrainingMode = await _settingsService.loadTrainingMode();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setTrainingMode(bool isTraining) async {
    _isTrainingMode = isTraining;
    await _settingsService.saveTrainingMode(isTraining);
    notifyListeners();
  }
}
