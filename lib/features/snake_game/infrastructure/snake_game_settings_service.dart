// lib/features/snake_game/infrastructure/snake_game_settings_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SnakeGameSettingsService {
  static const String _trainingModeKey = 'snake_game_training_mode';
  static const String _populationSizeKey = 'snake_game_population_size';
  static const String _trainingDurationKey = 'snake_game_training_duration';
  static const String _snakeSpeedKey = 'snake_game_speed';
  // ==> KUNCI BARU UNTUK MENYIMPAN LAYER ANN <==
  static const String _annLayersKey = 'snake_game_ann_layers';

  Future<void> saveTrainingMode(bool isTraining) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trainingModeKey, isTraining);
  }

  Future<bool> loadTrainingMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trainingModeKey) ?? false;
  }

  Future<void> savePopulationSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_populationSizeKey, size);
  }

  Future<int> loadPopulationSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_populationSizeKey) ?? 50;
  }

  Future<void> saveTrainingDuration(int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_trainingDurationKey, duration);
  }

  Future<int> loadTrainingDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_trainingDurationKey) ?? 0;
  }

  Future<void> saveSnakeSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_snakeSpeedKey, speed);
  }

  Future<double> loadSnakeSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_snakeSpeedKey) ?? 1.0;
  }

  // ==> FUNGSI BARU UNTUK MENYIMPAN DAN MEMUAT LAYER ANN <==
  Future<void> saveAnnLayers(List<int> layers) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = layers.map((i) => i.toString()).toList();
    await prefs.setStringList(_annLayersKey, stringList);
  }

  Future<List<int>> loadAnnLayers() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(_annLayersKey);
    if (stringList != null) {
      return stringList.map((s) => int.tryParse(s) ?? 20).toList();
    }
    // Default arsitektur
    return [10, 12, 4];
  }
}
