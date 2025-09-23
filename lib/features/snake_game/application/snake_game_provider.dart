// lib/features/snake_game/application/snake_game_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../infrastructure/snake_game_settings_service.dart';

class SnakeGameProvider with ChangeNotifier {
  final SnakeGameSettingsService _settingsService = SnakeGameSettingsService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isTrainingMode = false;
  bool get isTrainingMode => _isTrainingMode;

  int _populationSize = 50;
  int get populationSize => _populationSize;

  int _trainingDuration = 0; // 0 = tanpa batas
  int get trainingDuration => _trainingDuration;

  // ==> STATE BARU UNTUK KECEPATAN <==
  double _snakeSpeed = 1.0;
  double get snakeSpeed => _snakeSpeed;

  int _trainingTimeRemaining = 0;
  int get trainingTimeRemaining => _trainingTimeRemaining;
  Timer? _countdownTimer;

  SnakeGameProvider() {
    _loadSettings();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _isTrainingMode = await _settingsService.loadTrainingMode();
    _populationSize = await _settingsService.loadPopulationSize();
    _trainingDuration = await _settingsService.loadTrainingDuration();
    _snakeSpeed = await _settingsService.loadSnakeSpeed(); // ==> MUAT KECEPATAN
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setTrainingMode(bool isTraining) async {
    _isTrainingMode = isTraining;
    await _settingsService.saveTrainingMode(isTraining);
    notifyListeners();
  }

  Future<void> setPopulationSize(int size) async {
    _populationSize = size;
    await _settingsService.savePopulationSize(size);
    notifyListeners();
  }

  Future<void> setTrainingDuration(int duration) async {
    _trainingDuration = duration;
    await _settingsService.saveTrainingDuration(duration);
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK MENGUPDATE KECEPATAN <==
  Future<void> setSnakeSpeed(double speed) async {
    _snakeSpeed = speed;
    await _settingsService.saveSnakeSpeed(speed);
    notifyListeners();
  }

  void startTrainingTimer() {
    _countdownTimer?.cancel();
    if (_isTrainingMode && _trainingDuration > 0) {
      _trainingTimeRemaining = _trainingDuration;
      notifyListeners();

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_trainingTimeRemaining > 0) {
          _trainingTimeRemaining--;
          notifyListeners();
        } else {
          timer.cancel();
        }
      });
    }
  }

  void stopTrainingTimer() {
    _countdownTimer?.cancel();
  }
}
