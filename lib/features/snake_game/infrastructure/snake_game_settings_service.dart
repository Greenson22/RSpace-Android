// lib/features/snake_game/infrastructure/snake_game_settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SnakeGameSettingsService {
  static const String _trainingModeKey = 'snake_game_training_mode';
  // ==> KUNCI BARU DITAMBAHKAN <==
  static const String _populationSizeKey = 'snake_game_population_size';
  static const String _trainingDurationKey = 'snake_game_training_duration';

  Future<void> saveTrainingMode(bool isTraining) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trainingModeKey, isTraining);
  }

  Future<bool> loadTrainingMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trainingModeKey) ?? false;
  }

  // ==> FUNGSI BARU UNTUK MENYIMPAN UKURAN POPULASI <==
  Future<void> savePopulationSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_populationSizeKey, size);
  }

  // ==> FUNGSI BARU UNTUK MEMUAT UKURAN POPULASI <==
  Future<int> loadPopulationSize() async {
    final prefs = await SharedPreferences.getInstance();
    // Default ke 50 jika belum ada pengaturan
    return prefs.getInt(_populationSizeKey) ?? 50;
  }

  // ==> FUNGSI BARU UNTUK MENYIMPAN DURASI LATIHAN <==
  Future<void> saveTrainingDuration(int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_trainingDurationKey, duration);
  }

  // ==> FUNGSI BARU UNTUK MEMUAT DURASI LATIHAN <==
  Future<int> loadTrainingDuration() async {
    final prefs = await SharedPreferences.getInstance();
    // Default ke 0 (tanpa batas) jika belum ada pengaturan
    return prefs.getInt(_trainingDurationKey) ?? 0;
  }
}
