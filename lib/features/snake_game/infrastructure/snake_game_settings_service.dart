// lib/features/snake_game/infrastructure/snake_game_settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SnakeGameSettingsService {
  static const String _trainingModeKey = 'snake_game_training_mode';

  Future<void> saveTrainingMode(bool isTraining) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trainingModeKey, isTraining);
  }

  Future<bool> loadTrainingMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trainingModeKey) ?? false;
  }
}
